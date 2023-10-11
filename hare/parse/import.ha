// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};

fn name_list(lexer: *lex::lexer) (ast::import_members | error) = {
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
};

// Parses the import list for a sub-unit
export fn imports(lexer: *lex::lexer) ([]ast::import | error) = {
	let imports: []ast::import = [];
	for (true) {
		match (try(lexer, ltok::USE)?) {
		case void => break;
		case => void;
		};

		append(imports, ast::import {
			bindings = void,
			...
		});
		let import = &imports[len(imports) - 1];
		import.start = lex::mkloc(lexer);
		let (name, trailing) = ident_trailing(lexer)?;
		import.ident = name;
		switch (want(lexer, ltok::SEMICOLON, ltok::LBRACE,
			ltok::EQUAL, ltok::TIMES)?.0) {
		case ltok::SEMICOLON =>
			synassert(lex::mkloc(lexer), !trailing,
				"Unexpected trailing :: in ident")?;
		case ltok::LBRACE =>
			synassert(lex::mkloc(lexer), trailing,
				"Expected trailing :: in ident")?;
			import.bindings = name_list(lexer)?;
			want(lexer, ltok::SEMICOLON)?;
		case ltok::EQUAL =>
			synassert(lex::mkloc(lexer),
				len(name) == 1 && !trailing,
				"Expected name, not ident")?;
			import.bindings = name[0];
			free(name);
			import.ident = ident(lexer)?;
			want(lexer, ltok::SEMICOLON)?;
		case ltok::TIMES =>
			synassert(lex::mkloc(lexer), trailing,
				"Expected trailing :: in ident")?;
			import.bindings = ast::import_wildcard;
			want(lexer, ltok::SEMICOLON)?;
		case => abort(); // Unreachable
		};
		import.end = lex::mkloc(lexer);
	};
	return imports;
};
