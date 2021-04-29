use hare::ast;

// A type alias.
export type alias = ast::ident;

// A built-in primitive type (int, bool, str, etc).
export type builtin = enum u8 {
	// Keep me consistent with ast::builtin
	BOOL, CHAR, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE, STR,
	U16, U32, U64, U8, UINT, UINTPTR, VOID,
};

// Flags for a Hare type.
export type flags = enum u8 {
	NONE = 0,
	// Keep me consistent with ast::type_flags
	CONST = 1 << 0,
	ERROR = 1 << 1,
};

// A Hare type.
export type _type = struct {
	flags: flags,
	_type: (alias | builtin),
};
