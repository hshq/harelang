// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// [[_type]] representation of bool.
export const builtin_bool: _type = _type {
	repr = builtin::BOOL,
	sz = 1, _align = 1,
	...
};

// [[_type]] representation of f32.
export const builtin_f32: _type = _type {
	repr = builtin::F32,
	sz = 4, _align = 4,
	...
};

// [[_type]] representation of f64.
export const builtin_f64: _type = _type {
	repr = builtin::F64,
	sz = 8, _align = 8,
	...
};

// [[_type]] representation of i8.
export const builtin_i8: _type = _type {
	repr = builtin::I8,
	sz = 1, _align = 1,
	...
};

// [[_type]] representation of i16.
export const builtin_i16: _type = _type {
	repr = builtin::I16,
	sz = 2, _align = 2,
	...
};

// [[_type]] representation of i32.
export const builtin_i32: _type = _type {
	repr = builtin::I32,
	sz = 4, _align = 4,
	...
};

// [[_type]] representation of i64.
export const builtin_i64: _type = _type {
	repr = builtin::I64,
	sz = 8, _align = 8,
	...
};

// [[_type]] representation of opaque.
export const builtin_opaque: _type = _type {
	repr = builtin::OPAQUE,
	sz = SIZE_UNDEFINED, _align = SIZE_UNDEFINED,
	...
};

// [[_type]] representation of rune.
export const builtin_rune: _type = _type {
	repr = builtin::RUNE,
	sz = 4, _align = 4,
	...
};

// [[_type]] representation of u8.
export const builtin_u8: _type = _type {
	repr = builtin::U8,
	sz = 1, _align = 1,
	...
};

// [[_type]] representation of u16.
export const builtin_u16: _type = _type {
	repr = builtin::U16,
	sz = 2, _align = 2,
	...
};

// [[_type]] representation of u32.
export const builtin_u32: _type = _type {
	repr = builtin::U32,
	sz = 4, _align = 4,
	...
};

// [[_type]] representation of u64.
export const builtin_u64: _type = _type {
	repr = builtin::U64,
	sz = 8, _align = 8,
	...
};

// [[_type]] representation of void.
export const builtin_void: _type = _type {
	repr = builtin::VOID,
	sz = 0, _align = 0,
	...
};

@init fn init() void = {
	const builtins = [
		&builtin_bool,
		&builtin_f32,
		&builtin_f64,
		&builtin_i8,
		&builtin_i16,
		&builtin_i32,
		&builtin_i64,
		&builtin_opaque,
		&builtin_rune,
		&builtin_u8,
		&builtin_u16,
		&builtin_u32,
		&builtin_u64,
		&builtin_void,
	];
	for (let i = 0z; i < len(builtins); i += 1) {
		builtins[i].id = hash(builtins[i]);
	};
};
