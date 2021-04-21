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
	NORETURN = 1 << 0,
};

// A parameter to a function type.
export type func_param = struct {
	loc: lex::location,
	name: str,
	_type: *_type,
};

// fn(foo: int, ..., baz: ...int) int
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
};

// struct { ... }
export type struct_type = []struct_member;

// union { ... }
export type union_type = []struct_member;

// (int | bool, ...)
export type tagged_type = []*_type;

// (int, bool, ...)
export type tuple_type = []*_type;

// Flags which apply to types.
export type type_flags = enum uint {
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// A Hare type.
export type _type = struct {
	loc: lex::location,
	flags: type_flags,
	_type: (alias_type | builtin_type | enum_type | func_type |
		list_type | pointer_type | struct_type | union_type |
		tagged_type | tuple_type),
};

fn struct_type_free(t: (struct_type | union_type)) void = {
	let membs = match (t) {
		s: struct_type => s: []struct_member,
		u: union_type => u: []struct_member,
	};
	for (let i = 0z; i < len(membs); i += 1) {
		match (membs[i]._offset) {
			null => void,
			e: *expr => expr_free(e),
		};
		match (membs[i].member) {
			f: struct_field => {
				free(f.name);
				type_free(f._type);
			},
			e: struct_embedded => {
				type_free(e: *_type);
			},
			a: struct_alias => ident_free(a),
		};
	};
	free(membs);
};

// Frees resources associated with a [[_type]].
export fn type_free(t: (_type | nullable *_type)) void = match (t) {
	t: nullable *_type => match (t) {
		null => void,
		t: *_type => {
			type_free(*t);
			free(t);
		},
	},
	t: _type => match (t._type) {
		a: alias_type => ident_free(a.ident),
		_: builtin_type => void,
		e: enum_type => {
			for (let i = 0z; i < len(e.values); i += 1) {
				free(e.values[i].name);
				match (e.values[i].value) {
					null => void,
					v: *expr => expr_free(v),
				};
			};
			free(e.values);
		},
		f: func_type => {
			type_free(f.result);
			for (let i = 0z; i < len(f.params); i += 1) {
				free(f.params[i].name);
				type_free(f.params[i]._type);
			};
			free(f.params);
		},
		l: list_type => {
			match (l.length) {
				e: *expr => {
					expr_free(*e);
					free(e);
				},
				* => void,
			};
			type_free(l.members);
		},
		p: pointer_type => type_free(p.referent),
		s: (struct_type | union_type) => struct_type_free(s),
		t: tagged_type => {
			for (let i = 0z; i < len(t); i += 1) {
				type_free(t[i]);
			};
			free(t);
		},
		t: tuple_type => {
			for (let i = 0z; i < len(t); i += 1) {
				type_free(t[i]);
			};
			free(t);
		},
	},
};
