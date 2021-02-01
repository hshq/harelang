use types;

// An error indicating that an invalid UTF-8 sequence was found.
export type invalid = void;

const masks: [_]u8 = [0x7Fu8, 0x1Fu8, 0x0Fu8, 0x07u8, 0x03u8, 0x01u8];

type rsize = struct {
	mask: u8,
	result: u8,
	octets: size,
};

const sizes: [_]rsize = [
	rsize { mask = 0x80u8, result = 0x00u8, octets = 1z },
	rsize { mask = 0xE0u8, result = 0xC0u8, octets = 2z },
	rsize { mask = 0xF0u8, result = 0xE0u8, octets = 3z },
	rsize { mask = 0xF8u8, result = 0xF0u8, octets = 4z },
	rsize { mask = 0xFCu8, result = 0xF8u8, octets = 5z },
	rsize { mask = 0xFEu8, result = 0xF8u8, octets = 6z },
	rsize { mask = 0x80u8, result = 0x80u8, octets = types::SIZE_MAX },
];

// Returns the size of a rune, in octets, when encoded as UTF-8.
export fn runesz(r: rune) size = {
	const ch = r: u32;
	return if (ch < 0x80u32) 1z
		else if (ch < 0x800u32) 2z
		else if (ch < 0x10000u32) 3z
		else 4z;
};
