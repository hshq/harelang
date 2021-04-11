use hare::ast;
use hare::ast::{builtin_type};
use hare::lex;
use hare::lex::{ltok};

fn prototype(lexer: *lex::lexer) (ast::func_type | error) = {
	let variadism = ast::variadism::NONE;
	let params: []ast::func_param = [];
	want_tok(lexer, ltok::LPAREN)?;
	for (try_tok(lexer, ltok::RPAREN)? is void) {
		let loc = mkloc(lexer);
		match (try_tok(lexer, ltok::ELLIPSIS)?) {
			void => void,
			lex::token => {
				synassert(loc, len(params) > 0,
					"Expected at least one non-variadic parameter for C-style variadism")?;
				variadism = ast::variadism::C;
				try_tok(lexer, ltok::COMMA)?;
				want_tok(lexer, ltok::RPAREN)?;
				break;
			},
		};
		let name = match (try_tok(lexer, ltok::UNDERSCORE)?) {
			void => want_tok(lexer, ltok::NAME)?.1 as str,
			lex::token => "",
		};
		want_tok(lexer, ltok::COLON);
		append(params, ast::func_param {
			loc = loc,
			name = name,
			_type = alloc(_type(lexer)?),
		});
		match (try_tok(lexer, ltok::ELLIPSIS)?) {
			void => void,
			lex::token => {
				variadism = ast::variadism::HARE;
				try_tok(lexer, ltok::COMMA)?;
				want_tok(lexer, ltok::RPAREN)?;
				break;
			},
		};
		match (try_tok(lexer, ltok::COMMA)?) {
			void => {
				want_tok(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};
	let t = _type(lexer)?;
	return ast::func_type {
		result = alloc(t),
		attrs = 0,
		variadism = variadism,
		params = params,
	};
};

fn integer_type(
	lexer: *lex::lexer,
) (builtin_type | error) = switch (want_tok(lexer)?.0) {
	ltok::CHAR => builtin_type::CHAR,
	ltok::I16 => builtin_type::I16,
	ltok::I32 => builtin_type::I32,
	ltok::I64 => builtin_type::I64,
	ltok::I64 => builtin_type::I64,
	ltok::I8 => builtin_type::I8,
	ltok::INT => builtin_type::INT,
	ltok::SIZE => builtin_type::SIZE,
	ltok::U16 => builtin_type::U16,
	ltok::U32 => builtin_type::U32,
	ltok::U64 => builtin_type::U64,
	ltok::U64 => builtin_type::U64,
	ltok::U8 => builtin_type::U8,
	ltok::UINT => builtin_type::UINT,
	ltok::UINTPTR => builtin_type::UINTPTR,
	* => syntaxerr(mkloc(lexer), "Expected integer type"),
};

fn primitive_type(lexer: *lex::lexer) (ast::_type | error) = {
	let tok = want_tok(lexer)?;
	let builtin = switch (tok.0) {
		ltok::CHAR, ltok::I16, ltok::I32, ltok::I64,
		ltok::I64, ltok::I8, ltok::INT, ltok::SIZE, ltok::U16,
		ltok::U32, ltok::U64, ltok::U64, ltok::U8, ltok::UINT,
		ltok::UINTPTR => {
			lex::unlex(lexer, tok);
			integer_type(lexer)?;
		},
		ltok::RUNE => builtin_type::RUNE,
		ltok::STR => builtin_type::STR,
		ltok::F32 => builtin_type::F32,
		ltok::F64 => builtin_type::F64,
		ltok::BOOL => builtin_type::BOOL,
		ltok::VOID => builtin_type::VOID,
		ltok::NULL => builtin_type::NULL,
		* => return syntaxerr(mkloc(lexer),
			"Unexected {}, was expecting primitive type",
			lex::tokstr(tok)),
	};
	return ast::_type {
		loc = mkloc(lexer),
		flags = 0,
		_type = builtin,
	};
};

fn alias_type(lexer: *lex::lexer) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let unwrap = match (try_tok(lexer, ltok::ELLIPSIS)?) {
		void => false,
		* => true,
	};
	return ast::_type {
		loc = loc,
		flags = 0,
		_type = ast::alias_type {
			unwrap = unwrap,
			ident = ident(lexer)?,
		},
	};
};

fn pointer_type(lexer: *lex::lexer) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let flags = match (try_tok(lexer, ltok::NULLABLE)?) {
		void => 0: ast::pointer_flags,
		* => ast::pointer_flags::NULLABLE,
	};
	want_tok(lexer, ltok::TIMES)?;
	return ast::_type {
		loc = loc,
		flags = 0,
		_type = ast::pointer_type {
			referent = alloc(_type(lexer)?),
			flags = flags,
		},
	};
};

fn tagged_type(lexer: *lex::lexer, first: ast::_type) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let tagged: ast::tagged_type = [];
	append(tagged, alloc(first));
	for (try_tok(lexer, ltok::RPAREN)? is void) {
		append(tagged, alloc(_type(lexer)?));
		match (try_tok(lexer, ltok::BOR)?) {
			void => {
				want_tok(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};
	return ast::_type {
		loc = loc,
		flags = 0,
		_type = tagged,
	};
};

fn tuple_type(lexer: *lex::lexer, first: ast::_type) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let tuple: ast::tuple_type = [];
	append(tuple, alloc(first));
	for (try_tok(lexer, ltok::RPAREN)? is void) {
		append(tuple, alloc(_type(lexer)?));
		match (try_tok(lexer, ltok::COMMA)?) {
			void => {
				want_tok(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};
	return ast::_type {
		loc = loc,
		flags = 0,
		_type = tuple,
	};
};

fn fn_type(lexer: *lex::lexer) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let attrs = match (try_tok(lexer, ltok::ATTR_NORETURN)?) {
		void => 0: ast::func_attrs,
		* => ast::func_attrs::NORETURN,
	};
	want_tok(lexer, ltok::FN)?;
	let proto = prototype(lexer)?;
	proto.attrs |= attrs;
	return ast::_type {
		loc = loc,
		flags = ast::type_flags::CONST,
		_type = proto,
	};
};

// Parses a type
export fn _type(lexer: *lex::lexer) (ast::_type | error) = {
	let flags: ast::type_flags = match (try_tok(lexer, ltok::CONST)?) {
		void => 0,
		* => ast::type_flags::CONST,
	};
	let tok = peek_tok(lexer)? as lex::token;
	let typ: ast::_type = switch (tok.0) {
		ltok::CHAR, ltok::I16, ltok::I32, ltok::I64,
		ltok::I64, ltok::I8, ltok::INT, ltok::SIZE,
		ltok::U16, ltok::U32, ltok::U64, ltok::U64,
		ltok::U8, ltok::UINT, ltok::UINTPTR, ltok::RUNE,
		ltok::STR, ltok::F32, ltok::F64, ltok::BOOL,
		ltok::VOID, ltok::NULL => primitive_type(lexer)?,
		ltok::ENUM => abort(), // TODO
		ltok::NULLABLE, ltok::TIMES => pointer_type(lexer)?,
		ltok::STRUCT, ltok::UNION => abort(), // TODO
		ltok::LBRACKET => abort(), // TODO
		ltok::LPAREN => {
			want_tok(lexer, ltok::LPAREN)?;
			let t = _type(lexer)?;
			switch (want_tok(lexer, ltok::BOR,
					ltok::COMMA)?.0) {
				ltok::BOR => tagged_type(lexer, t)?,
				ltok::COMMA => tuple_type(lexer, t)?,
				* => abort("unreachable"),
			};
		},
		ltok::ATTR_NORETURN, ltok::FN => fn_type(lexer)?,
		ltok::ELLIPSIS, ltok::NAME => alias_type(lexer)?,
		* => return syntaxerr(mkloc(lexer),
			"Unexpected {}, was expecting type",
			lex::tokstr(tok)),
	};

	match (try_tok(lexer, ltok::LNOT)?) {
		void => void,
		* => flags |= ast::type_flags::ERROR,
	};

	typ.flags |= flags;
	return typ;
};
