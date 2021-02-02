use types;

fn to_utf8(in: str) []u8 = *(&in: *[]u8);

// The state for the UTF-8 decoder.
export type decoder = struct {
	offs: size,
	src: []u8,
};

// Initializes a new UTF-8 decoder.
export fn decode(src: (str | []u8)) decoder = match (src) {
	s: str => decoder {
		offs = 0z,
		src  = to_utf8(s),
	},
	b: []u8 => decoder {
		offs = 0z,
		src  = b,
	},
};

// Indicates that more data is needed, i.e. that a partial UTF-8 sequence was
// encountered.
export type more = void;

// An error indicating that an invalid UTF-8 sequence was found.
export type invalid = void;

// Returns the next rune from a decoder. If the slice ends with a complete UTF-8
// sequence, void is returned. If an incomplete sequence is encountered, more is
// returned. And if an invalid sequence is encountered, invalid returned.
export fn next(d: *decoder) (rune | void | more | invalid) = {
	if (d.offs >= len(d.src)) {
		return void;
	};

	// XXX: It would be faster if we decoded and measured at the same time.
	const n = utf8sz(d.src[d.offs..]);
	if (n == types::SIZE_MAX) {
		return invalid;
	} else if (d.offs + n > len(d.src)) {
		return more;
	};
	let bytes = d.src[d.offs..d.offs+n];
	d.offs += n;

	let r = 0u32;
	if (bytes[0] < 128u8) {
		// ASCII
		return bytes[0]: u32: rune;
	};

	const mask = masks[n - 1z];
	r = bytes[0] & mask;
	for (let i = 1z; i < len(bytes); i += 1z) {
		r <<= 6u8;
		r |= bytes[i] & 0x3Fu8;
	};
	return r: rune;
};

// Returns true if a given string or byte slice contains only valid UTF-8
// sequences. Note that Hare strings (str) are always valid UTF-8 - if this
// returns false for a str type, something funny is going on.
export fn valid(src: (str | []u8)) bool = {
	let decoder = decode(src);
	for (true) {
		match (next(&decoder)) {
			void    => return true,
			invalid => return false,
			more    => return false,
			rune    => void,
		};
	};
	abort();
};

fn utf8sz(src: []u8) size = {
	assert(len(src) > 0z);

	let c = src[0];
	for (let i = 0z; i < len(sizes); i += 1z) {
		if (c & sizes[i].mask == sizes[i].result) {
			return sizes[i].octets;
		};
	};

	return types::SIZE_MAX;
};
