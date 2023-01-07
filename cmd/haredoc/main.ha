// License: GPL-3.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use bufio;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use hare::unparse;
use io;
use os;
use os::exec;
use path;
use strings;
use unix::tty;

type format = enum {
	HARE,
	TTY,
	HTML,
	GEMTEXT,
};

type context = struct {
	mctx: *module::context,
	ident: ast::ident,
	tags: []module::tag,
	version: module::version,
	summary: summary,
	format: format,
	template: bool,
	show_undocumented: bool,
	readme: (io::file | void),
	out: io::handle,
	pager: (exec::process | void),
};

export fn main() void = {
	let fmt = if (tty::isatty(os::stdout_file)) {
		yield format::TTY;
	} else {
		yield format::HARE;
	};
	let template = true;
	let show_undocumented = false;
	let tags = default_tags();
	defer module::tags_free(tags);

	const help: [_]getopt::help = [
		"reads and formats Hare documentation",
		('F', "format", "specify output format (hare, tty, html, or gemtext)"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		('a', "show undocumented members (only applies to -Fhare and -Ftty)"),
		('t', "disable HTML template (requires postprocessing)"),
		"[identifiers...]",
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'F' =>
			switch (opt.1) {
			case "hare" =>
				fmt = format::HARE;
			case "tty" =>
				fmt = format::TTY;
			case "html" =>
				fmt = format::HTML;
			case "gemtext" =>
				fmt = format::GEMTEXT;
			case =>
				fmt::fatal("Invalid format", opt.1);
			};
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case 't' =>
			template = false;
		case 'a' =>
			show_undocumented = true;
		case => abort();
		};
	};

	if (show_undocumented) switch (fmt) {
	case format::HARE, format::TTY => void;
	case =>
		fmt::fatal("Option -a must be used only with -Fhare or -Ftty");
	};

	let decls: []ast::decl = [];
	defer free(decls);

	let ctx = module::context_init(tags, [], default_harepath());
	defer module::context_finish(&ctx);

	const id: ast::ident =
		if (len(cmd.args) < 1) []
		else match (parseident(cmd.args[0])) {
		case let err: parse::error =>
			fmt::fatal(parse::strerror(err));
		case let id: ast::ident =>
			yield id;
		};

	let decl = "";
	let dirname: ast::ident = if (len(id) < 2) [] else id[..len(id) - 1];
	const version = match (module::lookup(&ctx, id)) {
	case let ver: module::version =>
		yield ver;
	case let err: module::error =>
		yield match (module::lookup(&ctx, dirname)) {
		case let ver: module::version =>
			assert(len(id) >= 1);
			decl = id[len(id) - 1];
			yield ver;
		case let err: module::error =>
			fmt::fatal("Error scanning input module:",
				module::strerror(err));
		};
	};

	for (let i = 0z; i < len(version.inputs); i += 1) {
		const in = version.inputs[i];
		const ext = path::extension(in.path);
		if (ext.1 != ".ha") {
			continue;
		};
		match (scan(in.path)) {
		case let u: ast::subunit =>
			for (let i = 0z; i < len(u.imports); i += 1) {
				ast::import_finish(u.imports[i]);
			};
			append(decls, u.decls...);
		case let err: error =>
			fmt::fatal("Error:", strerror(err));
		};
	};

	const rpath = path::join(version.basedir, "README");
	defer free(rpath);
	const readme: (io::file | void) = if (decl == "") {
		yield match (os::open(rpath)) {
		case let err: fs::error =>
			yield void;
		case let f: io::file =>
			yield f;
		};
	} else void;

	defer match (readme) {
	case void => void;
	case let f: io::file =>
		io::close(f)!;
	};

	if (decl != "") {
		let new: []ast::decl = [];
		for (let i = 0z; i < len(decls); i += 1) {
			if (has_decl(decls[i], decl)) {
				append(new, decls[i]);
			} else {
				ast::decl_finish(decls[i]);
			};
		};
		if (len(new) == 0) {
			fmt::fatalf("Could not find {}::{}",
				unparse::identstr(dirname), decl);
		};
		free(decls);
		decls = new;

		show_undocumented = true;
	};

	defer for (let i = 0z; i < len(decls); i += 1) {
		ast::decl_finish(decls[i]);
	};

	const ctx = context {
		mctx = &ctx,
		ident = id,
		tags = tags,
		version = version,
		summary = sort_decls(decls),
		format = fmt,
		template = template,
		readme = readme,
		show_undocumented = show_undocumented,
		out = os::stdout,
		pager = void,
	};

	if (fmt == format::TTY) {
		ctx.out = init_tty(&ctx);
	};

	match (emit(&ctx)) {
	case void => void;
	case let err: error =>
		fmt::fatal("Error:", strerror(err));
	};

	io::close(ctx.out)!;
	match (ctx.pager) {
	case void => void;
	case let proc: exec::process =>
		exec::wait(&proc)!;
	};
};

// Nearly identical to parse::identstr, except alphanumeric lexical tokens are
// converted to strings and there must be no trailing tokens that don't belong
// to the ident in the string. For example, this function will parse `rt::abort`
// as a valid identifier.
fn parseident(in: str) (ast::ident | parse::error) = {
	const buf = bufio::fixed(strings::toutf8(in), io::mode::READ);
	const lexer = lex::init(&buf, "<string>");
	let ident: []str = []; // TODO: errdefer
	let z = 0z;
	for (true) {
		const tok = lex::lex(&lexer)?;
		const name = if (tok.0 == lex::ltok::NAME) {
			yield tok.1 as str;
		} else if (tok.0 < lex::ltok::LAST_KEYWORD) {
			yield lex::tokstr(tok);
		} else {
			lex::unlex(&lexer, tok);
			const loc = lex::mkloc(&lexer);
			const why = "Unexpected trailing :: in ident";
			return (loc, why): lex::syntax: parse::error;
		};
		append(ident, name);
		z += len(name);
		const tok = lex::lex(&lexer)?;
		switch (tok.0) {
		case lex::ltok::EOF =>
			break;
		case lex::ltok::DOUBLE_COLON =>
			z += 1;
		case =>
			lex::unlex(&lexer, tok);
			const loc = lex::mkloc(&lexer);
			const why = fmt::asprintf("Unexpected '{}' in ident",
				lex::tokstr(tok));
			return (loc, why): lex::syntax: parse::error;
		};
	};
	if (z > ast::IDENT_MAX) {
		const loc = lex::mkloc(&lexer);
		const why = "Identifier exceeds maximum length";
		return (loc, why): lex::syntax: parse::error;
	};
	return ident;
};

fn init_tty(ctx: *context) io::handle = {
	const pager = match (os::getenv("PAGER")) {
	case let name: str =>
		yield match (exec::cmd(name)) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			return os::stdout;
		};
	case void =>
		yield match (exec::cmd("less")) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			yield match (exec::cmd("more")) {
			case let cmd: exec::command =>
				yield cmd;
			case exec::error =>
				return os::stdout;
			};
		};
	};

	const pipe = exec::pipe();
	exec::addfile(&pager, os::stdin_file, pipe.0);
	exec::setenv(&pager, "LESS", "FRX")!;
	ctx.pager = exec::start(&pager)!;
	return pipe.1;
};

fn has_decl(decl: ast::decl, name: str) bool = {
	if (!decl.exported) {
		return false;
	};

	match (decl.decl) {
	case let d: []ast::decl_const =>
		for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		};
	case let d: ast::decl_func =>
		if (len(d.ident) == 1 && d.ident[0] == name) {
			return true;
		};
		const sym = strings::split(d.symbol, ".");
		defer free(sym);
		return len(sym) > 0 && sym[len(sym) - 1] == name;
	case let d: []ast::decl_global =>
		for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		};
	case let d: []ast::decl_type =>
		for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		};
	};
	return false;
};

fn scan(path: str) (ast::subunit | error) = {
	const input = match (os::open(path)) {
	case let f: io::file =>
		yield f;
	case let err: fs::error =>
		fmt::fatalf("Error reading {}: {}", path, fs::strerror(err));
	};
	defer io::close(input)!;
	const lexer = lex::init(input, path, lex::flags::COMMENTS);
	return parse::subunit(&lexer)?;
};

fn emit(ctx: *context) (void | error) = {
	switch (ctx.format) {
	case format::HARE =>
		emit_hare(ctx)?;
	case format::TTY =>
		emit_tty(ctx)?;
	case format::HTML =>
		emit_html(ctx)?;
	case format::GEMTEXT => abort(); // TODO
	};
};

@test fn parseident() void = {
	assert(parseident("hare::lex") is ast::ident);
	assert(parseident("strings::dup*{}&@") is parse::error);
	assert(parseident("foo::bar::") is parse::error);
	assert(parseident("rt::abort") is ast::ident);
};
