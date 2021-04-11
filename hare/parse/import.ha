use hare::ast;
use hare::lex;
use hare::lex::{ltok};

fn name_list(lexer: *lex::lexer) ([]str | error) = {
	let names: []str = [];
	for (true) {
		append(names, want_tok(lexer, ltok::NAME)?.1 as str);
		switch (want_tok(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
			ltok::COMMA => match (try_tok(lexer, ltok::RBRACE)?) {
				void => void,
				* => return names,
			},
			ltok::RBRACE => return names,
			* => abort(), // Unreachable
		};
	};
	abort();
};

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try_tok(lexer, ltok::USE)?) {
			void => break,
			* => void,
		};

		let name = ident_trailing(lexer)?;

		switch (want_tok(lexer, ltok::SEMICOLON, ltok::LBRACE,
				ltok::EQUAL)?.0) {
			ltok::SEMICOLON => {
				synassert(mkloc(lexer), !name.1,
					"Unexpected trailing :: in ident")?;
				append(imports, name.0: ast::import_module);
			},
			ltok::LBRACE => {
				synassert(mkloc(lexer), name.1,
					"Expected trailing :: in ident")?;
				let objects = name_list(lexer)?;
				append(imports, ast::import_objects {
					ident = name.0,
					objects = objects,
				});
				want_tok(lexer, ltok::SEMICOLON)?;
			},
			ltok::EQUAL => {
				synassert(mkloc(lexer),
					len(name.0) == 1 && !name.1,
					"Expected name, not ident")?;
				let ident = ident(lexer)?;
				append(imports, ast::import_alias {
					ident = ident,
					alias = name.0[0],
				});
				want_tok(lexer, ltok::SEMICOLON)?;
			},
			* => abort(), // Unreachable
		};
	};
	return imports;
};
