// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use hare::lex;

// A type alias.
export type alias_type = struct {
	unwrap: bool,
	ident: ident,
};

// A built-in primitive type (int, bool, str, etc).
export type builtin_type = enum {
	BOOL, CHAR, F32, F64, FCONST, I16, I32, I64, I8, ICONST, INT, NULL,
	RUNE, SIZE, STR, U16, U32, U64, U8, UINT, UINTPTR, VOID,
};

// An enumeration field (and optional value).
export type enum_field = struct {
	name: str,
	value: nullable *expr,
	loc: lex::location,
	docs: str,
};

// enum { FOO = 0, BAR, ... }
export type enum_type = struct {
	storage: builtin_type, // Must be an integer type
	values: []enum_field,
};

// The variadism strategy for a function type.
export type variadism = enum {
	NONE,
	C,
	HARE,
};

// The attributes associated with a function type.
export type func_attrs = enum uint {
	NONE = 0,
	NORETURN = 1 << 0,
};

// A parameter to a function type.
export type func_param = struct {
	loc: lex::location,
	name: str,
	_type: *_type,
};

// fn(foo: int, baz: int...) int
export type func_type = struct {
	result: *_type,
	attrs: func_attrs,
	variadism: variadism,
	params: []func_param,
};

// The length for a list type which is a slice (e.g. []int).
export type len_slice = void;

// The length for a list type which is unbounded (e.g. [*]int).
export type len_unbounded = void;

// The length for a list type which is inferred from context (e.g. [_]int).
export type len_contextual = void;

// []int, [*]int, [_]int, [foo]int
export type list_type = struct {
	length: (*expr | len_slice | len_unbounded | len_contextual),
	members: *_type,
};

// Flags which apply to a pointer type.
export type pointer_flags = enum uint {
	NONE = 0,
	NULLABLE = 1 << 0,
};

// *int
export type pointer_type = struct {
	referent: *_type,
	flags: pointer_flags,
};

// A single field of a struct type.
export type struct_field = struct {
	name: str,
	_type: *_type,
};

// An embedded struct type.
export type struct_embedded = *_type;

// An embedded type alias.
export type struct_alias = ident;

// struct { @offset(10) foo: int, struct { bar: int }, baz::quux }
export type struct_member = struct {
	_offset: nullable *expr,
	member: (struct_field | struct_embedded | struct_alias),

	// Only valid if the lexer has comments enabled
	docs: str,
};

// struct { ... }
export type struct_type = []struct_member;

// union { ... }
export type union_type = []struct_member;

// (int | bool)
export type tagged_type = []*_type;

// (int, bool, ...)
export type tuple_type = []*_type;

// Flags which apply to types.
export type type_flags = enum uint {
	NONE = 0,
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// A Hare type.
export type _type = struct {
	start: lex::location,
	end: lex::location,
	flags: type_flags,
	repr: (alias_type | builtin_type | enum_type | func_type |
		list_type | pointer_type | struct_type | union_type |
		tagged_type | tuple_type),
};

fn struct_type_free(t: (struct_type | union_type)) void = {
	let membs = match (t) {
	case let s: struct_type =>
		yield s: []struct_member;
	case let u: union_type =>
		yield u: []struct_member;
	};
	for (let i = 0z; i < len(membs); i += 1) {
		free(membs[i].docs);
		match (membs[i]._offset) {
		case null => void;
		case let e: *expr =>
			expr_free(e);
		};
		match (membs[i].member) {
		case let f: struct_field =>
			free(f.name);
			type_free(f._type);
		case let e: struct_embedded =>
			type_free(e: *_type);
		case let a: struct_alias =>
			ident_free(a);
		};
	};
	free(membs);
};

// Frees resources associated with a [[_type]].
export fn type_free(t: (_type | nullable *_type)) void = {
	match (t) {
	case let t: nullable *_type =>
		match (t) {
		case null => void;
		case let t: *_type =>
			type_free(*t);
			free(t);
		};
	case let t: _type =>
		match (t.repr) {
		case let a: alias_type =>
			ident_free(a.ident);
		case builtin_type => void;
		case let e: enum_type =>
			for (let i = 0z; i < len(e.values); i += 1) {
				free(e.values[i].name);
				match (e.values[i].value) {
				case null => void;
				case let v: *expr =>
					expr_free(v);
				};
			};
			free(e.values);
		case let f: func_type =>
			type_free(f.result);
			for (let i = 0z; i < len(f.params); i += 1) {
				free(f.params[i].name);
				type_free(f.params[i]._type);
			};
			free(f.params);
		case let l: list_type =>
			match (l.length) {
			case let e: *expr =>
				expr_free(*e);
				free(e);
			case => void;
			};
			type_free(l.members);
		case let p: pointer_type =>
			type_free(p.referent);
		case let s: (struct_type | union_type) =>
			struct_type_free(s);
		case let t: tagged_type =>
			for (let i = 0z; i < len(t); i += 1) {
				type_free(t[i]);
			};
			free(t);
		case let t: tuple_type =>
			for (let i = 0z; i < len(t); i += 1) {
				type_free(t[i]);
			};
			free(t);
		};
	};
};
