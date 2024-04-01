// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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
		case lex::token =>
			variadism = ast::variadism::C;
			want(lexer, ltok::RPAREN)?;
			break;
		case void => void;
		};

		let name_or_type = _type(lexer)?;
		match (try(lexer, ltok::COLON)?) {
		case void =>
			append(params, ast::func_param {
				loc = loc,
				name = "",
				_type = alloc(name_or_type),
				default_value = void,
			});
		case lex::token =>
			// Bit of a hack because we can't unlex twice.
			synassert(loc, name_or_type.repr is ast::alias_type,
				"Invalid parameter name")?;
			let ns = (name_or_type.repr as ast::alias_type).ident;
			synassert(loc, len(ns) == 1, "Invalid parameter name")?;
			append(params, ast::func_param {
				loc = loc,
				name = ns[0],
				_type = alloc(_type(lexer)?),
				default_value = void,
			});
		};
		match (try(lexer, ltok::EQUAL)?) {
		case void =>
			yield void;
		case lex::token =>
			params[len(params) - 1].default_value = expr(lexer)?;
		};
		match (try(lexer, ltok::ELLIPSIS)?) {
		case lex::token =>
			variadism = ast::variadism::HARE;
			want(lexer, ltok::RPAREN)?;
			break;
		case void => void;
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
		variadism = variadism,
		params = params,
	};
};

fn integer_type(
	lexer: *lex::lexer,
) (builtin_type | error) = {
	switch (want(lexer)?.0) {
	case ltok::INT =>
		return builtin_type::INT;
	case ltok::I8 =>
		return builtin_type::I8;
	case ltok::I16 =>
		return builtin_type::I16;
	case ltok::I32 =>
		return builtin_type::I32;
	case ltok::I64 =>
		return builtin_type::I64;
	case ltok::SIZE =>
		return builtin_type::SIZE;
	case ltok::UINT =>
		return builtin_type::UINT;
	case ltok::UINTPTR =>
		return builtin_type::UINTPTR;
	case ltok::U8 =>
		return builtin_type::U8;
	case ltok::U16 =>
		return builtin_type::U16;
	case ltok::U32 =>
		return builtin_type::U32;
	case ltok::U64 =>
		return builtin_type::U64;
	case =>
		return syntaxerr(lex::mkloc(lexer), "Expected integer type");
	};
};

fn primitive_type(lexer: *lex::lexer) (ast::_type | error) = {
	let tok = want(lexer)?;
	let builtin = switch (tok.0) {
	case ltok::I8, ltok::I16, ltok::I32, ltok::I64,
			ltok::INT, ltok::UINT, ltok::UINTPTR, ltok::SIZE,
			ltok::U8, ltok::U16, ltok::U32, ltok::U64 =>
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
	case ltok::DONE =>
		yield builtin_type::DONE;
	case ltok::VALIST =>
		yield builtin_type::VALIST;
	case ltok::VOID =>
		yield builtin_type::VOID;
	case ltok::OPAQUE =>
		yield builtin_type::OPAQUE;
	case ltok::NEVER =>
		yield builtin_type::NEVER;
	case =>
		return syntaxerr(lex::mkloc(lexer),
			"Unexected {}, was expecting primitive type",
			lex::tokstr(tok));
	};
	return ast::_type {
		start = tok.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flag::NONE,
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
		yield ast::pointer_flag::NONE;
	case =>
		yield ast::pointer_flag::NULLABLE;
	};
	want(lexer, ltok::TIMES)?;
	let _type = _type(lexer)?;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flag::NONE,
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
	for (true) {
		append(tagged, alloc(_type(lexer)?));

		match (try(lexer, ltok::BOR)?) {
		case lex::token =>
			match (try(lexer, ltok::RPAREN)) {
			case lex::token => break;
			case => void;
			};
		case void =>
			want(lexer, ltok::RPAREN)?;
			break;
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flag::NONE,
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
	for (true) {
		append(tuple, alloc(_type(lexer)?));
		match (try(lexer, ltok::COMMA)?) {
		case lex::token =>
			match (try(lexer, ltok::RPAREN)) {
			case lex::token => break;
			case => void;
			};
		case void =>
			want(lexer, ltok::RPAREN)?;
			break;
		};
	};
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = ast::type_flag::NONE,
		repr = tuple,
	};
};

fn fn_type(lexer: *lex::lexer) (ast::_type | error) = {
	const start = lex::mkloc(lexer);
	want(lexer, ltok::FN)?;
	let proto = prototype(lexer)?;
	return ast::_type {
		start = start,
		end = lex::prevloc(lexer),
		flags = 0,
		repr = proto,
	};
};

fn struct_union_type(lexer: *lex::lexer) (ast::_type | error) = {
	let membs: []ast::struct_member = [];
	let kind = want(lexer, ltok::STRUCT, ltok::UNION)?;
	let packed = false;

	if (kind.0 == ltok::STRUCT && try(lexer, ltok::ATTR_PACKED)? is lex::token) {
		packed = true;
	};

	want(lexer, ltok::LBRACE)?;

	for (true) {
		if (try(lexer, ltok::RBRACE)? is lex::token) {
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
		case ltok::COMMA =>
			const linecomment = lex::comment(lexer);
			const docs = &membs[len(membs) - 1].docs;
			if (linecomment != "" && *docs == "") {
				*docs = strings::dup(linecomment);
				free(lexer.comment);
				lexer.comment = "";
			};
		case => abort();
		};
	};

	return ast::_type {
		start = kind.2,
		end = lex::prevloc(lexer),
		flags = ast::type_flag::NONE,
		repr = switch (kind.0) {
		case ltok::STRUCT =>
			yield ast::struct_type { members = membs, packed = packed, ...};
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
		flags = ast::type_flag::NONE,
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
		case => abort(); // unreachable
		};
	};

	let membs: []ast::enum_field = [];
	for (true) {
		if (try(lexer, ltok::RBRACE)? is lex::token) {
			synassert(lex::mkloc(lexer), len(membs) != 0,
				"Expected member list")?;
			break;
		};

		const loc = lex::mkloc(lexer);
		let name = want(lexer, ltok::NAME)?;
		let comment = strings::dup(lex::comment(lexer));
		let value: nullable *ast::expr =
			if (try(lexer, ltok::EQUAL)? is lex::token)
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
			if (linecomment != "" && comment == "") {
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
		flags = ast::type_flag::NONE,
		repr = ast::enum_type {
			storage = storage,
			values = membs,
		},
	};
};

// Parses a type, e.g. '[]int'.
export fn _type(lexer: *lex::lexer) (ast::_type | error) = {
	let flags = ast::type_flag::NONE;
	if (try(lexer, ltok::CONST)? is lex::token) {
		flags |= ast::type_flag::CONST;
	};

	if (try(lexer, ltok::LNOT)? is lex::token) {
		flags |= ast::type_flag::ERROR;
	};

	let tok = peek(lexer)? as lex::token;
	let typ: ast::_type = switch (tok.0) {
	case ltok::RUNE, ltok::STR, ltok::BOOL, ltok::DONE, ltok::I8, ltok::I16,
			ltok::I32, ltok::I64, ltok::U8, ltok::U16, ltok::U32,
			ltok::U64, ltok::INT, ltok::UINT, ltok::UINTPTR,
			ltok::SIZE, ltok::F32, ltok::F64, ltok::VALIST,
			ltok::VOID, ltok::OPAQUE, ltok::NEVER =>
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
	case ltok::FN =>
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
