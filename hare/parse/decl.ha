use ascii;
use hare::ast;
use hare::lex::{ltok};
use hare::lex;
use hare::unparse;
use strings;

fn attr_symbol(lexer: *lex::lexer) (str | error) = {
	want_tok(lexer, ltok::LPAREN)?;
	let t = want_tok(lexer, ltok::LITERAL)?;
	let s = match (t.1) {
		v: lex::value => if (v.storage == lex::storage::STR) v.string
			else return syntaxerr(t.2,
				"Unexpected {}, was expecting string",
				lex::tokstr(t)),
		* => return syntaxerr(t.2,
			"Unexpected {}, was expecting string",
			lex::tokstr(t)),
	};
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
	want_tok(lexer, ltok::RPAREN)?;
	return s;
};

fn decl_global(
	lexer: *lex::lexer,
	tok: ltok
) ([]ast::decl_global | error) = {
	let decl: []ast::decl_global = [];
	for (true) {
		let symbol = if (tok == ltok::CONST || tok == ltok::LET) {
			match (try_tok(lexer, ltok::ATTR_SYMBOL)?) {
				void => "",
				lex::token => attr_symbol(lexer)?,
			};
		} else "";
		let ident = ident(lexer)?;
		want_tok(lexer, ltok::COLON)?;
		let _type = _type(lexer)?;
		if (tok == ltok::CONST) {
			_type.flags |= ast::type_flags::CONST;
		};
		want_tok(lexer, ltok::EQUAL)?;
		let init = expression(lexer)?;
		let btok = try_tok(lexer, ltok::COMMA)?;
		append(decl, ast::decl_global {
			is_const = tok == ltok::DEF,
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
		want_tok(lexer, ltok::EQUAL)?;
		let _type = _type(lexer)?;
		let btok = try_tok(lexer, ltok::COMMA)?;
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
	for (true) match (try_tok(lexer, attrs...)?) {
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

	want_tok(lexer, ltok::FN)?;
	let ident_loc = mkloc(lexer);
	let ident = ident(lexer)?;
	let proto_loc = mkloc(lexer);
	let prototype = prototype(lexer)?;
	if (noreturn) {
		prototype.attrs |= ast::func_attrs::NORETURN;
	};

	let tok = want_tok(lexer, ltok::EQUAL, ltok::SEMICOLON)?;
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
			loc = proto_loc,
			flags = ast::type_flags::CONST,
			_type = prototype,
		},
		body = body,
		attrs = attr,
	};
};

// Parses the declarations for a sub-unit
export fn decls(lexer: *lex::lexer) ([]ast::decl | error) = {
	let decls: []ast::decl = [];
	for (true) {
		if (peek_tok(lexer, ltok::EOF)? is lex::token) break;
		let exported = match (try_tok(lexer, ltok::EXPORT)?) {
			void => false,
			lex::token => true,
		};
		const toks = [ltok::CONST, ltok::LET, ltok::DEF, ltok::TYPE];
		let decl = match (try_tok(lexer, toks...)?) {
			void => decl_func(lexer)?,
			t: lex::token =>
				if (t.0 == ltok::TYPE) decl_type(lexer)?
				else decl_global(lexer, t.0)?,
		};
		append(decls, ast::decl {
			exported = exported,
			loc = mkloc(lexer),
			decl = decl,
		});
		want_tok(lexer, ltok::SEMICOLON)?;
	};
	return decls;
};
