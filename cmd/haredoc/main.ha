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

type format = enum {
	HARE,
	TTY,
	HTML,
	GEMTEXT,
};

type context = struct {
	ident: ast::ident,
	tags: []module::tag,
	version: module::version,
	summary: summary,
	format: format,
	template: bool,
	readme: nullable *io::stream,
};

export fn main() void = {
	// TODO: Use format::TTY by default if stdout is a tty
	let fmt = format::HARE;
	let template = true;
	const cmd = getopt::parse(os::args,
		"reads and formats Hare documentation",
		('F', "format", "specify output format (hare, tty, html, or gemtext)"),
		('t', "disable HTML template (requries postprocessing)"),
		"[identifiers...]",
	);
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
			* => abort(),
		};
	};

	let decls: []ast::decl = [];
	defer free(decls); // TODO: Free interior state

	let tags = default_tags();
	defer module::tags_free(tags);

	let ctx = module::context_init(tags, [], default_harepath());
	defer module::context_finish(&ctx);

	assert(len(cmd.args) == 1); // TODO: Something more sophisticated here

	const id = match (parse::identstr(cmd.args[0])) {
		err: parse::error => fmt::fatal(parse::strerror(err)),
		id: ast::ident => id,
	};

	const version = match (module::lookup(&ctx, id)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal(
			"Error scanning input module: {}",
			module::strerror(err)),
	};

	for (let i = 0z; i < len(version.inputs); i += 1) {
		const in = version.inputs[i];
		match (scan(in.path)) {
			u: ast::subunit => append(decls, u.decls...),
			err: error => fmt::fatal("Error: {}", strerror(err)),
		};
	};

	const rpath = path::join(version.basedir, "README");
	defer free(rpath);
	const readme: nullable *io::stream = match (os::open(rpath)) {
		err: fs::error => null,
		f: *io::stream => f,
	};
	defer match (readme) {
		null => void,
		f: *io::stream => io::close(f),
	};

	let dctx = context {
		ident = id,
		tags = tags,
		version = version,
		summary = sort_decls(decls),
		format = fmt,
		template = template,
		readme = readme,
	};
	match (emit(&dctx)) {
		_: void => void,
		err: error => fmt::fatal("Error: {}", strerror(err)),
	};
};

fn scan(path: str) (ast::subunit | error) = {
	const input = match (os::open(path)) {
		s: *io::stream => s,
		err: fs::error => fmt::fatal("Error reading {}: {}",
			path, fs::strerror(err)),
	};
	defer io::close(input);
	const lexer = lex::init(input, "<stdin>", lex::flags::COMMENTS);
	return parse::subunit(&lexer)?;
};

fn emit(ctx: *context) (void | error) = switch (ctx.format) {
	format::HARE => emit_hare(ctx),
	format::TTY => abort(), // TODO
	format::HTML => emit_html(ctx)?,
	format::GEMTEXT => abort(), // TODO
};
