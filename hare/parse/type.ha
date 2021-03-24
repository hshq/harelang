use hare::ast;
use hare::ast::{builtin_type};
use hare::lex;
use hare::lex::{btoken};

fn prototype(lexer: *lex::lexer) (ast::func_type | error) = {
	let variadism = ast::variadism::NONE;
	let params: []ast::func_param = [];
	want_btoken(lexer, btoken::LPAREN)?;
	for (try_btoken(lexer, btoken::RPAREN)? is void) {
		let loc = mkloc(lexer);
		match (try_btoken(lexer, btoken::ELLIPSIS)?) {
			void => void,
			lex::btoken => {
				synassert(loc, len(params) > 0,
					"Expected at least one non-variadic parameter for C-style variadism")?;
				variadism = ast::variadism::C;
				try_btoken(lexer, btoken::COMMA)?;
				want_btoken(lexer, btoken::RPAREN)?;
				break;
			},
		};
		let name = match (try_btoken(lexer, btoken::UNDERSCORE)?) {
			void => want_name(lexer)?: str,
			lex::btoken => "",
		};
		want_btoken(lexer, btoken::COLON);
		append(params, ast::func_param {
			loc = loc,
			name = name,
			_type = alloc(_type(lexer)?),
		});
		match (try_btoken(lexer, btoken::ELLIPSIS)?) {
			void => void,
			lex::btoken => {
				variadism = ast::variadism::HARE;
				try_btoken(lexer, btoken::COMMA)?;
				want_btoken(lexer, btoken::RPAREN)?;
				break;
			},
		};
		match (try_btoken(lexer, btoken::COMMA)?) {
			void => {
				want_btoken(lexer, btoken::RPAREN)?;
				break;
			},
			lex::btoken => void,
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
) (builtin_type | error) = switch (want_btoken(lexer)?) {
	btoken::CHAR => builtin_type::CHAR,
	btoken::I16 => builtin_type::I16,
	btoken::I32 => builtin_type::I32,
	btoken::I64 => builtin_type::I64,
	btoken::I64 => builtin_type::I64,
	btoken::I8 => builtin_type::I8,
	btoken::INT => builtin_type::INT,
	btoken::SIZE => builtin_type::SIZE,
	btoken::U16 => builtin_type::U16,
	btoken::U32 => builtin_type::U32,
	btoken::U64 => builtin_type::U64,
	btoken::U64 => builtin_type::U64,
	btoken::U8 => builtin_type::U8,
	btoken::UINT => builtin_type::UINT,
	btoken::UINTPTR => builtin_type::UINTPTR,
	* => syntaxerr(mkloc(lexer), "Expected integer type"),
};

fn primitive_type(lexer: *lex::lexer) (ast::_type | error) = {
	let t = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected primitive type, got EOF"),
		t: (lex::token, lex::location) => t,
	};
	let b = match (t.0) {
		b: lex::btoken => b,
		* => return syntaxerr(mkloc(lexer),
			"Unexpected {}, was expecting primitive type",
			lex::tokstr(t.0)),
	};
	let builtin = switch (b) {
		btoken::CHAR, btoken::I16, btoken::I32, btoken::I64,
		btoken::I64, btoken::I8, btoken::INT, btoken::SIZE, btoken::U16,
		btoken::U32, btoken::U64, btoken::U64, btoken::U8, btoken::UINT,
		btoken::UINTPTR => {
			lex::unlex(lexer, t);
			integer_type(lexer)?;
		},
		btoken::RUNE => builtin_type::RUNE,
		btoken::STR => builtin_type::STR,
		btoken::F32 => builtin_type::F32,
		btoken::F64 => builtin_type::F64,
		btoken::BOOL => builtin_type::BOOL,
		btoken::VOID => builtin_type::VOID,
		btoken::NULL => builtin_type::NULL,
		* => return syntaxerr(mkloc(lexer), "Expected primitive type"),
	};
	return ast::_type {
		loc = mkloc(lexer),
		flags = 0,
		_type = builtin,
	};
};

fn alias_type(lexer: *lex::lexer) (ast::_type | error) = {
	let loc = mkloc(lexer);
	let unwrap = match (try_btoken(lexer, btoken::ELLIPSIS)?) {
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
	let flags = match (try_btoken(lexer, btoken::NULLABLE)?) {
		void => 0: ast::pointer_flags,
		* => ast::pointer_flags::NULLABLE,
	};
	want_btoken(lexer, btoken::TIMES)?;
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
	for (try_btoken(lexer, btoken::RPAREN)? is void) {
		append(tagged, alloc(_type(lexer)?));
		match (try_btoken(lexer, btoken::BOR)?) {
			void => {
				want_btoken(lexer, btoken::RPAREN)?;
				break;
			},
			lex::btoken => void,
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
	for (try_btoken(lexer, btoken::RPAREN)? is void) {
		append(tuple, alloc(_type(lexer)?));
		match (try_btoken(lexer, btoken::COMMA)?) {
			void => {
				want_btoken(lexer, btoken::RPAREN)?;
				break;
			},
			lex::btoken => void,
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
	let attrs = match (try_btoken(lexer, btoken::ATTR_NORETURN)?) {
		void => 0: ast::func_attrs,
		* => ast::func_attrs::NORETURN,
	};
	want_btoken(lexer, btoken::FN)?;
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
	let flags: ast::type_flags = match (try_btoken(lexer, btoken::CONST)?) {
		void => 0,
		* => ast::type_flags::CONST,
	};
	let t = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Unexpected EOF, was expecting type"),
		t: (lex::token, lex::location) => t,
	};
	lex::unlex(lexer, t);
	let typ: ast::_type = match (t.0) {
		b: lex::btoken => switch (b) {
			btoken::CHAR, btoken::I16, btoken::I32, btoken::I64,
			btoken::I64, btoken::I8, btoken::INT, btoken::SIZE,
			btoken::U16, btoken::U32, btoken::U64, btoken::U64,
			btoken::U8, btoken::UINT, btoken::UINTPTR, btoken::RUNE,
			btoken::STR, btoken::F32, btoken::F64, btoken::BOOL,
			btoken::VOID, btoken::NULL => primitive_type(lexer)?,
			btoken::ENUM => abort(), // TODO
			btoken::NULLABLE, btoken::TIMES => pointer_type(lexer)?,
			btoken::STRUCT, btoken::UNION => abort(), // TODO
			btoken::LBRACKET => abort(), // TODO
			btoken::LPAREN => {
				want_btoken(lexer, btoken::LPAREN)?;
				let t = _type(lexer)?;
				switch (want_btoken(lexer, btoken::BOR,
						btoken::COMMA)?) {
					btoken::BOR => tagged_type(lexer, t)?,
					btoken::COMMA => tuple_type(lexer, t)?,
					* => abort("unreachable"),
				};
			},
			btoken::ATTR_NORETURN, btoken::FN => fn_type(lexer)?,
			btoken::ELLIPSIS => alias_type(lexer)?,
			* => return syntaxerr(mkloc(lexer), "Expected type"),
		},
		lex::name => alias_type(lexer)?,
		* => return syntaxerr(mkloc(lexer),
			"Unexpected {}, was expecting type",
			lex::tokstr(t.0)),
	};

	match (try_btoken(lexer, btoken::LNOT)?) {
		void => void,
		* => flags |= ast::type_flags::ERROR,
	};

	typ.flags |= flags;
	return typ;
};
