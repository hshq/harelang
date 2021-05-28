use ascii;
use hare::ast;
use hare::lex::{ltok};
use hare::lex;
use hare::unparse;
use strings;

fn attr_symbol(lexer: *lex::lexer) (str | error) = {
	want(lexer, ltok::LPAREN)?;
	let t = want(lexer, ltok::LIT_STR)?;
	let s = t.1 as str;
	let d = strings::iter(s);
	match (strings::next(&d)) {
		void => void,
		r: rune => synassert(t.2,
			ascii::isalpha(r) || r == '.' || r == '_',
			"Invalid symbol")?,
	};
	for (true) match (strings::next(&d)) {
		void => break,
		r: rune => synassert(t.2,
			ascii::isalnum(r) || r == '$' || r == '.' || r == '_',
			"Invalid symbol")?,
	};
	want(lexer, ltok::RPAREN)?;
	return s;
};

fn decl_const(
	lexer: *lex::lexer,
	tok: ltok,
) ([]ast::decl_const | error) = {
	let decl: []ast::decl_const = [];
	for (true) {
		const ident = ident(lexer)?;
		want(lexer, ltok::COLON)?;
		const _type = _type(lexer)?;
		want(lexer, ltok::EQUAL)?;
		const init: *ast::expr = alloc(expression(lexer)?);
		append(decl, ast::decl_const {
			ident = ident,
			_type = _type,
			init = init,
		});

		if (try(lexer, ltok::COMMA)? is void) {
			break;
		};
	};
	return decl;

};

fn decl_global(
	lexer: *lex::lexer,
	tok: ltok,
) ([]ast::decl_global | error) = {
	let decl: []ast::decl_global = [];
	for (true) {
		const symbol = match (try(lexer, ltok::ATTR_SYMBOL)?) {
			void => "",
			lex::token => attr_symbol(lexer)?,
		};
		const ident = ident(lexer)?;
		want(lexer, ltok::COLON)?;
		const _type = _type(lexer)?;
		const init: nullable *ast::expr =
			match (try(lexer, ltok::EQUAL)?) {
				lex::token => alloc(expression(lexer)?),
				void => null,
			};
		const btok = try(lexer, ltok::COMMA)?;
		append(decl, ast::decl_global {
			is_const = tok == ltok::CONST,
			symbol = symbol,
			ident = ident,
			_type = _type,
			init = init,
		});
		match (btok) {
			void => break,
			* => void,
		};
	};
	return decl;
};

fn decl_type(lexer: *lex::lexer) ([]ast::decl_type | error) = {
	let decl: []ast::decl_type = [];
	for (true) {
		let ident = ident(lexer)?;
		want(lexer, ltok::EQUAL)?;
		let _type = _type(lexer)?;
		let btok = try(lexer, ltok::COMMA)?;
		append(decl, ast::decl_type {
			ident = ident,
			_type = _type,
		});
		match (btok) {
			void => break,
			* => void,
		};
	};
	return decl;
};

fn decl_func(lexer: *lex::lexer) (ast::decl_func | error) = {
	let attr = ast::fndecl_attrs::NONE, noreturn = false, sym = "";
	const attrs = [
		ltok::ATTR_FINI, ltok::ATTR_INIT, ltok::ATTR_TEST,
		ltok::ATTR_NORETURN, ltok::ATTR_SYMBOL
	];
	for (true) match (try(lexer, attrs...)?) {
		void => break,
		t: lex::token => switch (t.0) {
			ltok::ATTR_FINI => attr = ast::fndecl_attrs::FINI,
			ltok::ATTR_INIT => attr = ast::fndecl_attrs::INIT,
			ltok::ATTR_TEST => attr = ast::fndecl_attrs::TEST,
			ltok::ATTR_NORETURN => noreturn = true,
			ltok::ATTR_SYMBOL => sym = attr_symbol(lexer)?,
			* => abort("unreachable"),
		},
	};

	want(lexer, ltok::FN)?;
	let ident_loc = lex::mkloc(lexer);
	let ident = ident(lexer)?;
	let proto_start = lex::mkloc(lexer);
	let prototype = prototype(lexer)?;
	let proto_end = lex::prevloc(lexer);
	if (noreturn) {
		prototype.attrs |= ast::func_attrs::NORETURN;
	};

	let tok = want(lexer, ltok::EQUAL, ltok::SEMICOLON)?;
	let body = switch (tok.0) {
		ltok::EQUAL => {
			synassert(ident_loc, len(ident) == 1,
				"Unexpected identifier, was expecting name")?;
			const params = prototype.params;
			for (let i = 0z; i < len(params); i += 1) {
				synassert(params[i].loc,
					len(params[i].name) > 0,
					"Expected parameter name in function declaration")?;
			};
			expression(lexer)?;
		},
		ltok::SEMICOLON => lex::unlex(lexer, tok),
	};

	return ast::decl_func {
		symbol = sym,
		ident = ident,
		prototype = ast::_type {
			start = proto_start,
			end = proto_end,
			flags = ast::type_flags::CONST,
			_type = prototype,
		},
		body = body,
		attrs = attr,
	};
};

// Parses the declarations for a sub-unit.
export fn decls(lexer: *lex::lexer) ([]ast::decl | error) = {
	let decls: []ast::decl = [];
	for (true) {
		if (peek(lexer, ltok::EOF)? is lex::token) break;
		let comment = "";
		let exported = match (try(lexer, ltok::EXPORT)?) {
			void => false,
			lex::token => {
				comment = strings::dup(lex::comment(lexer));
				true;
			},
		};
		const toks = [ltok::CONST, ltok::LET, ltok::DEF, ltok::TYPE];
		const next = try(lexer, toks...)?;
		if (comment == "") {
			comment = strings::dup(lex::comment(lexer));
		};
		let decl = match (next) {
			void => decl_func(lexer)?,
			t: lex::token => switch (t.0) {
				ltok::TYPE => decl_type(lexer)?,
				ltok::LET, ltok::CONST =>
					decl_global(lexer, t.0)?,
				ltok::DEF => decl_const(lexer, t.0)?,
				* => abort(),
			},
		};
		append(decls, ast::decl {
			exported = exported,
			loc = lex::mkloc(lexer),
			decl = decl,
			docs = comment,
		});
		want(lexer, ltok::SEMICOLON)?;
	};
	return decls;
};
