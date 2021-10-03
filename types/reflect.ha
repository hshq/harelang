// The sz field of [[typeinfo]] is set to this value to indicate that the size
// of the type is undefined.
export def SIZE_UNDEFINED: size = -1: size;

// Structure detailing information about a specific type.
export type typeinfo = struct {
	id: uint,
	sz: size,
	al: size,
	flags: flags,
	repr: repr,
};

// Returns [[typeinfo]] for the provided type.
export fn reflect(in: type) *typeinfo = in: *typeinfo;

// Returns [[typeinfo]] for the provided type, unwrapping any aliases along the
// way.
export fn unwrap(in: type) *typeinfo = {
	let info = reflect(in);
	match (info.repr) {
	case a: alias =>
		return unwrap(a.secondary);
	case =>
		return info;
	};
};

// Type flags.
export type flags = enum u8 {
	NONE = 0,
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// Details of the type representation.
export type repr = (alias | array | builtin
	| enumerated | func | pointer | slice_repr
	| struct_union | tagged | tuple);

// A type alias.
export type alias = struct {
	ident: []str,
	secondary: type,
};

// An array type.
export type array = struct {
	length: size,
	members: type,
};

// A built-in type.
export type builtin = enum u8 {
	BOOL, CHAR, ENUM, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE,
	STR, U16, U32, U64, U8, UINT, UINTPTR, VOID, TYPE,
};

// An enum type.
export type enumerated = struct {
	storage: builtin,
	values: [](str, u64),
};

// Indicates the variadism of a [[func]].
export type variadism = enum {
	NONE,
	C,
	HARE,
};

// Indicats if a [[func]] has the @noreturn attribute.
export type func_flags = enum uint {
	NORETURN = 1 << 0,
};

// A function type, e.g. fn(x: int, y: int) int.
export type func = struct {
	result: type,
	variadism: variadism,
	flags: func_flags,
	params: []type,
};

// Flags which apply to a pointer type.
export type pointer_flags = enum u8 {
	NONE = 0,
	NULLABLE = 1 << 0,
};

// *int
export type pointer = struct {
	secondary: type,
	flags: pointer_flags,
};

// Type information for slice members. Distinct from [[slice]], which is the
// representation of a slice object at runtime.
export type slice_repr = type;

// Indicates if a [[_struct]] was declared as a struct or union type.
export type struct_kind = enum {
	STRUCT,
	UNION,
};

// struct { ... } or union { ... }
export type struct_union = struct {
	kind: struct_kind,
	fields: []struct_field,
};

// A single struct field.
export type struct_field = struct {
	// "" for an anonymous field
	name: str,
	offs: size,
	type_: type,
};

// A tagged union type, e.g. (int | uint | void).
export type tagged = []type;

// A tuple type, e.g. (a, b, c)
export type tuple = []tuple_value;

// A single value of a tuple type.
export type tuple_value = struct {
	offs: size,
	type_: type,
};
