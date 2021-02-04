// Reverses a slice of bytes.
export fn reverse(b: []u8) void = {
	if (len(b) == 0z) {
		return;
	};
	for (let s = 0z, e = len(b) - 1z; s < e) {
		let x = b[s];
		b[s] = b[e];
		b[e] = x;
		s += 1z;
		e -= 1z;
	};
};

@test fn reverse() void = {
	let a: [4]u8 = [1u8, 3u8, 3u8, 7u8];
	reverse(a);
	assert(equal(a, [7u8, 3u8, 3u8, 1u8]));
	let b: [5]u8 = [1u8, 2u8, 3u8, 4u8, 5u8];
	reverse(b);
	assert(equal(b, [5u8, 4u8, 3u8, 2u8, 1u8]));
	let c: []u8 = [];
	reverse(c);
	assert(equal(c, []));
};
