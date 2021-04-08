use ascii;
use hare::ast;
use hare::lex::{btoken};
use hare::lex;
use hare::unparse;
use strings;

fn attr_symbol(lexer: *lex::lexer) (str | error) = {
	want_btoken(lexer, btoken::LPAREN)?;
	let s: (str, lex::location) = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected string, got EOF"),
		t: (lex::token, lex::location) => match (t.0) {
			l: lex::literal => match (l) {
				s: str => (s, t.1),
				* => return syntaxerr(t.1,
					"Unexpected {}, was expecting string",
					lex::tokstr(t.0)),
			},
			* => return syntaxerr(t.1,
				"Unexpected {}, was expecting string",
				lex::tokstr(t.0)),
		},
	};
	let d = strings::iter(s.0);
	match (strings::next(&d)) {
		void => void,
		r: rune => synassert(s.1,
			ascii::isalpha(r) || r == '.' || r == '_',
			"Invalid symbol")?,
	};
	for (true) match (strings::next(&d)) {
		void => break,
		r: rune => synassert(s.1,
			ascii::isalnum(r) || r == '$' || r == '.' || r == '_',
			"Invalid symbol")?,
	};
	want_btoken(lexer, btoken::RPAREN)?;
	return s.0;
};

fn decl_global(
	lexer: *lex::lexer,
	tok: btoken
) ([]ast::decl_global | error) = {
	let decl: []ast::decl_global = [];
	for (true) {
		let symbol = if (tok == btoken::CONST || tok == btoken::LET) {
			match (try_btoken(lexer, btoken::ATTR_SYMBOL)?) {
				void => "",
				lex::btoken => attr_symbol(lexer)?,
			};
		} else "";
		let ident = ident(lexer)?;
		want_btoken(lexer, btoken::COLON)?;
		let _type = _type(lexer)?;
		if (tok == btoken::CONST) {
			_type.flags |= ast::type_flags::CONST;
		};
		want_btoken(lexer, btoken::EQUAL)?;
		let init = expression(lexer)?;
		let btok = try_btoken(lexer, btoken::COMMA)?;
		append(decl, ast::decl_global {
			is_const = tok == btoken::DEF,
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
		want_btoken(lexer, btoken::EQUAL)?;
		let _type = _type(lexer)?;
		let btok = try_btoken(lexer, btoken::COMMA)?;
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
	let attrs = [
		btoken::ATTR_FINI, btoken::ATTR_INIT, btoken::ATTR_TEST,
		btoken::ATTR_NORETURN, btoken::ATTR_SYMBOL
	];
	for (true) match (try_btoken(lexer, attrs...)?) {
		void => break,
		b: lex::btoken => switch (b) {
			btoken::ATTR_FINI => attr = ast::fndecl_attrs::FINI,
			btoken::ATTR_INIT => attr = ast::fndecl_attrs::INIT,
			btoken::ATTR_TEST => attr = ast::fndecl_attrs::TEST,
			btoken::ATTR_NORETURN => noreturn = true,
			btoken::ATTR_SYMBOL => sym = attr_symbol(lexer)?,
			* => abort("unreachable"),
		},
	};

	want_btoken(lexer, btoken::FN)?;
	let ident_loc = mkloc(lexer);
	let ident = ident(lexer)?;
	let proto_loc = mkloc(lexer);
	let prototype = prototype(lexer)?;
	if (noreturn) {
		prototype.attrs |= ast::func_attrs::NORETURN;
	};

	let tok = want_btoken(lexer, btoken::EQUAL, btoken::SEMICOLON)?;
	let body = switch (tok) {
		btoken::EQUAL => {
			synassert(ident_loc, len(ident) == 1,
				"Unexpected identifier, was expecting name")?;
			const params = prototype.params;
			for (let i = 0z; i < len(params); i += 1) {
				synassert(params[i].loc,
					len(params[i].name) > 0,
					"Expected parameter name in function declaration")?;
			};
			compound_expression(lexer)?;
		},
		// We don't care about the location
		btoken::SEMICOLON => lex::unlex(lexer, (tok, proto_loc)),
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
		match (lex::lex(lexer)?) {
			io::EOF => break,
			t: (lex::token, lex::location) => lex::unlex(lexer, t),
		};
		let exported = match (try_btoken(lexer, btoken::EXPORT)?) {
			void => false,
			lex::btoken => true,
		};
		let tok = match(lex::lex(lexer)?) {
			io::EOF => return syntaxerr(mkloc(lexer),
				"Unexpected EOF, was expecting declaration"),
			t: (lex::token, lex::location) => t,
		};
		let btok = match (tok.0) {
			b: lex::btoken => b,
			* => return syntaxerr(mkloc(lexer),
				"Unexpected {}, was expecting declaration",
				lex::tokstr(tok.0)),
		};
		let decl = switch (btok) {
			btoken::CONST, btoken::LET, btoken::DEF =>
				decl_global(lexer, btok)?,
			btoken::TYPE => decl_type(lexer)?,
			* => {
				lex::unlex(lexer, tok);
				decl_func(lexer)?;
			},
		};
		append(decls, ast::decl {
			exported = exported,
			loc = mkloc(lexer),
			decl = decl,
		});
		want_btoken(lexer, btoken::SEMICOLON)?;
	};
	return decls;
};
