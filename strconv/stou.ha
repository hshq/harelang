// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use encoding::utf8;
use strings;
use types;

fn rune_to_integer(r: rune) (u64 | void) = {
	if (ascii::isdigit(r))
		return (r: u32 - '0'): u64
	else if (ascii::isalpha(r) && ascii::islower(r))
		return (r: u32 - 'a'): u64 + 10
	else if (ascii::isalpha(r) && ascii::isupper(r))
		return (r: u32 - 'A'): u64 + 10;
};

// Converts a string to a u64 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u64, [[overflow]] is returned.
export fn stou64b(s: str, base: base) (u64 | invalid | overflow) = {
	if (base == base::DEFAULT) {
		base = base::DEC;
	};
	assert(base == 2 || base == 8 || base == 10 || base == 16);

	if (len(s) == 0) {
		return 0: invalid;
	};
	if (strings::hasprefix(s, "-")) {
		return overflow;
	} else if (strings::hasprefix(s, "+")) {
		s = strings::trimprefix(s, "+");
	};

	let n = 0u64;
	let iter = strings::iter(s);
	for (true) {
		let r: rune = match (strings::next(&iter)) {
		case let r: rune =>
			yield r;
		case void =>
			break;
		};

		let digit = match (rune_to_integer(r)) {
		case void =>
			return (iter.dec.offs - 1): invalid;
		case let d: u64 =>
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
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u32, [[overflow]] is returned.
export fn stou32b(s: str, base: base) (u32 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U32_MAX: u64) {
		return n: u32;
	};
	return overflow;
};

// Converts a string to a u16 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u16, [[overflow]] is returned.
export fn stou16b(s: str, base: base) (u16 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U16_MAX: u64) {
		return n: u16;
	};
	return overflow;
};

// Converts a string to a u8 in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u8, [[overflow]] is returned.
export fn stou8b(s: str, base: base) (u8 | invalid | overflow) = {
	let n = stou64b(s, base)?;
	if (n <= types::U8_MAX: u64) {
		return n: u8;
	};
	return overflow;
};

// Converts a string to a uint in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a uint, [[overflow]] is returned.
export fn stoub(s: str, base: base) (uint | invalid | overflow) = {
	static assert(size(uint) == size(u32) || size(uint) == size(u64));
	return
		if (size(uint) == size(u32)) stou32b(s, base)?: uint
		else stou64b(s, base)?: uint;
};

// Converts a string to a size in the given base, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a size, [[overflow]] is returned.
export fn stozb(s: str, base: base) (size | invalid | overflow) = {
	static assert(size(size) == size(u32) || size(size) == size(u64));
	if (size(size) == size(u32)) {
		match (stou32b(s, base)) {
		case let v: (invalid | overflow) =>
			return v;
		case let n: u32 =>
			return n: size;
		};
	} else {
		match (stou64b(s, base)) {
		case let v: (invalid | overflow) =>
			return v;
		case let n: u64 =>
			return n: size;
		};
	};
};

// Converts a string to a u64 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u64, [[overflow]] is returned.
export fn stou64(s: str) (u64 | invalid | overflow) = stou64b(s, base::DEC);

// Converts a string to a u32 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u32, [[overflow]] is returned.
export fn stou32(s: str) (u32 | invalid | overflow) = stou32b(s, base::DEC);

// Converts a string to a u16 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u16, [[overflow]] is returned.
export fn stou16(s: str) (u16 | invalid | overflow) = stou16b(s, base::DEC);

// Converts a string to a u8 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a u8, [[overflow]] is returned.
export fn stou8(s: str) (u8 | invalid | overflow) = stou8b(s, base::DEC);

// Converts a string to a uint in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a uint, [[overflow]] is returned.
export fn stou(s: str) (uint | invalid | overflow) = stoub(s, base::DEC);

// Converts a string to a size in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by a size, [[overflow]] is returned.
export fn stoz(s: str) (size | invalid | overflow) = stozb(s, base::DEC);
