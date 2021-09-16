use hare::ast;
use hare::lex;
use hare::lex::{ltok};

fn name_list(lexer: *lex::lexer) ([]str | error) = {
	let names: []str = [];
	for (true) {
		append(names, want(lexer, ltok::NAME)?.1 as str);

		switch (want(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
		case ltok::COMMA =>
			match (try(lexer, ltok::RBRACE)?) {
			case void => void;
			case =>
				return names;
			};
		case ltok::RBRACE =>
			return names;
		case => abort(); // Unreachable
		};
	};
	abort();
};

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try(lexer, ltok::USE)?) {
		case void => break;
		case => void;
		};

		let name = ident_trailing(lexer)?;
		switch (want(lexer, ltok::SEMICOLON, ltok::LBRACE,
			ltok::EQUAL)?.0) {
		case ltok::SEMICOLON =>
			synassert(lex::mkloc(lexer), !name.1,
				"Unexpected trailing :: in ident")?;
			append(imports, name.0: ast::import_module);
		case ltok::LBRACE =>
			synassert(lex::mkloc(lexer), name.1,
				"Expected trailing :: in ident")?;
			let objects = name_list(lexer)?;
			append(imports, ast::import_objects {
				ident = name.0,
				objects = objects,
			});
			want(lexer, ltok::SEMICOLON)?;
		case ltok::EQUAL =>
			synassert(lex::mkloc(lexer),
				len(name.0) == 1 && !name.1,
				"Expected name, not ident")?;
			let ident = ident(lexer)?;
			append(imports, ast::import_alias {
				ident = ident,
				alias = name.0[0],
			});
			want(lexer, ltok::SEMICOLON)?;
		case => abort(); // Unreachable
		};
	};
	return imports;
};
