// Encodes a rune as UTF-8 and returns the result as a slice. The result is
// statically allocated; duplicate it if you aren't using it right away.
export fn encode_rune(r: rune) []u8 = {
	let ch = r: u32, n = 0z, first = 0u8;
	if (ch < 0x80u32) {
		first = 0u8;
		n = 1z;
	} else if (ch < 0x800u32) {
		first = 0xC0u8;
		n = 2z;
	} else if (ch < 0x10000u32) {
		first = 0xE0u8;
		n = 3z;
	} else {
		first = 0xF0u8;
		n = 4z;
	};

	static let buf: [6]u8 = [0u8...];
	for (let i = n - 1z; i > 0z; i -= 1z) {
		buf[i] = ch: u8 & 0x3Fu8 | 0x80u8;
		ch >>= 6u32;
	};
	buf[0] = ch: u8 | first;
	return buf[..n];
};
