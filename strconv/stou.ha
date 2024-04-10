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

// Converts a string to a u64. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by a u64.
export fn stou64(s: str, base: base = base::DEC) (u64 | invalid | overflow) = {
	let (sign, u) = parseint(s, base)?;
	if (sign) {
		return overflow;
	};
	return u;
};

fn stoumax(s: str, base: base, max: u64) (u64 | invalid | overflow) = {
	const n = stou64(s, base)?;
	if (n > max) {
		return overflow;
	};
	return n;
};

// Converts a string to a u32. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by a u32.
export fn stou32(s: str, base: base = base::DEC) (u32 | invalid | overflow) =
	stoumax(s, base, types::U32_MAX)?: u32;

// Converts a string to a u16. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by a u16.
export fn stou16(s: str, base: base = base::DEC) (u16 | invalid | overflow) =
	stoumax(s, base, types::U16_MAX)?: u16;

// Converts a string to a u8. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by a u8.
export fn stou8(s: str, base: base = base::DEC) (u8 | invalid | overflow) =
	stoumax(s, base, types::U8_MAX)?: u8;

// Converts a string to a uint in the given base. Returns [[invalid]] if the
// string is empty or contains invalid characters. Returns [[overflow]] if the
// number is too large to be represented by a uint.
export fn stou(s: str, base: base = base::DEC) (uint | invalid | overflow) =
	stoumax(s, base, types::UINT_MAX)?: uint;

// Converts a string to a size. Returns [[invalid]] if the string is empty or
// contains invalid characters. Returns [[overflow]] if the number is too large
// to be represented by a size.
export fn stoz(s: str, base: base = base::DEC) (size | invalid | overflow) =
	stoumax(s, base, types::SIZE_MAX)?: size;

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

@test fn stou_bases() void = {
	assert(stou64("7f", 16) as u64 == 0x7f);
	assert(stou64("7F", 16) as u64 == 0x7f);
	assert(stou64("37", 8) as u64 == 0o37);
	assert(stou64("110101", 2) as u64 == 0b110101);
};
