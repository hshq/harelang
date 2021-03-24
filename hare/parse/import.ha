use hare::ast;
use hare::lex;
use hare::lex::{btoken};

fn name_list(lexer: *lex::lexer) ([]str | error) = {
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
				let objects = name_list(lexer)?;
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
