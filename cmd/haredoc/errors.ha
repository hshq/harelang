use hare::lex;
use hare::parse;

type eof = void;
type syntaxerr = void;
type error = (lex::error | parse::error | syntaxerr | eof)!;

fn strerror(err: error) str = match (err) {
	err: lex::error => lex::strerror(err),
	err: parse::error => parse::strerror(err),
	eof => "Unexpected EOF",
	syntaxerr => "Syntax error",
};
