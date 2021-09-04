use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
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
	readme: nullable *io::stream,
};

export fn main() void = {
	let fmt = if (tty::isatty(os::stdout)) format::TTY else format::HARE;
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
			'F' => fmt =
				if (opt.1 == "hare") format::HARE
				else if (opt.1 == "tty") format::TTY
				else if (opt.1 == "html") format::HTML
				else if (opt.1 == "gemtext") format::GEMTEXT
				else fmt::fatal("Invalid format {}", opt.1),
			't' => template = false,
			'a' => show_undocumented = true,
			* => abort(),
		};
	};

	if (show_undocumented) switch (fmt) {
		format::HARE, format::TTY => void,
		* => fmt::fatal("Option -a must be used only with -Fhare or -Ftty"),
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
			err: parse::error => fmt::fatal(parse::strerror(err)),
			id: ast::ident => id,
		};

	let decl = "";
	// TODO: Const type reduction
	let dirname: ast::ident = if (len(id) < 2) id else id[..len(id) - 1];
	const version = match (module::lookup(&ctx, id)) {
		ver: module::version => ver,
		err: module::error => match (module::lookup(&ctx, dirname)) {
			ver: module::version => {
				assert(len(id) >= 2);
				decl = id[len(id) - 1];
				yield ver;
			},
			err: module::error => fmt::fatal(
				"Error scanning input module: {}",
				module::strerror(err)),
			},
	};

	for (let i = 0z; i < len(version.inputs); i += 1) {
		const in = version.inputs[i];
		const ext = path::extension(in.path);
		if (ext.1 != ".ha") {
			continue;
		};
		match (scan(in.path)) {
			u: ast::subunit => append(decls, u.decls...),
			err: error => fmt::fatal("Error: {}", strerror(err)),
		};
	};

	const rpath = path::join(version.basedir, "README");
	defer free(rpath);
	const readme: nullable *io::stream = if (decl == "") {
		yield match (os::open(rpath)) {
			err: fs::error => null,
			f: *io::stream => f,
		};
	} else null;
	defer match (readme) {
		null => void,
		f: *io::stream => io::close(f),
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
		free(decls);
		decls = new;
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
		void => void,
		err: error => fmt::fatal("Error: {}", strerror(err)),
	};
};

fn has_decl(decl: ast::decl, name: str) bool = {
	match (decl.decl) {
		d: []ast::decl_const => for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		},
		d: ast::decl_func =>
			return len(d.ident) == 1 && d.ident[0] == name,
		d: []ast::decl_global => for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		},
		d: []ast::decl_type => for (let i = 0z; i < len(d); i += 1) {
			if (len(d[i].ident) == 1 && d[i].ident[0] == name) {
				return true;
			};
		},
	};
	return false;
};

fn scan(path: str) (ast::subunit | error) = {
	const input = match (os::open(path)) {
		s: *io::stream => s,
		err: fs::error => fmt::fatal("Error reading {}: {}",
			path, fs::strerror(err)),
	};
	defer io::close(input);
	const lexer = lex::init(input, path, lex::flags::COMMENTS);
	return parse::subunit(&lexer)?;
};

fn emit(ctx: *context) (void | error) = switch (ctx.format) {
	format::HARE => emit_hare(ctx),
	format::TTY => emit_tty(ctx),
	format::HTML => emit_html(ctx)?,
	format::GEMTEXT => abort(), // TODO
};
