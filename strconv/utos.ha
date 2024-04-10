// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use types;

// Converts a u64 to a string. The return value is statically allocated and will
// be overwritten on subsequent calls; see [[strings::dup]] to duplicate the
// result.
export fn u64tos(u: u64, b: base = base::DEC) const str = {
	static assert(types::U64_MAX == 18446744073709551615);
	static let buf: [64]u8 = [0...]; // 64 binary digits

	static const lut_upper = [
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
	], lut_lower = [
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
	];
	const lut = if (b != base::HEX_LOWER) &lut_upper else {
		b = base::HEX_UPPER;
		yield &lut_lower;
	};

	const b: uint = if (b == base::DEFAULT) base::DEC else b;

	let s = types::string { data = &buf, ... };
	if (u == 0) {
		buf[s.length] = '0';
		s.length += 1z;
	};

	for (u > 0u64) {
		buf[s.length] = lut[u % b: u64]: u8;
		s.length += 1;
		u /= b;
	};

	bytes::reverse(buf[..s.length]);
	return *(&s: *str);
};

// Converts a u32 to a string. The return value is statically allocated and will
// be overwritten on subsequent calls; see [[strings::dup]] to duplicate the
// result.
export fn u32tos(u: u32, b: base = base::DEC) const str = u64tos(u, b);

// Converts a u16 to a string. The return value is statically allocated and will
// be overwritten on subsequent calls; see [[strings::dup]] to duplicate the
// result.
export fn u16tos(u: u16, b: base = base::DEC) const str = u64tos(u, b);

// Converts a u8 to a string. The return value is statically allocated and will
// be overwritten on subsequent calls; see [[strings::dup]] to duplicate the
// result.
export fn u8tos(u: u8, b: base = base::DEC) const str = u64tos(u, b);

// Converts a uint to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn utos(u: uint, b: base = base::DEC) const str = u64tos(u, b);

// Converts a size to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn ztos(u: size, b: base = base::DEC) const str = u64tos(u, b);

// Converts a uintptr to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn uptrtos(uptr: uintptr, b: base = base::DEC) const str = u64tos(uptr: u64, b);

@test fn utos_bases() void = {
	assert("11010" == u64tos(0b11010, base::BIN));
	assert("1234567" == u64tos(0o1234567, base::OCT));
	assert("123456789" == u64tos(123456789, base::DEC));
	assert("123456789ABCDEF" == u64tos(0x123456789ABCDEF, base::HEX));
	assert("123456789ABCDEF" == u64tos(0x123456789ABCDEF, base::HEX_UPPER));
	assert("123456789abcdef" == u64tos(0x123456789ABCDEF, base::HEX_LOWER));
	assert("1111111111111111111111111111111111111111111111111111111111111111"
		== u64tos(types::U64_MAX, base::BIN));
};

@test fn utos() void = {
	const samples: [_]u64 = [
		1234,
		4321,
		types::U64_MIN,
		types::U64_MAX,
	];
	const expected = [
		"1234",
		"4321",
		"0",
		"18446744073709551615",
	];

	for (let i = 0z; i < len(samples); i += 1) {
		const s = u64tos(samples[i]);
		assert(s == expected[i]);
	};
};
