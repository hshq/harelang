// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;
use types;

// Converts a string to an i64 in the given base. If the string contains any
// non-numeric characters, except '-' or '+' at the start, or if it's empty,
// [[invalid]] is returned. If the number is too large to be represented by an
// i64, [[overflow]] is returned.
export fn stoi64b(s: str, base: base) (i64 | invalid | overflow) = {
	let (sign, u) = parseint(s, base)?;
	// Two's complement: I64_MIN = -I64_MAX - 1
	let max = if (sign) types::I64_MAX: u64 + 1 else types::I64_MAX: u64;
	if (u > max) {
		return overflow;
	};
	return u: i64 * (if (sign) -1 else 1);
};

// Converts a string to an i32 in the given base. If the string contains any
// non-numeric characters, except '-' or '+' at the start, or if it's empty,
// [[invalid]] is returned. If the number is too large to be represented by an
// i32, [[overflow]] is returned.
export fn stoi32b(s: str, base: base) (i32 | invalid | overflow) = {
	let n = stoi64b(s, base)?;
	if (n >= types::I32_MIN: i64 && n <= types::I32_MAX: i64) {
		return n: i32;
	};
	return overflow;
};

// Converts a string to an i16 in the given base. If the string contains any
// non-numeric characters, except '-' or '+' at the start, or if it's empty,
// [[invalid]] is returned. If the number is too large to be represented by an
// i16, [[overflow]] is returned.
export fn stoi16b(s: str, base: base) (i16 | invalid | overflow) = {
	let n = stoi64b(s, base)?;
	if (n >= types::I16_MIN: i64 && n <= types::I16_MAX: i64) {
		return n: i16;
	};
	return overflow;
};

// Converts a string to an i8 in the given base. If the string contains any
// non-numeric characters, except '-' or '+' at the start, or if it's empty,
// [[invalid]] is returned. If the number is too large to be represented by an
// i8, [[overflow]] is returned.
export fn stoi8b(s: str, base: base) (i8 | invalid | overflow) = {
	let n= stoi64b(s, base)?;
	if (n >= types::I8_MIN: i64 && n <= types::I8_MAX: i64) {
		return n: i8;
	};
	return overflow;
};

// Converts a string to an int in the given base. If the string contains any
// non-numeric characters, except '-' or '+' at the start, or if it's empty,
// [[invalid]] is returned. If the number is too large to be represented by an
// int, [[overflow]] is returned.
export fn stoib(s: str, base: base) (int | invalid | overflow) = {
	static assert(size(int) == size(i32) || size(int) == size(i64));
	return
		if (size(int) == size(i32)) stoi32b(s, base)?: int
		else stoi64b(s, base)?: int;
};

// Converts a string to an i64 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by an i64, [[overflow]] is
// returned.
export fn stoi64(s: str) (i64 | invalid | overflow) = stoi64b(s, 10);

// Converts a string to an i32 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by an i32, [[overflow]] is
// returned.
export fn stoi32(s: str) (i32 | invalid | overflow) = stoi32b(s, 10);

// Converts a string to an i16 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by an i16, [[overflow]] is
// returned.
export fn stoi16(s: str) (i16 | invalid | overflow) = stoi16b(s, 10);

// Converts a string to an i8 in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by an i8, [[overflow]] is
// returned.
export fn stoi8(s: str) (i8 | invalid | overflow) = stoi8b(s, 10);

// Converts a string to an int in base 10, If the string contains any
// non-numeric characters, or if it's empty, [[invalid]] is returned. If the
// number is too large to be represented by an int, [[overflow]] is
// returned.
export fn stoi(s: str) (int | invalid | overflow) = stoib(s, 10);
