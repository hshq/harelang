// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use cmd::haredoc::doc;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use hare::unparse;
use io;
use memio;
use os;
use os::exec;
use path;
use strconv;
use strings;
use unix::tty;

const help: []getopt::help = [
	"reads and formats Hare documentation",
	('a', "show undocumented members (only applies to -Fhare and -Ftty)"),
	('t', "disable HTML template (requires postprocessing)"),
	('F', "format", "specify output format (hare, tty, or html)"),
	('T', "tagset", "set/unset build tags"),
	"[identifiers...]",
];

export fn main() void = {
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	match (doc(os::args[0], &cmd)) {
	case void => void;
	case let e: doc::error =>
		fmt::fatal(doc::strerror(e));
	case let e: exec::error =>
		fmt::fatal(exec::strerror(e));
	case let e: fs::error =>
		fmt::fatal(fs::strerror(e));
	case let e: io::error =>
		fmt::fatal(io::strerror(e));
	case let e: module::error =>
		fmt::fatal(module::strerror(e));
	case let e: path::error =>
		fmt::fatal(path::strerror(e));
	case let e: parse::error =>
		fmt::fatal(parse::strerror(e));
	case let e: strconv::error =>
		fmt::fatal(strconv::strerror(e));
	};
};

fn doc(name: str, cmd: *getopt::command) (void | error) = {
	let fmt = if (tty::isatty(os::stdout_file)) {
		yield doc::format::TTY;
	} else {
		yield doc::format::HARE;
	};
	let template = true;
	let show_undocumented = false;
	let tags: []str = default_tags()?;
	defer free(tags);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'F' =>
			switch (opt.1) {
			case "hare" =>
				fmt = doc::format::HARE;
			case "tty" =>
				fmt = doc::format::TTY;
			case "html" =>
				fmt = doc::format::HTML;
			case =>
				fmt::fatal("Invalid format", opt.1);
			};
		case 'T' =>
			merge_tags(&tags, opt.1)?;
		case 't' =>
			template = false;
		case 'a' =>
			show_undocumented = true;
		case => abort();
		};
	};

	if (show_undocumented) switch (fmt) {
	case doc::format::HARE, doc::format::TTY => void;
	case =>
		fmt::fatal("Option -a must be used only with -Fhare or -Ftty");
	};

	let decls: []ast::decl = [];
	defer free(decls);

	let ctx = module::context {
		harepath = harepath(),
		harecache = harecache(),
		tags = tags,
	};

	let decl = "";
	let (modpath, srcs, id) = if (len(cmd.args) == 0) {
		let (modpath, srcs) = module::find(&ctx, []: ast::ident)?;
		yield (modpath, srcs, []: ast::ident);
	} else match (parseident(cmd.args[0])) {
	case let id: ast::ident =>
		// first assume it's a module
		yield match (module::find(&ctx, id)) {
		case let r: (str, module::srcset) =>
			yield (r.0, r.1, id);
		case let e: module::error =>
			module::finish_error(e);
			// then assume it's an ident inside a module
			decl = id[len(id)-1];
			id = id[..len(id)-1];
			let (modpath, srcs) = module::find(&ctx, id)?;
			yield (modpath, srcs, id);
		};
	case =>
		let buf = path::buffer { ... };
		path::set(&buf, cmd.args[0])?;
		let (modpath, srcs) = module::find(&ctx, &buf)?;
		yield (modpath, srcs, []: ast::ident);
	};

	for (let i = 0z; i < len(srcs.ha); i += 1) {
		let u = doc::scan(srcs.ha[i])?;
		ast::imports_finish(u.imports);
		append(decls, u.decls...);
	};

	const rpath = path::init(modpath, "README")!;
	const readme: (io::file | void) = if (decl == "") {
		yield match (os::open(path::string(&rpath))) {
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
				unparse::identstr(id), decl);
		};
		free(decls);
		decls = new;

		show_undocumented = true;
	};

	defer for (let i = 0z; i < len(decls); i += 1) {
		ast::decl_finish(decls[i]);
	};

	const ctx = doc::context {
		mctx = &ctx,
		ident = id,
		tags = tags,
		modpath = modpath,
		srcs = srcs,
		submods = if (decl == "") doc::submodules(modpath)? else [],
		summary = doc::sort_decls(decls),
		format = fmt,
		template = template,
		readme = readme,
		show_undocumented = show_undocumented,
		out = os::stdout,
		pager = void,
	};

	if (fmt == doc::format::TTY) {
		ctx.out = init_tty(&ctx);
	};

	const ret = emit(&ctx);

	io::close(ctx.out)!;
	match (ctx.pager) {
	case void => void;
	case let proc: exec::process =>
		exec::wait(&proc)!;
	};

	return ret;
};

// Nearly identical to parse::identstr, except alphanumeric lexical tokens are
// converted to strings and there must be no trailing tokens that don't belong
// to the ident in the string. For example, this function will parse `rt::abort`
// as a valid identifier.
fn parseident(in: str) (ast::ident | parse::error) = {
	const buf = memio::fixed(strings::toutf8(in));
	const lexer = lex::init(&buf, "<string>");
	defer lex::finish(&lexer);
	// XXX: errdefer
	let success = false;
	let ident: ast::ident = [];
	defer if (!success) ast::ident_free(ident);
	let z = 0z;
	for (true) {
		const tok = lex::lex(&lexer)?;
		const name = if (tok.0 == lex::ltok::NAME) {
			yield tok.1 as str;
		} else if (tok.0 < lex::ltok::LAST_KEYWORD) {
			yield strings::dup(lex::tokstr(tok));
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
	success = true;
	return ident;
};

fn init_tty(ctx: *doc::context) io::handle = {
	const pager = match (os::getenv("PAGER")) {
	case let name: str =>
		yield match (exec::cmd(name)) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			return os::stdout;
		};
	case void =>
		yield match (exec::cmd("less", "-R")) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			yield match (exec::cmd("more", "-R")) {
			case let cmd: exec::command =>
				yield cmd;
			case exec::error =>
				return os::stdout;
			};
		};
	};

	const pipe = exec::pipe();
	exec::addfile(&pager, os::stdin_file, pipe.0);
	// Get raw flag in if possible
	exec::setenv(&pager, "LESS", os::tryenv("LESS", "FRX"))!;
	exec::setenv(&pager, "MORE", os::tryenv("MORE", "R"))!;
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

fn emit(ctx: *doc::context) (void | error) = {
	switch (ctx.format) {
	case doc::format::HARE =>
		doc::emit_hare(ctx)?;
	case doc::format::TTY =>
		doc::emit_tty(ctx)?;
	case doc::format::HTML =>
		doc::emit_html(ctx)?;
	};
};

@test fn parseident() void = {
	assert(ast::ident_eq(parseident("hare::lex") as ast::ident,
		["hare", "lex"]));
	assert(ast::ident_eq(parseident("rt::abort") as ast::ident,
		["rt", "abort"]));
	assert(parseident("strings::dup*{}&@") is parse::error);
	assert(parseident("foo::bar::") is parse::error);
};
