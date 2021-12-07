use hare::lex;
use hare::parse;
use io;

type eof = void;
type syntaxerr = void;
type error = !(lex::error | parse::error | io::error | syntaxerr | eof);

fn strerror(err: error) str = {
	match (err) {
	case let err: lex::error =>
		return lex::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case eof =>
		return "Unexpected EOF";
	case syntaxerr =>
		return "Syntax error";
	};
};
