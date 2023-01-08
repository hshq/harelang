// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use hare::ast;
use hare::lex;
use hare::lex::{ltok};

use fmt;

fn name_list(lexer: *lex::lexer) ([]((str | void), str) | error) = {
	let names: []((str | void), str) = [];
	for (true) {
		append(names, (void, want(lexer, ltok::NAME)?.1 as str));
		match (try(lexer, ltok::EQUAL)?) {
		case void => void;
		case =>
			let name = &names[len(names) - 1];
			name.0 = name.1;
			name.1 = want(lexer, ltok::NAME)?.1 as str;
		};

		switch (want(lexer, ltok::EQUAL, ltok::COMMA, ltok::RBRACE)?.0) {
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

		append(imports, ast::import { ... });
		let import = &imports[len(imports) - 1];
		import.start = lex::mkloc(lexer);
		for (true) {
			let name = ident_trailing(lexer)?;
			import.ident = name.0;
			switch (want(lexer, ltok::SEMICOLON, ltok::LBRACE,
				ltok::EQUAL, ltok::TIMES)?.0) {
			case ltok::SEMICOLON =>
				synassert(lex::mkloc(lexer), !name.1,
					"Unexpected trailing :: in ident")?;
				break;
			case ltok::LBRACE =>
				synassert(lex::mkloc(lexer), name.1,
					"Expected trailing :: in ident")?;
				import.mode |= ast::import_mode::MEMBERS;
				import.objects = name_list(lexer)?;
				want(lexer, ltok::SEMICOLON)?;
				break;
			case ltok::EQUAL =>
				synassert(lex::mkloc(lexer),
					len(name.0) == 1 && !name.1,
					"Expected name, not ident")?;
				import.alias = name.0[0];
				import.mode |= ast::import_mode::ALIAS;
			case ltok::TIMES =>
				synassert(lex::mkloc(lexer), name.1,
					"Expected trailing :: in ident")?;
				synassert(lex::mkloc(lexer),
					import.mode & ast::import_mode::ALIAS == 0,
					"Unexpected * after aliased import")?;
				import.mode |= ast::import_mode::WILDCARD;
				want(lexer, ltok::SEMICOLON)?;
				break;
			case => abort(); // Unreachable
			};
		};
		import.end = lex::mkloc(lexer);
	};
	return imports;
};
