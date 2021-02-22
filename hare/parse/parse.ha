use hare::ast;
use hare::lex;

// Parses a single identifier, i.e. foo::bar::baz
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	let ident = ast::ident { ... }, cur = &ident;
	for (true) {
		cur.name = match (want_name(lexer)) {
			err: error => return err,
			n: lex::name => n: str,
		};

		match (try_btoken(lexer, hare::lex::btoken::DOUBLE_COLON)) {
			err: error => return err,
			void => break,
			* => void, // Grab the next ident
		};

		let new = alloc(*ast::ident, ast::ident { ... });
		cur.ns = new;
		cur = new;
	};
	return ident;
};
