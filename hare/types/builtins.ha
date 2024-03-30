// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// IDs are precomputed, but a test verifies that they match what they would be
// if computed at runtime

// [[_type]] representation of bool.
export const builtin_bool: _type = _type {
	repr = builtin::BOOL,
	sz = 1, _align = 1,
	id = 292984781,
	...
};

// [[_type]] representation of done.
export const builtin_done: _type = _type {
	repr = builtin::DONE,
	sz = 0, _align = 0,
	id = 3950255460,
	...
};

// [[_type]] representation of f32.
export const builtin_f32: _type = _type {
	repr = builtin::F32,
	sz = 4, _align = 4,
	id = 1568378015,
	...
};

// [[_type]] representation of f64.
export const builtin_f64: _type = _type {
	repr = builtin::F64,
	sz = 8, _align = 8,
	id = 930681398,
	...
};

// [[_type]] representation of i8.
export const builtin_i8: _type = _type {
	repr = builtin::I8,
	sz = 1, _align = 1,
	id = 2674862226,
	...
};

// [[_type]] representation of i16.
export const builtin_i16: _type = _type {
	repr = builtin::I16,
	sz = 2, _align = 2,
	id = 2037165609,
	...
};

// [[_type]] representation of i32.
export const builtin_i32: _type = _type {
	repr = builtin::I32,
	sz = 4, _align = 4,
	id = 1399468992,
	...
};

// [[_type]] representation of i64.
export const builtin_i64: _type = _type {
	repr = builtin::I64,
	sz = 8, _align = 8,
	id = 3312558843,
	...
};

// [[_type]] representation of opaque.
export const builtin_opaque: _type = _type {
	repr = builtin::OPAQUE,
	sz = SIZE_UNDEFINED, _align = SIZE_UNDEFINED,
	id = 1737287038,
	...
};

// [[_type]] representation of never.
export const builtin_never: _type = _type {
	repr = builtin::NEVER,
	sz = SIZE_UNDEFINED, _align = SIZE_UNDEFINED,
	id = 1737287038,
	...
};

// [[_type]] representation of rune.
export const builtin_rune: _type = _type {
	repr = builtin::RUNE,
	sz = 4, _align = 4,
	id = 2843771249,
	...
};

// [[_type]] representation of u8.
export const builtin_u8: _type = _type {
	repr = builtin::U8,
	sz = 1, _align = 1,
	id = 3181589295,
	...
};

// [[_type]] representation of u16.
export const builtin_u16: _type = _type {
	repr = builtin::U16,
	sz = 2, _align = 2,
	id = 3481467866,
	...
};

// [[_type]] representation of u32.
export const builtin_u32: _type = _type {
	repr = builtin::U32,
	sz = 4, _align = 4,
	id = 1906196061,
	...
};

// [[_type]] representation of u64.
export const builtin_u64: _type = _type {
	repr = builtin::U64,
	sz = 8, _align = 8,
	id = 1268499444,
	...
};

// [[_type]] representation of void.
export const builtin_void: _type = _type {
	repr = builtin::VOID,
	sz = 0, _align = 0,
	id = 3012680272,
	...
};
