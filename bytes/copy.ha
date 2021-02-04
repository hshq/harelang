// Copies bytes from src to dest. dest must have the same length as src.
export fn copy(dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src),
		"Destination slice must have same length as source slice");
	for (let i = 0z; i < len(dest); i += 1z) {
		dest[i] = src[i];
	};
};

@test fn copy() void = {
	let a: [4]u8 = [1u8, 3u8, 3u8, 7u8];
	let b: [4]u8 = [0u8...];
	copy(b[..], a[..]);
	assert(equal(a, b));
};
