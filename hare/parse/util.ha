use hare::ast;
use hare::lex;

// Requires the next token to be a name. Returns that name, or an error.
fn want_name(lexer: *lex::lexer) (lex::name | error) = {
	match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected name, found EOF"),
		t: (lex::token, lex::location) => match (t.0) {
			n: lex::name => return n,
			// TODO: Use fmt+lex::tokstr here:
			* => return syntaxerr(mkloc(lexer),
				"Expected name, got <something else>"),
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
	match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected name, found EOF"),
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
				// TODO: Use fmt+lex::tokstr here:
				return syntaxerr(mkloc(lexer),
					"Expected <something>, got <something else>");
			},
			// TODO: Use fmt+lex::tokstr here:
			* => return syntaxerr(mkloc(lexer),
				"Expected <something>, got <something else>"),
		},
	};
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

// Returns a syntax error if cond is false and void otherwise
fn synassert(loc: lex::location, cond: bool, msg: str) (void | error) = {
	if (!cond) {
		return syntaxerr(loc, msg);
	};
};
