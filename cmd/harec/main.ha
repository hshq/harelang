use fmt;
use getopt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::unparse;
use io;
use os;

export fn main() void = {
	let cmd = getopt::parse(os::args,
		"compiles Hare programs to an intermediate form",
		('D', "ident:type=value", "defines a constant"),
		('o', "path", "set the output file"),
		('T', "tags...", "sets build tags"),
		('t', "path", "write typedefs to a file"),
		('N', "ident", "set the namespace for unit"),
		"files..."
	);
	defer getopt::finish(&cmd);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'D' => abort(), // TODO
			'o' => abort(), // TODO
			'T' => abort(), // TODO
			't' => abort(), // TODO
			'N' => abort(), // TODO
			*   => abort(),
		};
	};

	for (let i = 0z; i < len(cmd.args); i += 1) {
		let input = match (os::open(cmd.args[i])) {
			f: *io::stream => f,
			err: io::error => fmt::fatal("Error opening {}: {}",
				cmd.args[i], io::errstr(err)),
		};
		defer io::close(input);

		let lexer = lex::init(input, cmd.args[i]);
		let su = match (parse::subunit(&lexer)) {
			err: parse::error => {
				printerr(err);
				os::exit(1);
			},
			u: ast::subunit => u,
		};
		defer ast::subunit_free(su);

		unparse::subunit(os::stdout, su);
	};
};
