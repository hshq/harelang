use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::unparse;
use io;
use os;

export fn main() void = {
	let input = os::open(os::args[1]) as *io::stream;
	defer io::close(input);

	let lexer = lex::init(input, os::args[1]);
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
