use hare::ast;
use hare::lex;
use hare::lex::{btoken};
use slice;

fn ident_trailing(lexer: *lex::lexer) ((ast::ident, bool) | error) = {
	let ident: []str = [];
	let z = 0z;
	for (true) {
		let name = match (try_name(lexer)?) {
			n: lex::name => n,
			void => {
				slice::reverse(ident, size(ast::ident));
				return (ident: ast::ident, true);
			},
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
	slice::reverse(ident, size(ast::ident));
	return (ident: ast::ident, false);
};

// Parses a single identifier, i.e. foo::bar::baz
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	let ident = ident_trailing(lexer)?;
	synassert(mkloc(lexer), !ident.1, "Unexpected trailing :: in ident");
	return ident.0;
};

fn parse_name_list(lexer: *lex::lexer) ([]str | error) = {
	let names: []str = [];
	for (true) {
		append(names, want_name(lexer)?: str);
		switch (want_btoken(lexer, btoken::COMMA, btoken::RBRACE)?) {
			btoken::COMMA => match (try_btoken(lexer, btoken::RBRACE)?) {
				void => void,
				* => return names,
			},
			btoken::RBRACE => return names,
			* => abort(), // Unreachable
		};
	};
	abort();
};

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try_btoken(lexer, btoken::USE)?) {
			void => break,
			* => void,
		};

		let name = ident_trailing(lexer)?;

		switch (want_btoken(lexer, btoken::SEMICOLON, btoken::LBRACE,
				btoken::EQUAL)?) {
			btoken::SEMICOLON => {
				synassert(mkloc(lexer), !name.1,
					"Unexpected trailing :: in ident")?;
				append(imports, name.0: ast::import_module);
			},
			btoken::LBRACE => {
				synassert(mkloc(lexer), name.1,
					"Expected trailing :: in ident")?;
				let objects = parse_name_list(lexer)?;
				append(imports, ast::import_objects {
					ident = name.0,
					objects = objects,
				});
				want_btoken(lexer, btoken::SEMICOLON)?;
			},
			btoken::EQUAL => {
				synassert(mkloc(lexer),
					len(name.0) == 1 && !name.1,
					"Expected name, not ident")?;
				let ident = ident(lexer)?;
				append(imports, ast::import_alias {
					ident = ident,
					alias = name.0[0],
				});
				want_btoken(lexer, btoken::SEMICOLON)?;
			},
			* => abort(), // Unreachable
		};
	};
	return imports;
};
