export let builtin_char: _type = _type {
	repr = builtin::CHAR,
	sz = 1, align = 1,
	...
}, builtin_f32: _type = _type {
	repr = builtin::F32,
	sz = 4, align = 4,
	...
}, builtin_f64: _type = _type {
	repr = builtin::F64,
	sz = 8, align = 8,
	...
}, builtin_i8: _type = _type {
	repr = builtin::I8,
	sz = 1, align = 1,
	...
}, builtin_i16: _type = _type {
	repr = builtin::I16,
	sz = 2, align = 2,
	...
}, builtin_i32: _type = _type {
	repr = builtin::I32,
	sz = 4, align = 4,
	...
}, builtin_i64: _type = _type {
	repr = builtin::I64,
	sz = 8, align = 8,
	...
}, builtin_rune: _type = _type {
	repr = builtin::RUNE,
	sz = 4, align = 4,
	...
}, builtin_u8: _type = _type {
	repr = builtin::U8,
	sz = 1, align = 1,
	...
}, builtin_u16: _type = _type {
	repr = builtin::U16,
	sz = 2, align = 2,
	...
}, builtin_u32: _type = _type {
	repr = builtin::U32,
	sz = 4, align = 4,
	...
}, builtin_u64: _type = _type {
	repr = builtin::U64,
	sz = 8, align = 8,
	...
}, builtin_void: _type = _type {
	repr = builtin::VOID,
	sz = 0, align = 0,
	...
};

@init fn init() void = {
	const builtins = [
		&builtin_char,
		&builtin_f32,
		&builtin_f64,
		&builtin_i8,
		&builtin_i16,
		&builtin_i32,
		&builtin_i64,
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