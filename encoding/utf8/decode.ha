use strings;
use types;

// The state for the UTF-8 decoder.
export type decoder = struct {
	offs: size,
	src: []u8,
};

export fn decode(src: str) decoder = decoder {
	offs = 0z,
	src  = strings::to_utf8(src),
};

// Initializes a new UTF-8 decoder for a byte slice.
export fn decode_bytes(src: []u8) decoder = decoder {
	offs = 0z,
	src  = src,
};

// Indicates that more data is needed, or that a partial UTF-8 sequence was
// encountered.
export type more = void;

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

	let cp = 0u32;
	if (bytes[0] < 128u8) {
		// ASCII
		return bytes[0]: u32: rune;
	};

	const mask = masks[n - 1z];
	cp = bytes[0] & mask;
	for (let i = 1z; i < len(bytes); i += 1z) {
		cp <<= 6u8;
		cp |= bytes[i] & 0x3Fu8;
	};
	return cp: rune;
};

fn utf8sz(src: []u8) size = {
	assert(sizes[0].octets == 1z);

	assert(len(src) > 0z);
	let c = src[0];
	for (let i = 0z; i < len(sizes); i += 1z) {
		if (c & sizes[i].mask == sizes[i].result) {
			return sizes[i].octets;
		};
	};
	return types::SIZE_MAX;
};
