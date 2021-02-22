use hare::ast;
use hare::lex;

// Parses a single identifier, i.e. foo::bar::baz
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	// TODO: This is actually wrong, it builds the idents backwards. Whoops
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

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try_btoken(lexer, hare::lex::btoken::USE)) {
			err: error => return err,
			void => break,
			* => void,
		};

		let name = match (ident(lexer)) {
			err: error => return err,
			ident: ast::ident => ident,
		};

		// TODO: Parse alternate import syntaxes
		match (want_btoken(lexer, hare::lex::btoken::SEMICOLON)) {
			err: error => return err,
			lex::btoken => void,
		};

		append(imports, name: ast::import_module);
	};
	return imports;
};
