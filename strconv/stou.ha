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

fn parseint(s: str, base: base) ((bool, u64) | invalid | overflow) = {
	if (base == base::DEFAULT) {
		base = base::DEC;
	};
	assert(base == 2 || base == 8 || base == 10 || base == 16);

	if (len(s) == 0) {
		return 0: invalid;
	};

	let buf = strings::toutf8(s);
	let i = 0z;

	let sign = buf[i] == '-';
	if (sign || buf[i] == '+') {
		i += 1;
	};

	// Require at least one digit.
	if (i == len(buf)) {
		return i: invalid;
	};

	let n = 0u64;
	for (i < len(buf); i += 1) {
		const digit = match (rune_to_integer(buf[i]: rune)) {
		case void =>
			return i: invalid;
		case let d: u64 =>
			yield d;
		};

		if (digit >= base) {
			return i: invalid;
		};

		const old = n;

		n *= base;
		n += digit;

		if (n < old) {
			return overflow;
		};
	};
	return (sign, n);
};

// Converts a string to a u64 in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a u64.
export fn stou64b(s: str, base: base) (u64 | invalid | overflow) = {
	let (sign, u) = parseint(s, base)?;
	if (sign) {
		return overflow;
	};
	return u;
};

fn stoumax(s: str, base: base, max: u64) (u64 | invalid | overflow) = {
	const n = stou64b(s, base)?;
	if (n > max) {
		return overflow;
	};
	return n;
};

// Converts a string to a u32 in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a u32.
export fn stou32b(s: str, base: base) (u32 | invalid | overflow) =
	stoumax(s, base, types::U32_MAX)?: u32;

// Converts a string to a u16 in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a u16.
export fn stou16b(s: str, base: base) (u16 | invalid | overflow) =
	stoumax(s, base, types::U16_MAX)?: u16;

// Converts a string to a u8 in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a u8.
export fn stou8b(s: str, base: base) (u8 | invalid | overflow) =
	stoumax(s, base, types::U8_MAX)?: u8;

// Converts a string to a uint in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a uint.
export fn stoub(s: str, base: base) (uint | invalid | overflow) =
	stoumax(s, base, types::UINT_MAX)?: uint;

// Converts a string to a size in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a size.
export fn stozb(s: str, base: base) (size | invalid | overflow) =
	stoumax(s, base, types::SIZE_MAX)?: size;

// Converts a string to a u64 in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a u64.
export fn stou64(s: str) (u64 | invalid | overflow) = stou64b(s, base::DEC);

// Converts a string to a u32 in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a u32.
export fn stou32(s: str) (u32 | invalid | overflow) = stou32b(s, base::DEC);

// Converts a string to a u16 in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a u16.
export fn stou16(s: str) (u16 | invalid | overflow) = stou16b(s, base::DEC);

// Converts a string to a u8 in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a u8.
export fn stou8(s: str) (u8 | invalid | overflow) = stou8b(s, base::DEC);

// Converts a string to a uint in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a uint.
export fn stou(s: str) (uint | invalid | overflow) = stoub(s, base::DEC);

// Converts a string to a size in base 10. Returns [[invalid]] if the string is
// empty or contains invalid characters. Returns [[overflow]] if the number is
// too large to be represented by a size.
export fn stoz(s: str) (size | invalid | overflow) = stozb(s, base::DEC);

@test fn stou() void = {
	assert(stou64("") as invalid == 0);
	assert(stou64("+") as invalid == 1);
	assert(stou64("+a") as invalid == 1);
	assert(stou64("abc") as invalid == 0);
	assert(stou64("1a") as invalid == 1);

	assert(stou64("18446744073709551616") is overflow);
	assert(stou64("184467440737095516150") is overflow);
	assert(stou64("-1") is overflow);

	assert(stou64("0") as u64 == 0);
	assert(stou64("1") as u64 == 1);
	assert(stou64("18446744073709551615") as u64 == 18446744073709551615);
};

@test fn stoub() void = {
	assert(stou64b("7f", 16) as u64 == 0x7f);
	assert(stou64b("7F", 16) as u64 == 0x7f);
	assert(stou64b("37", 8) as u64 == 0o37);
	assert(stou64b("110101", 2) as u64 == 0b110101);
};
