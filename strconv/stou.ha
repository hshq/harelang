use strings;
use types;
use ascii;
use encoding::utf8;

fn rune_to_integer(r: rune) (u64 | void) = {
	if (ascii::isdigit(r))
		return (r: u32 - '0': u32): u64
	else if (ascii::isalpha(r) && ascii::islower(r))
		return (r: u32 - 'a': u32): u64 + 10
	else if (ascii::isalpha(r) && ascii::isupper(r))
		return (r: u32 - 'A': u32): u64 + 10;
};

// Converts a string to a u64 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u64, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stou64b(s: str, base: uint) (u64 | invalid | overflow) = {
	assert(base == 2 || base == 8 || base == 10 || base == 16);

	if (len(s) == 0) {
		return 0: invalid;
	};

	let n = 0u64;
	let iter = strings::iter(s);
	for (true) {
		let r: rune = match (strings::next(&iter)) {
		case r: rune =>
			yield r;
		case void =>
			break;
		};

		let digit = match (rune_to_integer(r)) {
		case void =>
			return (iter.dec.offs - 1): invalid;
		case d: u64 =>
			yield d;
		};

		if (digit >= base: u64) {
			return (iter.dec.offs - 1): invalid;
		};

		let old = n;

		n *= base;
		n += digit;

		if (n < old) {
			return overflow;
		};
	};
	return n;
};

// Converts a string to a u32 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u32, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stou32b(s: str, base: uint) (u32 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U32_MAX: u64) {
		return n: u32;
	};
	return overflow;
};

// Converts a string to a u16 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u16, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stou16b(s: str, base: uint) (u16 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U16_MAX: u64) {
		return n: u16;
	};
	return overflow;
};

// Converts a string to a u8 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u8, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stou8b(s: str, base: uint) (u8 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U8_MAX: u64) {
		return n: u8;
	};
	return overflow;
};

// Converts a string to a uint in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a uint, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stoub(s: str, base: uint) (uint | invalid | overflow) = {
	static assert(size(uint) == size(u32) || size(uint) == size(u64));
	return
		if (size(uint) == size(u32)) stou32b(s, base)?: uint
		else stou64b(s, base)?: uint;
};

// Converts a string to a size in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a size, [[strconv::overflow]] is
// returned. Supported bases are 2, 8, 10 and 16.
export fn stozb(s: str, base: uint) (size | invalid | overflow) = {
	static assert(size(size) == size(u32) || size(size) == size(u64));
	if (size(size) == size(u32)) {
		match (stou32b(s, base)) {
		case v: (invalid | overflow) =>
			return v;
		case n: u32 =>
			return n: size;
		};
	} else {
		match (stou64b(s, base)) {
		case v: (invalid | overflow) =>
			return v;
		case n: u64 =>
			return n: size;
		};
	};
};

// Converts a string to a u64 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u64, [[strconv::overflow]] is
// returned.
export fn stou64(s: str) (u64 | invalid | overflow) = stou64b(s, 10);

// Converts a string to a u32 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u32, [[strconv::overflow]] is
// returned.
export fn stou32(s: str) (u32 | invalid | overflow) = stou32b(s, 10);

// Converts a string to a u16 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u16, [[strconv::overflow]] is
// returned.
export fn stou16(s: str) (u16 | invalid | overflow) = stou16b(s, 10);

// Converts a string to a u8 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a u8, [[strconv::overflow]] is
// returned.
export fn stou8(s: str) (u8 | invalid | overflow) = stou8b(s, 10);

// Converts a string to a uint in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a uint, [[strconv::overflow]] is
// returned.
export fn stou(s: str) (uint | invalid | overflow) = stoub(s, 10);

// Converts a string to a size in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[strconv::invalid]] is returned. If
// the number is too large to be represented by a size, [[strconv::overflow]] is
// returned.
export fn stoz(s: str) (size | invalid | overflow) = stozb(s, 10);
