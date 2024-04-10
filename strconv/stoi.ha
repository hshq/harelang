// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;
use types;

// Converts a string to an i64. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by an i64.
export fn stoi64(s: str, base: base = base::DEC) (i64 | invalid | overflow) = {
	let (sign, u) = parseint(s, base)?;
	// Two's complement: I64_MIN = -I64_MAX - 1
	let max = if (sign) types::I64_MAX: u64 + 1 else types::I64_MAX: u64;
	if (u > max) {
		return overflow;
	};
	return u: i64 * (if (sign) -1 else 1);
};

fn stoiminmax(
	s: str,
	base: base,
	min: i64,
	max: i64,
) (i64 | invalid | overflow) = {
	const n = stoi64(s, base)?;
	if (n < min || n > max) {
		return overflow;
	};
	return n;
};

// Converts a string to an i32. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by an i32.
export fn stoi32(s: str, base: base = base::DEC) (i32 | invalid | overflow) =
	stoiminmax(s, base, types::I32_MIN, types::I32_MAX)?: i32;

// Converts a string to an i16. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by an i16.
export fn stoi16(s: str, base: base = base::DEC) (i16 | invalid | overflow) =
	stoiminmax(s, base, types::I16_MIN, types::I16_MAX)?: i16;

// Converts a string to an i8. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by an i8.
export fn stoi8(s: str, base: base = base::DEC) (i8 | invalid | overflow) =
	stoiminmax(s, base, types::I8_MIN, types::I8_MAX)?: i8;

// Converts a string to an int. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by an int.
export fn stoi(s: str, base: base = base::DEC) (int | invalid | overflow) =
	stoiminmax(s, base, types::INT_MIN, types::INT_MAX)?: int;

@test fn stoi() void = {
	assert(stoi64("") as invalid == 0);
	assert(stoi64("abc") as invalid == 0);
	assert(stoi64("1a") as invalid == 1);
	assert(stoi64("+") as invalid == 1);
	assert(stoi64("-+") as invalid == 1);
	assert(stoi64("-z") as invalid == 1);

	assert(stoi64("9223372036854775808") is overflow);
	assert(stoi64("-9223372036854775809") is overflow);

	assert(stoi64("0") as i64 == 0);
	assert(stoi64("1") as i64 == 1);
	assert(stoi64("+1") as i64 == 1);
	assert(stoi64("-1") as i64 == -1);
	assert(stoi64("9223372036854775807") as i64 == types::I64_MAX);
	assert(stoi64("-9223372036854775808") as i64 == types::I64_MIN);

	assert(stoi32("2147483648") is overflow);
	assert(stoi32("-2147483649") is overflow);

	assert(stoi32("2147483647") as i32 == 2147483647);
	assert(stoi32("-2147483648") as i32 == -2147483648);
};

@test fn stoi_bases() void = {
	assert(stoi64("-7f", 16) as i64 == -0x7f);
	assert(stoi64("7F", 16) as i64 == 0x7f);
	assert(stoi64("37", 8) as i64 == 0o37);
	assert(stoi64("-110101", 2) as i64 == -0b110101);
};
