use strings;
use types;
use ascii;
use encoding::utf8;

// Converts a string to a u64 in base 10. If the string contains any non-numeric
// characters, or if it's empty, [strconv::invalid] is returned. If the number
// is too large to be represented by a u64, [strconv::overflow] is returned.
export fn stou64(s: str) (u64 | invalid | overflow) = {
	if (len(s) == 0z) {
		return invalid;
	};
	let n = 0u64;
	let iter = strings::iter(s);
	for (true) {
		let r: rune = match (strings::next(&iter)) {
			void => break,
			r: rune => r,
		};

		if (!ascii::isascii(r) || !ascii::isdigit(r)) {
			return invalid;
		};

		let old = n;

		n *= 10u64;
		n += (r: u32 - '0': u32): u64;

		if (n < old) {
			return overflow;
		};
	};
	return n;
};

// Converts a string to a u32 in base 10. If the string contains any non-numeric
// characters, or if it's empty, [strconv::invalid] is returned. If the number
// is too large to be represented by a u32, [strconv::overflow] is returned.
export fn stou32(s: str) (u32 | invalid | overflow) = {
	match (stou64(s)) {
		v: (invalid | overflow) => return v,
		n: u64 => {
			if (n <= types::U32_MAX: u64) {
				return n: u32;
			};
			return overflow;
		},
	};
};

// Converts a string to a u16 in base 10. If the string contains any non-numeric
// characters, or if it's empty, [strconv::invalid] is returned. If the number
// is too large to be represented by a u16, [strconv::overflow] is returned.
export fn stou16(s: str) (u16 | invalid | overflow) = {
	match (stou64(s)) {
		v: (invalid | overflow) => return v,
		n: u64 => {
			if (n <= types::U16_MAX: u64) {
				return n: u16;
			};
			return overflow;
		},
	};
};

// Converts a string to a u8 in base 10. If the string contains any non-numeric
// characters, or if it's empty, [strconv::invalid] is returned. If the number
// is too large to be represented by a u8, [strconv::overflow] is returned.
export fn stou8(s: str) (u8 | invalid | overflow) = {
	match (stou64(s)) {
		v: (invalid | overflow) => return v,
		n: u64 => {
			if (n <= types::U8_MAX: u64) {
				return n: u8;
			};
			return overflow;
		},
	};
};

// Converts a string to a uint in base 10. If the string contains any
// non-numeric characters, or if it's empty, [strconv::invalid] is returned. If
// the number is too large to be represented by a uint, [strconv::overflow] is
// returned.
export fn stou(s: str) (uint | invalid | overflow) = {
	static assert(size(uint) == size(u32) || size(uint) == size(u64));
	return if (size(uint) == size(u32)) match (stou32(s)) {
		v: (invalid | overflow) => v,
		n: u32 => n: uint,
	} else match (stou64(s)) {
		v: (invalid | overflow) => v,
		n: u64 => n: uint,
	};
};

// Converts a string to a size in base 10. If the string contains any
// non-numeric characters, or if it's empty, [strconv::invalid] is returned. If
// the number is too large to be represented by a size, [strconv::overflow] is
// returned.
export fn stoz(s: str) (size | invalid | overflow) = {
	static assert(size(size) == size(u32) || size(size) == size(u64));
	return if (size(size) == size(u32)) match (stou32(s)) {
		v: (invalid | overflow) => v,
		n: u32 => n: size,
	} else match (stou64(s)) {
		v: (invalid | overflow) => v,
		n: u64 => n: size,
	};
};
