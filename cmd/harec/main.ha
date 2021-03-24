use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::unparse;
use os;

export fn main() void = {
	let lexer = lex::init(os::stdin, "<stdin>");
	let su = match (parse::subunit(&lexer)) {
		e: parse::error =>
			fmt::fatal("Syntax error: {}", parse::errstr(e)),
		u: ast::subunit => u,
	};
	defer ast::subunit_free(su);
	unparse::subunit(os::stdout, su);
};
