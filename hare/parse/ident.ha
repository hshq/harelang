use hare::ast;
use hare::lex;
use hare::lex::{btoken};

fn ident_trailing(lexer: *lex::lexer) ((ast::ident, bool) | error) = {
	let ident: []str = [];
	let z = 0z;
	for (true) {
		let name = match (try_name(lexer)?) {
			n: lex::name => n,
			void => return (ident: ast::ident, true),
		};
		append(ident, name: str);
		z += len(name);
		match (try_btoken(lexer, btoken::DOUBLE_COLON)?) {
			void => break,
			* => void, // Grab the next ident
		};
		z += 1;
	};
	if (z > ast::IDENT_MAX) {
		ast::ident_free(ident: ast::ident);
		return syntaxerr(mkloc(lexer),
			"Identifier exceeds maximum length");
	};
	return (ident: ast::ident, false);
};

// Parses a single identifier, i.e. foo::bar::baz
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	let ident = ident_trailing(lexer)?;
	synassert(mkloc(lexer), !ident.1, "Unexpected trailing :: in ident")?;
	return ident.0;
};
