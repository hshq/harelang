use hare::ast;
use hare::lex;
use slice;

// Parses a single identifier, i.e. foo::bar::baz
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	let ident: []str = [];
	for (true) {
		let name = want_name(lexer)?;
		append(ident, name: str);
		match (try_btoken(lexer, lex::btoken::DOUBLE_COLON)?) {
			void => break,
			* => void, // Grab the next ident
		};
	};
	slice::reverse(ident, size(ast::ident));
	return ident;
};

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try_btoken(lexer, lex::btoken::USE)?) {
			void => break,
			* => void,
		};

		let name = ident(lexer)?;

		// TODO: Parse alternate import syntaxes
		want_btoken(lexer, lex::btoken::SEMICOLON)?;

		append(imports, name: ast::import_module);
	};
	return imports;
};
