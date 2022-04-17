// License: GPL-3.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use hare::unit;
use hare::unparse;
use io;
use os;
use unix;

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

	let out = os::stdout;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'D' => abort(); // TODO
		case 'N' => abort(); // TODO
		case 'T' => abort(); // TODO
		case 'o' =>
			out = match (os::create(opt.1, 0o644)) {
			case let f: io::file =>
				yield f;
			case let e: fs::error =>
				fmt::fatal(fs::strerror(e));
			};
		case 't' => abort(); // TODO
		case => abort();
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
		ast::subunit_finish(subunits[i]);
	};

	for (let i = 0z; i < len(cmd.args); i += 1) {
		let input = match (os::open(cmd.args[i])) {
		case let f: io::file =>
			yield f;
		case let err: fs::error =>
			fmt::fatal("Error opening {}: {}",
				cmd.args[i], fs::strerror(err));
		};
		defer io::close(input);
		static let buf: [os::BUFSIZ]u8 = [0...];
		let bufin = bufio::buffered(input, buf, []);
		defer io::close(&bufin);

		let lexer = lex::init(&bufin, cmd.args[i]);
		let su = match (parse::subunit(&lexer)) {
		case let err: parse::error =>
			printerr(err);
			os::exit(1);
		case let u: ast::subunit =>
			yield u;
		};
		append(subunits, su);
	};

	let unit = match (unit::check(store, [], subunits)) {
	case unit::error => abort(); // TODO
	case let u: unit::unit =>
		yield u;
	};
	defer unit::unit_finish(unit);
	gen(out, store, &unit);
};
