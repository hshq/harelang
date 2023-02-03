// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

fn toutf8(in: str) []u8 = *(&in: *[]u8);

export type decoder = struct {
	offs: size,
	src: []u8,
};

// Initializes a new UTF-8 decoder.
export fn decode(src: (str | []u8)) decoder = match (src) {
case let s: str =>
	yield decoder { src = toutf8(s), ...  };
case let b: []u8 =>
	yield decoder { src = b, ...  };
};

// Returned when more data is needed, i.e. when an incomplete UTF-8 sequence is
// encountered.
export type more = void;

// Returned when an invalid UTF-8 sequence was found.
export type invalid = !void;

const leader_masks: [_]u8 = [0x7F, 0x3F, 0x1F, 0x0F];

const masks: [2][8]u8 = [
	[0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f],
	[0x7f, 0x1f, 0x0f, 0x0f, 0x0f, 0x07, 0x07, 0x07],
];

fn decode_leader(c: u8) ((size, u8) | invalid) = {
	for (let i = 0z; i < len(sizes); i += 1) {
		if (c & sizes[i].mask == sizes[i].result) {
			return (sizes[i].octets, c & leader_masks[i]);
		};
	};
	// Bad leading byte
	return invalid;
};

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

	let r = 0u32;
	let n = 0z;
	for (let i = 0z; i < d.offs; i += 1) {
		let byte = d.src[d.offs - i - 1];
		if ((byte & 0xC0) == 0x80) {
			if (i == 3) {
				// Too many continuation bytes in a row
				return invalid;
			};
			byte &= 0x3F;
			r |= byte << (i * 6): u32;
		} else {
			const nl = decode_leader(byte)?;
			n = nl.0;
			if (i + 1 != n) {
				// Trailing continuation bytes
				return invalid;
			};
			r |= nl.1 << (i * 6): u32;
			break;
		};
	};

	if (n == 0) {
		return more;
	} else if (n > 1) {
		if (r >= 0xD800 && r <= 0xDFFF) {
			// UTF-16 surrogates
			return invalid;
		};
		if (runesz(r: rune) != n) {
			// Overlong encoding
			return invalid;
		};
	};

	d.offs -= n;
	return r: rune;
};

@test fn decode() void = {
	const input: [_]u8 = [
		0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81,
		0xAB, 0xE3, 0x81, 0xA1, 0xE3, 0x81, 0xAF, 0x00,
	];
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

	const incomplete: [_]u8 = [0xE3, 0x81];
	decoder = decode(incomplete);
	assert(next(&decoder) is more);
	decoder.offs = 2;
	assert(prev(&decoder) is invalid);

	const surrogate: [_]u8 = [0xED, 0xA0, 0x80];
	decoder = decode(surrogate);
	assert(next(&decoder) is invalid);
	decoder.offs = 3;
	assert(prev(&decoder) is invalid);

	const overlong: [_]u8 = [0xF0, 0x82, 0x82, 0xAC];
	decoder = decode(overlong);
	assert(next(&decoder) is invalid);
	decoder.offs = 4;
	assert(prev(&decoder) is invalid);

	const badcont: [_]u8 = [0xC2, 0xFF];
	decoder = decode(badcont);
	assert(next(&decoder) is invalid);

	const extracont: [_]u8 = [0xC2, 0xA3, 0x95];
	decoder = decode(extracont);
	decoder.offs = 3;
	assert(prev(&decoder) is invalid);

	const regression: []u8 = [0xf5, 0x94, 0x80, 0x80];
	assert(!valid(regression));
};

// Returns true if a given string or byte slice contains only valid UTF-8
// sequences. Note that Hare strings (str) are always valid UTF-8 - if this
// returns false for a str type, something funny is going on.
export fn valid(src: (str | []u8)) bool = {
	let decoder = decode(src);
	for (true) {
		match (next(&decoder)) {
		case void =>
			return true;
		case invalid =>
			return false;
		case more =>
			return false;
		case rune => void;
		};
	};
	abort();
};
