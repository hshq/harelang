use hare::ast;

// A type alias.
export type alias = struct {
	id: ast::ident,
	// null for forward referenced types
	_type: const nullable *_type,
};

// An array type, e.g. [10]int
export type array = struct {
	// [[SIZE_UNDEFINED]] for [*]type
	length: size,
	member: const *_type,
};

// A built-in primitive type (int, bool, str, etc).
export type builtin = enum u8 {
	// Keep me consistent with ast::builtin
	BOOL, CHAR, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE, STR,
	U16, U32, U64, U8, UINT, UINTPTR, VOID,
};

// An enum type, e.g. enum { FOO = 0 }
export type _enum = struct {
	storage: builtin,
	values: [](str, u64),
};

// Indicates the variadism of a [[func]]
export type variadism = enum {
	NONE,
	C,
	HARE,
};

// Indicats if a [[func]] has the @noreturn attribute
export type func_flags = enum uint {
	NORETURN = 1 << 0,
};

// A function type, e.g. fn(x: int, y: int) int
export type func = struct {
	result: const *_type,
	variadism: variadism,
	flags: func_flags,
	params: []const *_type,
};

// Flags which apply to a pointer type.
export type pointer_flags = enum u8 {
	NONE = 0,
	// Keep me consistent with ast::pointer_flags
	NULLABLE = 1 << 0,
};

// *int
export type pointer = struct {
	referent: const *_type,
	flags: pointer_flags,
};

// []int
export type slice = const *_type;

// Indicates if a [[_struct]] was declared as a struct or union type.
export type struct_union = enum {
	STRUCT,
	UNION,
};

// struct { ... } or union { ... }
//
// Note that embedded anonymous structs will have been merged into their parent
// type.
export type _struct = struct {
	kind: struct_union,
	fields: []struct_field,
};

// A single struct field.
export type struct_field = struct {
	// "" for an anonymous field
	name: str,
	offs: size,
	_type: const *_type,
};

// A tagged union type, e.g. (int | uint | void).
export type tagged = []*_type;

// A tuple type, e.g. (a, b, c)
export type tuple = []tuple_value;

// A single value of a tuple type.
export type tuple_value = struct {
	offs: size,
	_type: const *_type,
};

// Flags for a Hare type.
export type flags = enum u8 {
	NONE = 0,
	// Keep me consistent with ast::type_flags
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// The sz field of [[_type]] is set to this value to indicate that the size of
// the type is undefined.
export def SIZE_UNDEFINED: size = -1: size;

// A Hare type.
export type _type = struct {
	flags: flags,
	_type: (alias | array | builtin | _enum | func | pointer | slice |
		_struct | tagged | tuple),
	id: u32,
	sz: size,
	align: size,
};
