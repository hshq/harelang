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
};

export fn main() void = {
	let fmt =
		if (tty::isatty(os::stdout_file))
			format::TTY
		else
			format::HARE;
	let template = true;
	let show_undocumented = false;
	const help: [_]getopt::help = [
		"reads and formats Hare documentation",
		('F', "format", "specify output format (hare, tty, html, or gemtext)"),
		('t', "disable HTML template (requires postprocessing)"),
		('a', "show undocumented members (only applies to -Fhare and -Ftty)"),
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
				fmt::fatal("Invalid format {}", opt.1);
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
	defer free(decls); // TODO: Free interior state

	let tags = default_tags();
	defer module::tags_free(tags);

	let ctx = module::context_init(tags, [], default_harepath());
	defer module::context_finish(&ctx);

	const id: ast::ident =
		if (len(cmd.args) < 1) []
		else match (parse::identstr(cmd.args[0])) {
		case err: parse::error =>
			fmt::fatal(parse::strerror(err));
		case id: ast::ident =>
			yield id;
		};

	let decl = "";
	let dirname = if (len(id) < 2) id else id[..len(id) - 1];
	const version = match (module::lookup(&ctx, id)) {
	case ver: module::version =>
		yield ver;
	case err: module::error =>
		yield match (module::lookup(&ctx, dirname)) {
		case ver: module::version =>
			assert(len(id) >= 2);
			decl = id[len(id) - 1];
			yield ver;
		case err: module::error =>
			fmt::fatal(
				"Error scanning input module: {}",
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
		case u: ast::subunit =>
			append(decls, u.decls...);
		case err: error =>
			fmt::fatal("Error: {}", strerror(err));
		};
	};

	const rpath = path::join(version.basedir, "README");
	defer free(rpath);
	const readme: (io::file | void) = if (decl == "") {
		yield match (os::open(rpath)) {
		case err: fs::error =>
			yield void;
		case f: io::file =>
			yield f;
		};
	} else void;

	defer match (readme) {
	case void => void;
	case f: io::file =>
		io::close(f);
	};

	if (decl != "") {
		let new: []ast::decl = [];
		for (let i = 0z; i < len(decls); i += 1) {
			if (has_decl(decls[i], decl)) {
				append(new, decls[i]);
			} else {
				ast::decl_free(decls[i]);
			};
		};
		if (len(new) == 0) {
			fmt::fatal("Could not find {}::{}",
				unparse::identstr(dirname), decl);
		};
		free(decls);
		decls = new;

		show_undocumented = true;
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
	};
	match (emit(&ctx)) {
	case void => void;
	case err: error =>
		fmt::fatal("Error: {}", strerror(err));
	};
};

fn has_decl(decl: ast::decl, name: str) bool = {
	if (!decl.exported) {
		return false;
	};

	match (decl.decl) {
	case d: []ast::decl_const =>
		for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		};
	case d: ast::decl_func =>
		return len(d.ident) == 1 && d.ident[0] == name;
	case d: []ast::decl_global =>
		for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		};
	case d: []ast::decl_type =>
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
	case f: io::file =>
		yield f;
	case err: fs::error =>
		fmt::fatal("Error reading {}: {}", path, fs::strerror(err));
	};
	defer io::close(input);
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
