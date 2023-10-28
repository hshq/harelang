// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn toutf8(in: str) []u8 = *(&in: *[]u8);

fn fromtagged(in: (str | []u8)) []u8 = match (in) {
case let s: str =>
	return toutf8(s);
case let b: []u8 =>
	return b;
};

export type decoder = struct {
	offs: size,
	src: []u8,
};

// Initializes a new UTF-8 decoder.
export fn decode(src: (str | []u8)) decoder = decoder {
	src = fromtagged(src),
	offs = 0,
};

const masks: [2][8]u8 = [
	[0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f],
	[0x7f, 0x1f, 0x0f, 0x0f, 0x0f, 0x07, 0x07, 0x07],
];

// Returns the next rune from a decoder. void is returned when there are no
// remaining codepoints.
export fn next(d: *decoder) (rune | void | more | invalid) = {
	if (d.offs == len(d.src)) {
		return;
	};

	// from https://github.com/skeeto/scratch/blob/master/parsers/utf8_decode.c
	// See https://bjoern.hoehrmann.de/utf-8/decoder/dfa/
	// and https://nullprogram.com/blog/2020/12/31/ for an explanation of
	// the algorithm.
	let next = 0, state = 0;
	let r = 0u32;
	for (d.offs < len(d.src); d.offs += 1) {
		next = table[state][d.src[d.offs]];
		r = r << 6 | d.src[d.offs] & masks[(state - 1): uint >> 31][next & 7];
		if (next <= 0) {
			d.offs += 1;
			return if (next == 0) r: rune else invalid;
		};
		state = next;
	};
	return more;
};

// Returns the previous rune from a decoder. void is returned when there are no
// previous codepoints.
export fn prev(d: *decoder) (rune | void | more | invalid) = {
	if (d.offs == 0) {
		return;
	};
	let n = d.offs;
	d.offs -= 1;
	for (d.offs < len(d.src); d.offs -= 1) {
		if (table[0][d.src[d.offs]] != -1) {
			let t = d.offs;
			defer d.offs = t;
			let r = next(d);
			return if (n != d.offs || r is more) invalid else r;
		};
		if (n - d.offs == 4) {
			// Too many continuation bytes in a row
			return invalid;
		};
	};
	return more;
};

@test fn decode() void = {
	const input: [_]u8 = [
		0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81,
		0xAB, 0xE3, 0x81, 0xA1, 0xE3, 0x81, 0xAF, 0x00,
	];
	assert(valid(input));
	const expected = ['こ', 'ん', 'に', 'ち', 'は', '\0'];
	let decoder = decode(input);
	for (let i = 0z; i < len(expected); i += 1) {
		match (next(&decoder)) {
		case (invalid | more | void) =>
			abort();
		case let r: rune =>
			assert(r == expected[i]);
		};
	};
	assert(next(&decoder) is void);
	assert(decoder.offs == len(decoder.src));
	for (let i = 0z; i < len(expected); i += 1) {
		match (prev(&decoder)) {
		case (invalid | more | void) =>
			abort();
		case let r: rune =>
			assert(r == expected[len(expected) - i - 1]);
		};
	};
	assert(prev(&decoder) is void);

	const inv: [_]u8 = [0xA0, 0xA1];
	decoder = decode(inv);
	assert(next(&decoder) is invalid);
	decoder.offs = 2;
	assert(prev(&decoder) is more);
	assert(!valid(inv));

	const incomplete: [_]u8 = [0xE3, 0x81];
	decoder = decode(incomplete);
	assert(next(&decoder) is more);
	decoder.offs = 2;
	assert(prev(&decoder) is invalid);
	assert(!valid(incomplete));

	const surrogate: [_]u8 = [0xED, 0xA0, 0x80];
	decoder = decode(surrogate);
	assert(next(&decoder) is invalid);
	decoder.offs = 3;
	assert(prev(&decoder) is invalid);
	assert(!valid(surrogate));

	const overlong: [_]u8 = [0xF0, 0x82, 0x82, 0xAC];
	decoder = decode(overlong);
	assert(next(&decoder) is invalid);
	decoder.offs = 4;
	assert(prev(&decoder) is invalid);
	assert(!valid(overlong));

	const badcont: [_]u8 = [0xC2, 0xFF];
	decoder = decode(badcont);
	assert(next(&decoder) is invalid);
	assert(!valid(badcont));

	const extracont: [_]u8 = [0xC2, 0xA3, 0x95];
	decoder = decode(extracont);
	decoder.offs = 3;
	assert(prev(&decoder) is invalid);
	assert(!valid(extracont));
	const maxinrange: [_]u8 = [0xF4, 0x8F, 0xBF, 0xBF];
	decoder = decode(maxinrange);
	match (next(&decoder)) {
	case let r: rune =>
		assert(r == 0x10FFFFu32: rune);
	case => abort();
	};
	decoder.offs = 4;
	match (prev(&decoder)) {
	case let r: rune =>
		assert(r == 0x10FFFFu32: rune);
	case => abort();
	};

	const minoutofrange: [_]u8 = [0xF5, 0x94, 0x80, 0x80];
	decoder = decode(minoutofrange);
	assert(next(&decoder) is invalid);
	decoder.offs = 4;
	assert(prev(&decoder) is invalid);
};

// Returns true if a given string or byte slice contains only valid UTF-8
// sequences. Note that Hare strings (str) are always valid UTF-8 - if this
// returns false for a str type, something funny is going on.
export fn valid(src: (str | []u8)) bool = {
	let src = fromtagged(src);
	let state = 0;
	for (let i = 0z; i < len(src) && state >= 0; i += 1) {
		state = table[state][src[i]];
	};
	return state == 0;
};
