// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Encodes a rune as UTF-8 and returns the result as a slice. The return value
// is statically allocated, and will not be consistent after subsequent calls to
// encoderune.
export fn encoderune(r: rune) []u8 = {
	let ch = r: u32, n = 0z, first = 0u8;
	assert((ch < 0xD800 || ch > 0xDFFF) && ch <= 0x10FFFF,
		"the rune is not a valid Unicode codepoint");

	if (ch < 0x80) {
		first = 0;
		n = 1;
	} else if (ch < 0x800) {
		first = 0xC0;
		n = 2;
	} else if (ch < 0x10000) {
		first = 0xE0;
		n = 3;
	} else {
		first = 0xF0;
		n = 4;
	};

	static let buf: [4]u8 = [0...];
	for (let i = n - 1; i > 0; i -= 1) {
		buf[i] = ch: u8 & 0x3F | 0x80;
		ch >>= 6;
	};
	buf[0] = ch: u8 | first;
	return buf[..n];
};

@test fn encode() void = {
	const expected: [_][]u8 = [
		[0],
		[0x25],
		[0xE3, 0x81, 0x93],
	];
	const inputs = ['\0', '%', 'こ'];
	for (let i = 0z; i < len(inputs); i += 1) {
		const out = encoderune(inputs[i]);
		for (let j = 0z; j < len(expected[i]); j += 1) {
			assert(out[j] == expected[i][j]);
		};
	};
};
