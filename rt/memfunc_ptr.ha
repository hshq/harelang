// License: MPL-2.0

type memfunc_ptr = union {
	byte: *[*]u8,
	quad: *[*]u32,
	octs: *[*]u64,
	sz: *[*]size,
	uptr: uintptr,
};
