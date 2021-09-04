use bufio;
use fmt;
use getopt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use hare::unit;
use hare::unparse;
use io;
use os;

export fn main() void = {
	let usage: []getopt::help = [
		"compiles Hare programs to an intermediate form",
		('D', "ident:type=value", "defines a constant"),
		('T', "tags...", "sets build tags"),
		('N', "ident", "set the namespace for unit"),
		('o', "path", "set the output file"),
		('t', "path", "write typedefs to a file"),
		"files...",
	];
	let cmd = getopt::parse(os::args, usage...);
	defer getopt::finish(&cmd);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'D' => abort(), // TODO
			'N' => abort(), // TODO
			'T' => abort(), // TODO
			'o' => abort(), // TODO
			't' => abort(), // TODO
			*   => abort(),
		};
	};

	if (len(cmd.args) == 0) {
		getopt::printusage(os::stderr, os::args[0], usage);
		os::exit(1);
	};

	// TODO: Use hare::unit resolver
	const store = types::store(types::x86_64, null, null);
	defer types::store_free(store);

	let subunits: []ast::subunit = [];
	defer for (let i = 0z; i < len(subunits); i += 1) {
		ast::subunit_free(subunits[i]);
	};

	for (let i = 0z; i < len(cmd.args); i += 1) {
		let input = match (os::open(cmd.args[i])) {
			f: io::file => f,
			err: io::error => fmt::fatal("Error opening {}: {}",
				cmd.args[i], io::strerror(err)),
		};
		defer io::close(&input);
		static let buf: [os::BUFSIZ]u8 = [0...];
		let bufin = bufio::buffered(&input, buf, []);
		defer io::close(bufin);

		let lexer = lex::init(bufin, cmd.args[i]);
		let su = match (parse::subunit(&lexer)) {
			err: parse::error => {
				printerr(err);
				os::exit(1);
			},
			u: ast::subunit => u,
		};
		append(subunits, su);
	};

	let unit = match (unit::check(store, [], subunits)) {
		unit::error => abort(), // TODO
		u: unit::unit => u,
	};
	defer unit::unit_free(unit);
	gen(store, &unit);
};
