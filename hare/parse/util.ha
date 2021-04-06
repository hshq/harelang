use fmt;
use hare::ast;
use hare::lex;
use io;
use strio;

// Requires the next token to be a name. Returns that name, or an error.
fn want_name(lexer: *lex::lexer) (lex::name | error) = {
	match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Unexpected EOF, was expecting name"),
		t: (lex::token, lex::location) => match (t.0) {
			n: lex::name => return n,
			* => return syntaxerr(mkloc(lexer),
				"Unexpected {}, was expecting name",
				lex::tokstr(t.0)),
		},
	};
};

// Looks for a matching name from the lexer, and if not present, unlexes the
// token and returns void. If found, the token is consumed from the lexer and is
// returned.
fn try_name(lexer: *lex::lexer) (lex::name | error | void) = {
	let tuple = match (lex::lex(lexer)?) {
		io::EOF => return,
		t: (lex::token, lex::location) => match (t.0) {
			n: lex::name => return n,
			* => t,
		},
	};
	lex::unlex(lexer, tuple);
};

// Requires the next token to be a name. Returns that name, or an error.
fn want_btoken(
	lexer: *lex::lexer,
	want: lex::btoken...
) (lex::btoken | error) = {
	let tok: lex::token = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer), "Unexpected EOF"),
		t: (lex::token, lex::location) => match (t.0) {
			b: lex::btoken => {
				if (len(want) == 0) {
					return b;
				};
				for (let i = 0z; i < len(want); i += 1) {
					if (b == want[i]) {
						return b;
					};
				};
				t.0;
			},
			* => t.0,
		},
	};

	let buf = strio::dynamic();
	defer io::close(buf);
	for (let i = 0z; i < len(want); i += 1) {
		fmt::fprintf(buf, lex::tokstr(want[i]));
		if (i + 1 < len(want)) {
			fmt::fprint(buf, ", ");
		};
	};
	return syntaxerr(mkloc(lexer), "Unexpected {}, was expecting {}",
		lex::tokstr(tok), strio::string(buf));
};

// Looks for a matching btoken from the lexer, and if not present, unlexes the
// token and returns void. If found, the token is consumed from the lexer and is
// returned.
fn try_btoken(
	lexer: *lex::lexer,
	want: lex::btoken...
) (lex::btoken | error | void) = {
	let tok = lex::lex(lexer);
	let tuple = match (tok?) {
		io::EOF => return,
		t: (lex::token, lex::location) => {
			match (t.0) {
				b: lex::btoken =>
				for (let i = 0z; i < len(want); i += 1) {
					if (b == want[i]) {
						return b;
					};
				},
				* => void,
			};
			t;
		},
	};
	lex::unlex(lexer, tuple);
};

// Looks for a matching btoken from the lexer, unlexes the token, and returns
// it; or void if it was not a btoken.
fn peek_btoken(
	lexer: *lex::lexer,
	want: lex::btoken...
) (lex::btoken | error | void) = {
	let tok = lex::lex(lexer);
	let tuple = match (tok?) {
		io::EOF => return,
		t: (lex::token, lex::location) => {
			match (t.0) {
				b: lex::btoken =>
				for (let i = 0z; i < len(want); i += 1) {
					if (b == want[i]) {
						lex::unlex(lexer, t);
						return b;
					};
				},
				* => void,
			};
			t;
		},
	};
	lex::unlex(lexer, tuple);
};

// Identical to [lex::lex], but considers io::EOF a syntax error.
fn mustlex(lexer: *lex::lexer) ((lex::token, lex::location) | error) = {
	return match (lex::lex(lexer)) {
		err: lex::error => err,
		io::EOF => syntaxerr(mkloc(lexer), "Unexpected EOF"),
		t: (lex::token, lex::location) => t,
	};
};

// Returns a syntax error if cond is false and void otherwise
fn synassert(loc: lex::location, cond: bool, msg: str) (void | error) = {
	if (!cond) {
		return syntaxerr(loc, msg);
	};
};
