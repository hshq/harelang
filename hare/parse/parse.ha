use fmt;
use hare::ast;
use hare::lex;
use io;
use strio;

// All possible error types
export type error = lex::error!;

// Convert an error into a human-friendly string
export fn strerror(err: error) const str = lex::strerror(err: lex::error);

fn syntaxerr(
	loc: lex::location,
	fmt: str,
	args: fmt::formattable...
) lex::error = {
	let why = fmt::asprintf(fmt, args...);
	return (loc, why): lex::syntax: lex::error;
};

fn mkloc(lex: *lex::lexer) lex::location = lex::location {
	path = lex.path,
	line = lex.loc.0,
	col = lex.loc.1,
};

// Requires the next token to have a matching ltok. Returns that token, or an
// error.
fn want(lexer: *lex::lexer, want: lex::ltok...) (lex::token | error) = {
	let tok = lex::lex(lexer)?;
	if (len(want) == 0) {
		return tok;
	};
	for (let i = 0z; i < len(want); i += 1) {
		if (tok.0 == want[i]) {
			return tok;
		};
	};

	let buf = strio::dynamic();
	defer io::close(buf);
	for (let i = 0z; i < len(want); i += 1) {
		fmt::fprintf(buf, "'{}'", lex::tokstr((want[i], void, mkloc(lexer))));
		if (i + 1 < len(want)) {
			fmt::fprint(buf, ", ");
		};
	};
	return syntaxerr(mkloc(lexer), "Unexpected '{}', was expecting {}",
		lex::tokstr(tok), strio::string(buf));
};

// Looks for a matching ltok from the lexer, and if not present, unlexes the
// token and returns void. If found, the token is consumed from the lexer and is
// returned.
fn try(
	lexer: *lex::lexer,
	want: lex::ltok...
) (lex::token | error | void) = {
	let tok = lex::lex(lexer)?;
	assert(len(want) > 0);
	for (let i = 0z; i < len(want); i += 1) {
		if (tok.0 == want[i]) {
			return tok;
		};
	};
	lex::unlex(lexer, tok);
};

// Looks for a matching ltok from the lexer, unlexes the token, and returns
// it; or void if it was not a ltok.
fn peek(
	lexer: *lex::lexer,
	want: lex::ltok...
) (lex::token | error | void) = {
	let tok = lex::lex(lexer)?;
	lex::unlex(lexer, tok);
	if (len(want) == 0) {
		return tok;
	};
	for (let i = 0z; i < len(want); i += 1) {
		if (tok.0 == want[i]) {
			return tok;
		};
	};
};

// Returns a syntax error if cond is false and void otherwise
fn synassert(loc: lex::location, cond: bool, msg: str) (void | error) = {
	if (!cond) {
		return syntaxerr(loc, msg);
	};
};
