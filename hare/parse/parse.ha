use hare::ast;
use hare::lex;

// All possible error types
export type error = lex::error;

// Convert an error into a human-friendly string
export fn errstr(err: error) const str = lex::errstr(err: lex::error);

// Parses a single identifier, i.e. foo::bar::baz
export fn identifier(lexer: *lex::lexer) (ast::identifier | error) = {
	let ident = ast::identifier { ... }, cur = &ident;
	for (true) {
		let tok = lex::lex(lexer);
		match (tok) {
			io::EOF => abort(), // TODO: Syntax error
			err: lex::error => return err,
			t: (lex::token, lex::location) => match (t.0) {
				n: lex::name => cur.name = n: str,
				* => {
					lex::unlex(lexer, t);
					break;
				},
			},
		};

		tok = lex::lex(lexer);
		match (tok) {
			io::EOF => break,
			err: lex::error => return err,
			t: (lex::token, lex::location) => match (t.0) {
				b: lex::btoken => switch (b) {
					hare::lex::btoken::DOUBLE_COLON => {
						let new = alloc(*ast::identifier,
							ast::identifier { ... });
						cur.ns = new;
						cur = new;
					},
					* => {
						lex::unlex(lexer, t);
						break;
					},
				},
				* => {
					lex::unlex(lexer, t);
					break;
				},
			},
		};
	};
	return ident;
};
