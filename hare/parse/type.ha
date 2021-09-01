use hare::ast;
use hare::ast::{builtin_type};
use hare::lex;
use hare::lex::{ltok};

fn prototype(lexer: *lex::lexer) (ast::func_type | error) = {
	let variadism = ast::variadism::NONE;
	let params: []ast::func_param = [];
	want(lexer, ltok::LPAREN)?;
	for (try(lexer, ltok::RPAREN)? is void) {
		let loc = lex::mkloc(lexer);
		match (try(lexer, ltok::ELLIPSIS)?) {
			void => void,
			lex::token => {
				synassert(loc, len(params) > 0,
					"Expected at least one non-variadic parameter for C-style variadism")?;
				variadism = ast::variadism::C;
				try(lexer, ltok::COMMA)?;
				want(lexer, ltok::RPAREN)?;
				break;
			},
		};
		let name = match (try(lexer, ltok::UNDERSCORE)?) {
			void => want(lexer, ltok::NAME)?.1 as str,
			lex::token => "",
		};
		want(lexer, ltok::COLON)?;
		append(params, ast::func_param {
			loc = loc,
			name = name,
			_type = alloc(_type(lexer)?),
		});
		match (try(lexer, ltok::ELLIPSIS)?) {
			void => void,
			lex::token => {
				variadism = ast::variadism::HARE;
				try(lexer, ltok::COMMA)?;
				want(lexer, ltok::RPAREN)?;
				break;
			},
		};
		match (try(lexer, ltok::COMMA)?) {
			void => {
				want(lexer, ltok::RPAREN)?;
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
) (builtin_type | error) = switch (want(lexer)?.0) {
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
	* => syntaxerr(lex::mkloc(lexer), "Expected integer type"),
};

fn primitive_type(lexer: *lex::lexer) (ast::_type | error) = {
	let tok = want(lexer)?;
	let builtin = switch (tok.0) {
		ltok::CHAR, ltok::I16, ltok::I32, ltok::I64,
		ltok::I64, ltok::I8, ltok::INT, ltok::SIZE, ltok::U16,
		ltok::U32, ltok::U64, ltok::U64, ltok::U8, ltok::UINT,
		ltok::UINTPTR => {
			lex::unlex(lexer, tok);
			yield integer_type(lexer)?;
		},
		ltok::RUNE => builtin_type::RUNE,
		ltok::STR => builtin_type::STR,
		ltok::F32 => builtin_type::F32,
		ltok::F64 => builtin_type::F64,
		ltok::BOOL => builtin_type::BOOL,
		ltok::VOID => builtin_type::VOID,
		* => return syntaxerr(lex::mkloc(lexer),
			"Unexected {}, was expecting primitive type",
			lex::tokstr(tok)),
	};
	return ast::_type {
		start = tok.2,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = builtin,
	};
};

fn alias_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	let unwrap = match (try(lexer, ltok::ELLIPSIS)?) {
		void => false,
		* => true,
	};
	let ident = ident(lexer)?;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = ast::alias_type {
			unwrap = unwrap,
			ident = ident,
		},
	};
};

fn pointer_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	let flags = match (try(lexer, ltok::NULLABLE)?) {
		void => 0: ast::pointer_flags,
		* => ast::pointer_flags::NULLABLE,
	};
	want(lexer, ltok::TIMES)?;
	let _type = _type(lexer)?;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = ast::pointer_type {
			referent = alloc(_type),
			flags = flags,
		},
	};
};

fn tagged_type(
	lexer: *lex::lexer,
	first: ast::_type,
	start: lex::location
) (ast::_type | error) = {
	let tagged: ast::tagged_type = [];
	append(tagged, alloc(first));
	for (try(lexer, ltok::RPAREN)? is void) {
		append(tagged, alloc(_type(lexer)?));
		match (try(lexer, ltok::BOR)?) {
			void => {
				want(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = tagged,
	};
};

fn tuple_type(
	lexer: *lex::lexer,
	first: ast::_type,
	start: lex::location
) (ast::_type | error) = {
	let tuple: ast::tuple_type = [];
	append(tuple, alloc(first));
	for (try(lexer, ltok::RPAREN)? is void) {
		append(tuple, alloc(_type(lexer)?));
		match (try(lexer, ltok::COMMA)?) {
			void => {
				want(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = tuple,
	};
};

fn fn_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	let attrs = match (try(lexer, ltok::ATTR_NORETURN)?) {
		void => 0: ast::func_attrs,
		* => ast::func_attrs::NORETURN,
	};
	want(lexer, ltok::FN)?;
	let proto = prototype(lexer)?;
	proto.attrs |= attrs;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::CONST,
		repr = proto,
	};
};

fn struct_union_type(lexer: *lex::lexer) (ast::_type | error) = {
	let membs: []ast::struct_member = [];
	let kind = want(lexer, ltok::STRUCT, ltok::UNION)?;
	want(lexer, ltok::LBRACE)?;

	for (true) {
		if (try(lexer, ltok::RBRACE) is lex::token) {
			synassert(lex::mkloc(lexer), len(membs) != 0,
				"Expected field list")?;
			break;
		};

		let offs: nullable *ast::expr = match (try(lexer, ltok::ATTR_OFFSET)?) {
			void => null,
			lex::token => {
				want(lexer, ltok::LPAREN)?;
				let ex = expression(lexer)?;
				want(lexer, ltok::RPAREN)?;
				yield alloc(ex);
			},
		};

		let tok = want(lexer, ltok::NAME, ltok::STRUCT, ltok::UNION)?;
		switch (tok.0) {
			ltok::NAME => {
				lex::unlex(lexer, tok);
				let memb = struct_embed_or_field(lexer, offs)?;
				append(membs, memb);
			},
			ltok::STRUCT, ltok::UNION => {
				lex::unlex(lexer, tok);
				let subtype = struct_union_type(lexer)?;
				append(membs, ast::struct_member {
					_offset = offs,
					member = alloc(subtype),
				});
			},
			* => abort(),
		};

		switch (want(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
			ltok::COMMA => void,
			ltok::RBRACE => break,
			* => abort(),
		};
	};

	return ast::_type {
		start = kind.2,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = switch (kind.0) {
			ltok::STRUCT => membs: ast::struct_type,
			ltok::UNION => membs: ast::union_type,
			* => abort(),
		},
	};
};

fn struct_embed_or_field(
	lexer: *lex::lexer,
	offs: nullable *ast::expr,
) (ast::struct_member | error) = {
	// Disambiguates between `name: type` and `identifier`
	//
	// struct-union-field
	// 	name : type
	// 	identifier
	// 
	// identifier
	// 	name
	// 	name :: identifier
	let name = want(lexer, ltok::NAME)?;

	let id: ast::ident = match (try(lexer, ltok::COLON, ltok::DOUBLE_COLON)?) {
		void => alloc([name.1 as str]),
		tok: lex::token => switch (tok.0) {
			ltok::COLON => {
				let field = ast::struct_field {
					name = name.1 as str,
					_type = alloc(_type(lexer)?),
				};
				return ast::struct_member {
					_offset = offs,
					member = field,
				};
			},
			ltok::DOUBLE_COLON => {
				let id = ident(lexer)?;
				insert(id[0], name.1 as str);
				yield id;
			},
			* => abort(),
		},
	};

	return ast::struct_member {
		_offset = offs,
		member = id: ast::struct_alias,
	};
};

fn array_slice_type(lexer: *lex::lexer) (ast::_type | error) = {
	let start = want(lexer, ltok::LBRACKET)?;

	let length = match (try(lexer,
			ltok::UNDERSCORE, ltok::TIMES, ltok::RBRACKET)?) {
		void => alloc(expression(lexer)?),
		tok: lex::token => switch (tok.0) {
			ltok::UNDERSCORE => ast::len_contextual,
			ltok::TIMES => ast::len_unbounded,
			ltok::RBRACKET => ast::len_slice,
			* => abort(),
		},
	};

	match (length) {
		ast::len_slice => void,
		* => want(lexer, ltok::RBRACKET)?,
	};
	let _type = _type(lexer)?;
	return ast::_type {
		start = start.2,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = ast::list_type {
			length = length,
			members = alloc(_type),
		},
	};
};

fn enum_type(lexer: *lex::lexer) (ast::_type | error) = {
	let start = want(lexer, ltok::ENUM)?;

	const storage = match (try(lexer, ltok::LBRACE)?) {
		void => {
			let storage = integer_type(lexer)?;
			want(lexer, ltok::LBRACE)?;
			yield storage;
		},
		lex::token => builtin_type::INT,
	};

	let membs: []ast::enum_field = [];
	for (true) {
		if (try(lexer, ltok::RBRACE) is lex::token) {
			synassert(lex::mkloc(lexer), len(membs) != 0,
				"Expected member list")?;
			break;
		};

		let name = want(lexer, ltok::NAME)?;
		let value: nullable *ast::expr =
			if (try(lexer, ltok::EQUAL) is lex::token)
				alloc(expression(lexer)?)
			else null;

		append(membs, ast::enum_field {
			name = name.1 as str,
			value = value,
		});

		switch (want(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
			ltok::COMMA => void,
			ltok::RBRACE => break,
			* => abort(),
		};
	};

	return ast::_type {
		start = start.2,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = ast::enum_type {
			storage = storage,
			values = membs,
		},
	};
};

// Parses a type, e.g. '[]int'.
export fn _type(lexer: *lex::lexer) (ast::_type | error) = {
	let flags: ast::type_flags = 0;
	match (try(lexer, ltok::CONST)?) {
		void => void,
		* => flags |= ast::type_flags::CONST,
	};
	match (try(lexer, ltok::LNOT)?) {
		void => void,
		* => flags |= ast::type_flags::ERROR,
	};
	let tok = peek(lexer)? as lex::token;
	let typ: ast::_type = switch (tok.0) {
		ltok::CHAR, ltok::I16, ltok::I32, ltok::I64,
		ltok::I64, ltok::I8, ltok::INT, ltok::SIZE,
		ltok::U16, ltok::U32, ltok::U64, ltok::U64,
		ltok::U8, ltok::UINT, ltok::UINTPTR, ltok::RUNE,
		ltok::STR, ltok::F32, ltok::F64, ltok::BOOL,
		ltok::VOID => primitive_type(lexer)?,
		ltok::ENUM => enum_type(lexer)?,
		ltok::NULLABLE, ltok::TIMES => pointer_type(lexer)?,
		ltok::STRUCT, ltok::UNION => struct_union_type(lexer)?,
		ltok::LBRACKET => array_slice_type(lexer)?,
		ltok::LPAREN => {
			want(lexer, ltok::LPAREN)?;
			let t = _type(lexer)?;
			yield switch (want(lexer, ltok::BOR,
					ltok::COMMA)?.0) {
				ltok::BOR => tagged_type(lexer, t, tok.2)?,
				ltok::COMMA => tuple_type(lexer, t, tok.2)?,
				* => abort("unreachable"),
			};
		},
		ltok::ATTR_NORETURN, ltok::FN => fn_type(lexer)?,
		ltok::ELLIPSIS, ltok::NAME => alias_type(lexer)?,
		* => return syntaxerr(lex::mkloc(lexer),
			"Unexpected {}, was expecting type",
			lex::tokstr(tok)),
	};

	typ.flags |= flags;
	return typ;
};
