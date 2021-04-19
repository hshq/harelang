use hare::lex;
use hare::parse;
use io;

type eof = void;
type syntaxerr = void;
type error = (lex::error | parse::error | io::error | syntaxerr | eof)!;

fn strerror(err: error) str = match (err) {
	err: lex::error => lex::strerror(err),
	err: parse::error => parse::strerror(err),
	err: io::error => io::strerror(err),
	_: eof => "Unexpected EOF",
	_: syntaxerr => "Syntax error",
};
