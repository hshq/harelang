// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// https://en.wikipedia.org/wiki/ITU_T.61
const t61toascii: [_]u8 = [
//	 0	 1	 2	 3	 4	 5	 6	 7
//	 8	 9	 a	 b	 c	 d	 e	 f
	0,	0,	0,	0,	0,	0,	0,	0,	// 0
	0,	0,	0x0a,	0,	0x0c,	0x0d,	0,	0,	// 0
	0,	0,	0,	0,	0,	0,	0,	0,	// 10
	0,	0,	0x1a,	0x1b,	0,	0,	0,	0,	// 10
	0x20,	0x21,	0x22,	0,	0,	0x25,	0x26,	0x27,	// 20
	0x28,	0x29,	0x2a,	0x2b,	0x2c,	0x2d,	0x2e,	0x2f,	// 20
	0x30,	0x31,	0x32,	0x33,	0x34,	0x35,	0x36,	0x37,	// 30
	0x38,	0x39,	0x3a,	0x3b,	0x3c,	0x3d,	0x3e,	0x3f,	// 30
	0x40,	0x41,	0x42,	0x43,	0x44,	0x45,	0x46,	0x47,	// 40
	0x48,	0x49,	0x4a,	0x4b,	0x4c,	0x4d,	0x4e,	0x4f,	// 40
	0x50,	0x51,	0x52,	0x53,	0x54,	0x55,	0x56,	0x57,	// 50
	0x58,	0x59,	0x5a,	0x5b,	0,	0x5d,	0,	0x5f,	// 50
	0,	0x61,	0x62,	0x63,	0x64,	0x65,	0x66,	0x67,	// 60
	0x68,	0x69,	0x6a,	0x6b,	0x6c,	0x6d,	0x6e,	0x6f,	// 60
	0x70,	0x71,	0x72,	0x73,	0x74,	0x75,	0x76,	0x77,	// 70
	0x78,	0x79,	0x7a,	0,	0x7c,	0,	0,	0,	// 70
];

const t61toutf8: [_]rune = [
	// 0x80
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u008b',
	'\u008c', '\u0000', '\u0000', '\u0000',

	// 0x90
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u009b',
	'\u0000', '\u0000', '\u0000', '\u0000',

	// 0xa0
	'\u00a0', '\u00a1', '\u00a2', '\u00a3',
	'\u0024', '\u00a5', '\u0023', '\u00a7',
	'\u00a4', '\u0000', '\u0000', '\u00ab',
	'\u0000', '\u0000', '\u0000', '\u0000',

	// 0x0b
	'\u00b0', '\u00b1', '\u00b2', '\u00b3',
	'\u00d7', '\u00b5', '\u00b6', '\u00b7',
	'\u00f7', '\u0000', '\u0000', '\u00bb',
	'\u00bc', '\u00bd', '\u00be', '\u00bf',

	// 0xc0
	'\u0000', '\u0300', '\u0301', '\u0302',
	'\u0303', '\u0304', '\u0306', '\u0307',
	'\u0308', '\u0308', '\u030a', '\u0327',
	'\u0332', '\u030b', '\u0328', '\u030c',

	// 0xd0
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u0000',
	'\u0000', '\u0000', '\u0000', '\u0000',

	// 0xe0
	'\u2126', '\u00c6', '\u00d0', '\u00aa',
	'\u0126', '\u0000', '\u0132', '\u013f',
	'\u0141', '\u00d8', '\u0152', '\u00ba',
	'\u00de', '\u0166', '\u014a', '\u0149',

	// 0xf0
	'\u0138', '\u00e6', '\u0111', '\u00f0',
	'\u0127', '\u0131', '\u0133', '\u0140',
	'\u0142', '\u00f8', '\u0153', '\u00df',
	'\u00fe', '\u0167', '\u014b', '\u0000',
];

fn decode(out: []u8, in: []u8) void = {
	for (let i = 0z; i < len(in); i += 1) {
		const c = in[i];
		const r: rune = if (c & 0x80 != 0) {
			// TODO special cases
			yield t61toutf8[c - 0x80];
		} else {
			const c = t61toascii[in[i]];
			yield c: u32: rune;
		};

		// write r to out
	};
	return;
};

export type insufficient = !void;

export fn t61_chardecode(in: []u8) (rune | insufficient | invalid) = {
	// 'in' is either one char or two if first is a combining character.
	if (len(in) == 2) {
		return t61_combine(in);
	};

	const in = in[0];

	if (in & 0x80 == 0) {
		const r = t61toascii[in];
		return if (r == 0) invalid else r: u32: rune;
	};

	const c = t61toutf8[in - 0x80];
	if (c == '\u0000') {
		return invalid;
	};

	if (in == 0xcc) {
		return invalid;
	};
	if (in > 0xc0 && in <= 0xcf) {
		return insufficient;
	};

	return c;
};

fn t61_combine(in: []u8) (rune | invalid) = {
	const comb = in[0];
	const in = in[1];
	switch (comb) {
	case 0xc1 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c0';
		case 'E' =>
			return '\u00c8';
		case 'I' =>
			return '\u00cc';
		case 'O' =>
			return '\u00d2';
		case 'U' =>
			return '\u00d9';
		case 'a' =>
			return '\u00e0';
		case 'e' =>
			return '\u00e8';
		case 'i' =>
			return '\u00ec';
		case 'o' =>
			return '\u00f2';
		case 'u' =>
			return '\u00f9';
		case =>
			return invalid;
		};
	case 0xc2 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c1';
		case 'C' =>
			return '\u0106';
		case 'E' =>
			return '\u00c9';
		case 'I' =>
			return '\u00cd';
		case 'L' =>
			return '\u0139';
		case 'N' =>
			return '\u0143';
		case 'O' =>
			return '\u00d3';
		case 'R' =>
			return '\u0154';
		case 'S' =>
			return '\u015a';
		case 'U' =>
			return '\u00da';
		case 'Y' =>
			return '\u00dd';
		case 'Z' =>
			return '\u0179';
		case 'a' =>
			return '\u00e1';
		case 'c' =>
			return '\u0107';
		case 'e' =>
			return '\u00e9';
		case 'g' =>
			return '\u0123';
		case 'i' =>
			return '\u00ed';
		case 'l' =>
			return '\u013a';
		case 'n' =>
			return '\u0144';
		case 'o' =>
			return '\u00f3';
		case 'r' =>
			return '\u0155';
		case 's' =>
			return '\u015b';
		case 'u' =>
			return '\u00fa';
		case 'y' =>
			return '\u00fd';
		case 'z' =>
			return '\u017a';
		case =>
			return invalid;
		};
	case 0xc3 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c2';
		case 'C' =>
			return '\u0108';
		case 'E' =>
			return '\u00ca';
		case 'G' =>
			return '\u011c';
		case 'H' =>
			return '\u0124';
		case 'I' =>
			return '\u00ce';
		case 'J' =>
			return '\u0134';
		case 'O' =>
			return '\u00d4';
		case 'S' =>
			return '\u015c';
		case 'U' =>
			return '\u00db';
		case 'W' =>
			return '\u0174';
		case 'Y' =>
			return '\u0176';
		case 'a' =>
			return '\u00e2';
		case 'c' =>
			return '\u0109';
		case 'e' =>
			return '\u00ea';
		case 'g' =>
			return '\u011d';
		case 'h' =>
			return '\u0125';
		case 'i' =>
			return '\u00ee';
		case 'j' =>
			return '\u0135';
		case 'o' =>
			return '\u00f4';
		case 's' =>
			return '\u015d';
		case 'u' =>
			return '\u00fb';
		case 'w' =>
			return '\u0175';
		case 'y' =>
			return '\u0177';
		case =>
			return invalid;
		};
	case 0xc4 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c3';
		case 'I' =>
			return '\u0128';
		case 'N' =>
			return '\u00d1';
		case 'O' =>
			return '\u00d5';
		case 'U' =>
			return '\u0168';
		case 'a' =>
			return '\u00e3';
		case 'i' =>
			return '\u0129';
		case 'n' =>
			return '\u00f1';
		case 'o' =>
			return '\u00f5';
		case 'u' =>
			return '\u0169';
		case =>
			return invalid;
		};
	case 0xc5 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u0100';
		case 'E' =>
			return '\u0112';
		case 'I' =>
			return '\u012a';
		case 'O' =>
			return '\u014c';
		case 'U' =>
			return '\u016a';
		case 'a' =>
			return '\u0101';
		case 'e' =>
			return '\u0113';
		case 'i' =>
			return '\u012b';
		case 'o' =>
			return '\u014d';
		case 'u' =>
			return '\u016b';
		case =>
			return invalid;
		};
	case 0xc6 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u0102';
		case 'G' =>
			return '\u011e';
		case 'U' =>
			return '\u016c';
		case 'a' =>
			return '\u0103';
		case 'g' =>
			return '\u011f';
		case 'u' =>
			return '\u016d';
		case =>
			return invalid;
		};
	case 0xc7 =>
		switch (in: u32: rune) {
		case 'C' =>
			return '\u010a';
		case 'E' =>
			return '\u0116';
		case 'G' =>
			return '\u0120';
		case 'I' =>
			return '\u0130';
		case 'Z' =>
			return '\u017b';
		case 'c' =>
			return '\u010b';
		case 'e' =>
			return '\u0117';
		case 'g' =>
			return '\u0121';
		case 'z' =>
			return '\u017c';
		case =>
			return invalid;
		};
	case 0xc8 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c4';
		case 'E' =>
			return '\u00cb';
		case 'I' =>
			return '\u00cf';
		case 'O' =>
			return '\u00d6';
		case 'U' =>
			return '\u00dc';
		case 'Y' =>
			return '\u0178';
		case 'a' =>
			return '\u00e4';
		case 'e' =>
			return '\u00eb';
		case 'i' =>
			return '\u00ef';
		case 'o' =>
			return '\u00f6';
		case 'u' =>
			return '\u00fc';
		case 'y' =>
			return '\u00ff';
		case =>
			return invalid;
		};
	case 0xc9 =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c4';
		case 'E' =>
			return '\u00cb';
		case 'I' =>
			return '\u00cf';
		case 'O' =>
			return '\u00d6';
		case 'U' =>
			return '\u00dc';
		case 'Y' =>
			return '\u0178';
		case 'a' =>
			return '\u00e4';
		case 'e' =>
			return '\u00eb';
		case 'i' =>
			return '\u00ef';
		case 'o' =>
			return '\u00f6';
		case 'u' =>
			return '\u00fc';
		case 'y' =>
			return '\u00ff';
		case =>
			return invalid;
		};
	case 0xca =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u00c5';
		case 'U' =>
			return '\u016e';
		case 'a' =>
			return '\u00e5';
		case 'u' =>
			return '\u016f';
		case =>
			return invalid;
		};
	case 0xcb =>
		switch (in: u32: rune) {
		case 'C' =>
			return '\u00c7';
		case 'G' =>
			return '\u0122';
		case 'K' =>
			return '\u0136';
		case 'L' =>
			return '\u013b';
		case 'N' =>
			return '\u0145';
		case 'R' =>
			return '\u0156';
		case 'S' =>
			return '\u015e';
		case 'T' =>
			return '\u0162';
		case 'c' =>
			return '\u00e7';
		case 'k' =>
			return '\u0137';
		case 'l' =>
			return '\u013c';
		case 'n' =>
			return '\u0146';
		case 'r' =>
			return '\u0157';
		case 's' =>
			return '\u015f';
		case 't' =>
			return '\u0163';
		case =>
			return invalid;
		};
	case 0xcd =>
		switch (in: u32: rune) {
		case 'O' =>
			return '\u0150';
		case 'U' =>
			return '\u0170';
		case 'o' =>
			return '\u0151';
		case 'u' =>
			return '\u0171';
		case =>
			return invalid;
		};
	case 0xce =>
		switch (in: u32: rune) {
		case 'A' =>
			return '\u0104';
		case 'E' =>
			return '\u0118';
		case 'I' =>
			return '\u012e';
		case 'U' =>
			return '\u0172';
		case 'a' =>
			return '\u0105';
		case 'e' =>
			return '\u0119';
		case 'i' =>
			return '\u012f';
		case 'u' =>
			return '\u0173';
		case =>
			return invalid;
		};
	case 0xCf =>
		switch (in: u32: rune) {
		case 'C' =>
			return '\u010c';
		case 'D' =>
			return '\u010e';
		case 'E' =>
			return '\u011a';
		case 'L' =>
			return '\u013d';
		case 'N' =>
			return '\u0147';
		case 'R' =>
			return '\u0158';
		case 'S' =>
			return '\u0160';
		case 'T' =>
			return '\u0164';
		case 'Z' =>
			return '\u017d';
		case 'c' =>
			return '\u010d';
		case 'd' =>
			return '\u010f';
		case 'e' =>
			return '\u011b';
		case 'l' =>
			return '\u013e';
		case 'n' =>
			return '\u0148';
		case 'r' =>
			return '\u0159';
		case 's' =>
			return '\u0161';
		case 't' =>
			return '\u0165';
		case 'z' =>
			return '\u017e';
		case =>
			return invalid;
		};
	case =>
		return invalid;
	};
};
