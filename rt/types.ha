// This defines a subset of types/reflect.ha so we can declare static typeinfo
// structures for builtins.
type types::typeinfo = struct {
	id: uint,
	sz: size,
	al: size,
	flags: types::flags,
	repr: types::repr,
};

type types::flags = enum uint {
	NONE = 0,
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

type types::repr = (types::alias | types::array | types::builtin
	| types::enum_ | types::func | types::pointer | types::slice_repr
	| types::struct_union | types::tagged | types::tuple);

type types::alias = struct {
	ident: []str,
	secondary: type,
};

type types::array = struct {
	length: size,
	members: type,
};

type types::builtin = enum uint {
	BOOL, CHAR, ENUM, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE,
	STR, U16, U32, U64, U8, UINT, UINTPTR, VOID, TYPE,
};

type types::enum_ = struct {
	storage: types::builtin,
	values: [](str, u64),
};

type types::variadism = enum {
	NONE,
	C,
	HARE,
};

type types::func_flags = enum uint {
	NORETURN = 1 << 0,
};

type types::func = struct {
	result: type,
	variadism: types::variadism,
	flags: types::func_flags,
	params: []type,
};

type types::pointer_flags = enum uint {
	NONE = 0,
	NULLABLE = 1 << 0,
};

type types::pointer = struct {
	referent: type,
	flags: types::pointer_flags,
};

type types::slice_repr = type;

type types::struct_kind = enum {
	STRUCT,
	UNION,
};

type types::struct_union = struct {
	kind: types::struct_kind,
	fields: []types::struct_field,
};

type types::struct_field = struct {
	name: str,
	offs: size,
	type_: type,
};

type types::tagged = []type;

type types::tuple = []types::tuple_value;

type types::tuple_value = struct {
	offs: size,
	type_: type,
};

export const @hidden builtin_char: types::typeinfo = types::typeinfo {
	id = 3950255460,
	sz = 1, al = 1, flags = 0,
	repr = types::builtin::CHAR,
}, @hidden builtin_f32: types::typeinfo = types::typeinfo {
	id = 930681398,
	sz = 4, al = 4, flags = 0,
	repr = types::builtin::F32,
}, @hidden builtin_f64: types::typeinfo = types::typeinfo {
	id = 2037165609,
	sz = 8, al = 8, flags = 0,
	repr = types::builtin::F64,
}, @hidden builtin_i8: types::typeinfo = types::typeinfo {
	id = 461893804,
	sz = 1, al = 1, flags = 0,
	repr = types::builtin::I8,
}, @hidden builtin_i16: types::typeinfo = types::typeinfo {
	id = 3312558843,
	sz = 2, al = 2, flags = 0,
	repr = types::builtin::I16,
}, @hidden builtin_i32: types::typeinfo = types::typeinfo {
	id = 2674862226,
	sz = 4, al = 4, flags = 0,
	repr = types::builtin::I32,
}, @hidden builtin_i64: types::typeinfo = types::typeinfo {
	id = 1099590421,
	sz = 8, al = 8, flags = 0,
	repr = types::builtin::I64,
}, @hidden builtin_rune: types::typeinfo = types::typeinfo {
	id = 2206074632,
	sz = 4, al = 4, flags = 0,
	repr = types::builtin::RUNE,
}, @hidden builtin_u8: types::typeinfo = types::typeinfo {
	id = 3181589295,
	sz = 1, al = 1, flags = 0,
	repr = types::builtin::U8,
}, @hidden builtin_u16: types::typeinfo = types::typeinfo {
	id = 3481467866,
	sz = 2, al = 2, flags = 0,
	repr = types::builtin::U16,
}, @hidden builtin_u32: types::typeinfo = types::typeinfo {
	id = 1906196061,
	sz = 4, al = 4, flags = 0,
	repr = types::builtin::U32,
}, @hidden builtin_u64: types::typeinfo = types::typeinfo {
	id = 1268499444,
	sz = 8, al = 8, flags = 0,
	repr = types::builtin::U64,
}, @hidden builtin_void: types::typeinfo = types::typeinfo {
	id = 3012680272,
	sz = 0, al = 0, flags = 0,
	repr = types::builtin::VOID,
};
