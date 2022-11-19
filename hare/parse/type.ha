// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use hare::ast;
use hare::ast::{builtin_type};
use hare::lex;
use hare::lex::{ltok};
use strings;

fn prototype(lexer: *lex::lexer) (ast::func_type | error) = {
	let variadism = ast::variadism::NONE;
	let params: []ast::func_param = [];
	want(lexer, ltok::LPAREN)?;
	for (try(lexer, ltok::RPAREN)? is void) {
		let loc = lex::mkloc(lexer);
		match (try(lexer, ltok::ELLIPSIS)?) {
		case void =>
			yield void;
		case lex::token =>
			synassert(loc, len(params) > 0,
				"Expected at least one non-variadic parameter for C-style variadism")?;
			variadism = ast::variadism::C;
			try(lexer, ltok::COMMA)?;
			want(lexer, ltok::RPAREN)?;
			break;
		};

		let name = match (try(lexer, ltok::UNDERSCORE)?) {
		case void =>
			yield want(lexer, ltok::NAME)?.1 as str;
		case lex::token =>
			yield "";
		};

		want(lexer, ltok::COLON)?;
		append(params, ast::func_param {
			loc = loc,
			name = name,
			_type = alloc(_type(lexer)?),
		});
		match (try(lexer, ltok::ELLIPSIS)?) {
		case void =>
			yield void;
		case lex::token =>
			variadism = ast::variadism::HARE;
			try(lexer, ltok::COMMA)?;
			want(lexer, ltok::RPAREN)?;
			break;
		};
		match (try(lexer, ltok::COMMA)?) {
		case void =>
			want(lexer, ltok::RPAREN)?;
			break;
		case lex::token => void;
		};
	};
	let t = _type(lexer)?;
	return ast::func_type {
		result = alloc(t),
		attrs = ast::func_attrs::NONE,
		variadism = variadism,
		params = params,
	};
};

fn integer_type(
	lexer: *lex::lexer,
) (builtin_type | error) = {
	switch (want(lexer)?.0) {
	case ltok::CHAR =>
		return builtin_type::CHAR;
	case ltok::I16 =>
		return builtin_type::I16;
	case ltok::I32 =>
		return builtin_type::I32;
	case ltok::I64 =>
		return builtin_type::I64;
	case ltok::I64 =>
		return builtin_type::I64;
	case ltok::I8 =>
		return builtin_type::I8;
	case ltok::INT =>
		return builtin_type::INT;
	case ltok::SIZE =>
		return builtin_type::SIZE;
	case ltok::U16 =>
		return builtin_type::U16;
	case ltok::U32 =>
		return builtin_type::U32;
	case ltok::U64 =>
		return builtin_type::U64;
	case ltok::U64 =>
		return builtin_type::U64;
	case ltok::U8 =>
		return builtin_type::U8;
	case ltok::UINT =>
		return builtin_type::UINT;
	case ltok::UINTPTR =>
		return builtin_type::UINTPTR;
	case =>
		return syntaxerr(lex::mkloc(lexer), "Expected integer type");
	};
};

fn primitive_type(lexer: *lex::lexer) (ast::_type | error) = {
	let tok = want(lexer)?;
	let builtin = switch (tok.0) {
	case ltok::CHAR, ltok::I16, ltok::I32, ltok::I64, ltok::I64, ltok::I8,
			ltok::INT, ltok::SIZE, ltok::U16, ltok::U32, ltok::U64,
			ltok::U64, ltok::U8, ltok::UINT, ltok::UINTPTR =>
		lex::unlex(lexer, tok);
		yield integer_type(lexer)?;
	case ltok::RUNE =>
		yield builtin_type::RUNE;
	case ltok::STR =>
		yield builtin_type::STR;
	case ltok::F32 =>
		yield builtin_type::F32;
	case ltok::F64 =>
		yield builtin_type::F64;
	case ltok::BOOL =>
		yield builtin_type::BOOL;
	case ltok::VALIST =>
		yield builtin_type::VALIST;
	case ltok::VOID =>
		yield builtin_type::VOID;
	case =>
		return syntaxerr(lex::mkloc(lexer),
			"Unexected {}, was expecting primitive type",
			lex::tokstr(tok));
	};
	return ast::_type {
		start = tok.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
		repr = builtin,
	};
};

fn alias_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	let unwrap = try(lexer, ltok::ELLIPSIS)? is lex::token;
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
	case void =>
		yield ast::pointer_flags::NONE;
	case =>
		yield ast::pointer_flags::NULLABLE;
	};
	want(lexer, ltok::TIMES)?;
	let _type = _type(lexer)?;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
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
		if (try(lexer, ltok::BOR)? is void) {
			want(lexer, ltok::RPAREN)?;
			break;
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
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
		if (try(lexer, ltok::COMMA)? is void) {
			want(lexer, ltok::RPAREN)?;
			break;
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
		repr = tuple,
	};
};

fn fn_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	let attrs = match (try(lexer, ltok::ATTR_NORETURN)?) {
	case void =>
		yield ast::func_attrs::NONE;
	case =>
		yield ast::func_attrs::NORETURN;
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

		let comment = "";

		let offs: nullable *ast::expr = match (try(lexer, ltok::ATTR_OFFSET)?) {
		case void =>
			yield null;
		case lex::token =>
			comment = strings::dup(lex::comment(lexer));
			want(lexer, ltok::LPAREN)?;
			let ex = expr(lexer)?;
			want(lexer, ltok::RPAREN)?;
			yield alloc(ex);
		};

		let tok = want(lexer, ltok::NAME, ltok::STRUCT, ltok::UNION)?;
		if (comment == "") {
			comment = strings::dup(lex::comment(lexer));
		};
		switch (tok.0) {
		case ltok::NAME =>
			lex::unlex(lexer, tok);
			let memb = struct_embed_or_field(lexer, offs, comment)?;
			append(membs, memb);
		case ltok::STRUCT, ltok::UNION =>
			lex::unlex(lexer, tok);
			let subtype = struct_union_type(lexer)?;
			append(membs, ast::struct_member {
				_offset = offs,
				member = alloc(subtype),
				docs = comment,
			});
		case => abort();
		};

		switch (want(lexer, ltok::RBRACE, ltok::COMMA)?.0) {
		case ltok::RBRACE => break;
		case ltok::COMMA => void;
		case => abort();
		};
	};

	return ast::_type {
		start = kind.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
		repr = switch (kind.0) {
		case ltok::STRUCT =>
			yield membs: ast::struct_type;
		case ltok::UNION =>
			yield membs: ast::union_type;
		case => abort();
		},
	};
};

fn struct_embed_or_field(
	lexer: *lex::lexer,
	offs: nullable *ast::expr,
	comment: str,
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
	case void =>
		yield alloc([name.1 as str]);
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::COLON =>
			let field = ast::struct_field {
				name = name.1 as str,
				_type = alloc(_type(lexer)?),
			};
			return ast::struct_member {
				_offset = offs,
				member = field,
				docs = comment,
			};
		case ltok::DOUBLE_COLON =>
			let id = ident(lexer)?;
			insert(id[0], name.1 as str);
			yield id;
		case => abort();
		};
	};

	return ast::struct_member {
		_offset = offs,
		member = id: ast::struct_alias,
		docs = comment,
	};
};

fn array_slice_type(lexer: *lex::lexer) (ast::_type | error) = {
	let start = want(lexer, ltok::LBRACKET)?;

	let length = match (try(lexer, ltok::UNDERSCORE,
		ltok::TIMES, ltok::RBRACKET)?) {
	case void =>
		yield alloc(expr(lexer)?);
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::UNDERSCORE =>
			yield ast::len_contextual;
		case ltok::TIMES =>
			yield ast::len_unbounded;
		case ltok::RBRACKET =>
			yield ast::len_slice;
		case => abort();
		};
	};

	if (!(length is ast::len_slice)) {
		want(lexer, ltok::RBRACKET)?;
	};

	let _type = _type(lexer)?;
	return ast::_type {
		start = start.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
		repr = ast::list_type {
			length = length,
			members = alloc(_type),
		},
	};
};

fn enum_type(lexer: *lex::lexer) (ast::_type | error) = {
	let start = want(lexer, ltok::ENUM)?;

	const storage = match (try(lexer, ltok::LBRACE, ltok::RUNE)?) {
	case void =>
		let storage = integer_type(lexer)?;
		want(lexer, ltok::LBRACE)?;
		yield storage;
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::LBRACE =>
			yield builtin_type::INT;
		case ltok::RUNE =>
			want(lexer, ltok::LBRACE)?;
			yield builtin_type::RUNE;
		};
	};

	let membs: []ast::enum_field = [];
	for (true) {
		if (try(lexer, ltok::RBRACE) is lex::token) {
			synassert(lex::mkloc(lexer), len(membs) != 0,
				"Expected member list")?;
			break;
		};

		const loc = lex::mkloc(lexer);
		let name = want(lexer, ltok::NAME)?;
		let comment = strings::dup(lex::comment(lexer));
		let value: nullable *ast::expr =
			if (try(lexer, ltok::EQUAL) is lex::token)
				alloc(expr(lexer)?)
			else null;

		defer append(membs, ast::enum_field {
			name = name.1 as str,
			value = value,
			loc = loc,
			docs = comment,
		});

		switch (want(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
		case ltok::COMMA =>
			const linecomment = lex::comment(lexer);
			if (linecomment != "") {
				free(comment);
				comment = strings::dup(linecomment);
				free(lexer.comment);
				lexer.comment = "";
			};
		case ltok::RBRACE => break;
		case => abort();
		};
	};

	return ast::_type {
		start = start.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flags::NONE,
		repr = ast::enum_type {
			storage = storage,
			values = membs,
		},
	};
};

// Parses a type, e.g. '[]int'.
export fn _type(lexer: *lex::lexer) (ast::_type | error) = {
	let flags = ast::type_flags::NONE;
	if (try(lexer, ltok::CONST)? is lex::token) {
		flags |= ast::type_flags::CONST;
	};

	if (try(lexer, ltok::LNOT)? is lex::token) {
		flags |= ast::type_flags::ERROR;
	};

	let tok = peek(lexer)? as lex::token;
	let typ: ast::_type = switch (tok.0) {
	case ltok::CHAR, ltok::I16, ltok::I32, ltok::I64, ltok::I64, ltok::I8,
			ltok::INT, ltok::SIZE, ltok::U16, ltok::U32, ltok::U64,
			ltok::U8, ltok::UINT, ltok::UINTPTR, ltok::RUNE,
			ltok::STR, ltok::F32, ltok::F64, ltok::BOOL,
			ltok::VALIST, ltok::VOID, ltok::TYPE =>
		yield primitive_type(lexer)?;
	case ltok::ENUM =>
		yield enum_type(lexer)?;
	case ltok::NULLABLE, ltok::TIMES =>
		yield pointer_type(lexer)?;
	case ltok::STRUCT, ltok::UNION =>
		yield struct_union_type(lexer)?;
	case ltok::LBRACKET =>
		yield array_slice_type(lexer)?;
	case ltok::LPAREN =>
		want(lexer, ltok::LPAREN)?;
		let t = _type(lexer)?;
		yield switch (want(lexer, ltok::BOR, ltok::COMMA)?.0) {
		case ltok::BOR =>
			yield tagged_type(lexer, t, tok.2)?;
		case ltok::COMMA =>
			yield tuple_type(lexer, t, tok.2)?;
		case => abort("unreachable");
		};
	case ltok::ATTR_NORETURN, ltok::FN =>
		yield fn_type(lexer)?;
	case ltok::ELLIPSIS, ltok::NAME =>
		yield alias_type(lexer)?;
	case =>
		return syntaxerr(lex::mkloc(lexer),
			"Unexpected {}, was expecting type",
			lex::tokstr(tok));
	};

	typ.flags |= flags;
	return typ;
};
