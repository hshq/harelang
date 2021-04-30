use hare::ast;

// A type alias.
export type alias = struct {
	id: ast::ident,
	// null for forward referenced types
	_type: const nullable *_type,
};

// A built-in primitive type (int, bool, str, etc).
export type builtin = enum u8 {
	// Keep me consistent with ast::builtin
	BOOL, CHAR, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE, STR,
	U16, U32, U64, U8, UINT, UINTPTR, VOID,
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
	_type: (alias | builtin | pointer),
	sz: size,
	align: size,
};
