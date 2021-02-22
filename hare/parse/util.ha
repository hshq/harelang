use hare::ast;
use hare::lex;

// Requires the next token to be a name. Returns that name, or an error.
fn want_name(lexer: *lex::lexer) (lex::name | error) = {
	match (lex::lex(lexer)) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected name, found EOF"),
		err: lex::error => return err,
		t: (lex::token, lex::location) => match (t.0) {
			n: lex::name => return n,
			// TODO: Use fmt+lex::tokstr here:
			* => return syntaxerr(mkloc(lexer),
				"Expected name, got <something else>"),
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
	let tuple = match (tok) {
		io::EOF => return,
		err: lex::error => return err,
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
