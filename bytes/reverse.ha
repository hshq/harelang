// Reverses a slice of bytes.
export fn reverse(b: []u8) void = {
	for (let s = 0z, e = len(b) - 1z; s < e) {
		let x = b[s];
		b[s] = b[e];
		b[e] = x;
		s += 1z;
		e -= 1z;
	};
};
