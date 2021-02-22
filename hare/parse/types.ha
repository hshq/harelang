use hare::lex;

// All possible error types
export type error = lex::error;

// Convert an error into a human-friendly string
export fn errstr(err: error) const str = lex::errstr(err: lex::error);

fn syntaxerr(loc: lex::location, why: str) lex::error =
	(loc, why): lex::syntax: lex::error;

fn mkloc(lex: *lex::lexer) lex::location = lex::location {
	path = lex.path,
	line = lex.loc.0,
	col = lex.loc.1,
};
