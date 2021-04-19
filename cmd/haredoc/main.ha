use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use os;
use strings;

type format = enum {
	HARE,
	TTY,
	HTML,
	GEMTEXT,
};

export fn main() void = {
	// TODO: Use format::TTY by default if stdout is a tty
	let fmt = format::HARE;
	const cmd = getopt::parse(os::args,
		"reads and formats Hare documentation",
		('F', "format", "specify output format (hare, tty, html, or gemtext)"),
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
			* => abort(),
		};
	};

	let unit: []ast::subunit = [];
	defer {
		for (let i = 0z; i < len(unit); i += 1) {
			ast::subunit_free(unit[i]);
		};
		free(unit);
	};

	for (let i = 0z; i < len(cmd.args); i += 1) {
		match (scan(cmd.args[i])) {
			u: ast::subunit => append(unit, u),
			err: error => fmt::fatal("Error: {}", strerror(err)),
		};
	};

	for (let i = 0z; i < len(unit); i += 1) {
		match (emit(unit[i].decls, fmt)) {
			void => void,
			err: error => fmt::fatal("Error: {}", strerror(err)),
		};
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

fn emit(decls: []ast::decl, fmt: format) (void | error) = switch (fmt) {
	format::HARE => emit_hare(decls),
	format::TTY => abort(), // TODO
	format::HTML => abort(), // TODO
	format::GEMTEXT => abort(), // TODO
};
