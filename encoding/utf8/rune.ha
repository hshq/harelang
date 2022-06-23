// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use types;

const masks: [_]u8 = [0x7F, 0x1F, 0x0F, 0x07, 0x03, 0x01];

type rsize = struct {
	mask: u8,
	result: u8,
	octets: size,
};

const sizes: [_]rsize = [
	rsize { mask = 0x80, result = 0x00, octets = 1 },
	rsize { mask = 0xE0, result = 0xC0, octets = 2 },
	rsize { mask = 0xF0, result = 0xE0, octets = 3 },
	rsize { mask = 0xF8, result = 0xF0, octets = 4 },
	rsize { mask = 0xFC, result = 0xF8, octets = 5 },
	rsize { mask = 0xFE, result = 0xF8, octets = 6 },
];

// Returns the size of a rune, in octets, when encoded as UTF-8.
export fn runesz(r: rune) size = {
	const ch = r: u32;
	return if (ch < 0x80) 1
		else if (ch < 0x800) 2
		else if (ch < 0x10000) 3
		else 4;
};

// Returns the expected length of a UTF-8 codepoint in bytes given its first
// byte, or void if the given byte doesn't begin a valid UTF-8 sequence.
export fn utf8sz(c: u8) (size | void) = {
	for (let i = 0z; i < len(sizes); i += 1) {
		if (c & sizes[i].mask == sizes[i].result) {
			return sizes[i].octets;
		};
	};
};
