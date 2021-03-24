use hare::lex;

// foo
export type alias_type = struct {
	unwrap: bool,
	ident: ident,
};

// int, bool, ...
export type builtin_type = enum {
	BOOL, CHAR, F32, F64, FCONST, I16, I32, I64, I8, ICONST, INT, NULL,
	RUNE, SIZE, STR, U16, U32, U64, U8, UINT, UINTPTR, VOID,
};

export type enum_field = struct {
	name: str,
	value: nullable *expr,
};

// enum { FOO = 0, BAR, ... }
export type enum_type = struct {
	storage: builtin_type, // Must be an integer type
	values: []enum_field,
};

export type variadism = enum {
	NONE,
	C,
	HARE,
};

export type func_attrs = enum uint {
	NORETURN = 1 << 0,
};

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

export type len_slice = void;
export type len_unbounded = void;
export type len_contextual = void;

// []int, [*]int, [_]int, [foo]int
export type list_type = struct {
	length: (*expr | len_slice | len_unbounded | len_contextual),
	members: *_type,
};

export type pointer_flags = enum uint {
	NULLABLE = 1 << 0,
};

// *int
export type pointer_type = struct {
	referent: *_type,
	flags: pointer_flags,
};

export type struct_field = struct {
	name: str,
	_type: *_type,
};

export type struct_embedded = *_type;

export type struct_alias = ident;

// struct { @offset(10) foo: int, struct { bar: int }, baz::quux }
export type struct_member = struct {
	is_union: bool,
	_offset: nullable *expr,
	member: (struct_field | struct_embedded | struct_alias),
};

// (int | bool, ...)
export type tagged_type = []*_type;

// (int, bool, ...)
export type tuple_type = []*_type;

export type type_flags = enum uint {
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// A type
export type _type = struct {
	loc: lex::location,
	flags: type_flags,
	_type: (alias_type | builtin_type | enum_type | func_type |
		list_type | pointer_type | []struct_member | tagged_type |
		tuple_type),
};

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
		builtin_type => void,
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
		s: []struct_member => {
			for (let i = 0z; i < len(s); i += 1) {
				match (s[i]._offset) {
					null => void,
					e: *expr => expr_free(e),
				};
				match (s[i].member) {
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
			free(s);
		},
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
