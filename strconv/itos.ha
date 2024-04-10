// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use strings;
use types;

// Converts an i64 to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn i64tos(i: i64, b: base = base::DEC) const str = {
	static assert(types::I64_MAX == 9223372036854775807);
	if (b == base::DEFAULT) {
		b = base::DEC;
	};

	if (i >= 0) return u64tos(i: u64, b);

	static let buf: [65]u8 = [0...]; // 64 binary digits plus -

	let s = types::string { data = &buf, ... };

	buf[0] = '-';
	s.length = 1;

	let u = strings::toutf8(u64tos((-i): u64, b));
	assert(len(u) < len(buf));

	buf[1..len(u) + 1] = u[..];
	s.length += len(u);

	return *(&s: *str);
};

// Converts an i32 to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn i32tos(i: i32, b: base = base::DEC) const str = i64tos(i, b);

// Converts an i16 to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn i16tos(i: i16, b: base = base::DEC) const str = i64tos(i, b);

// Converts an i8 to a string. The return value is statically allocated and will
// be overwritten on subsequent calls; see [[strings::dup]] to duplicate the
// result.
export fn i8tos(i: i8, b: base = base::DEC) const str = i64tos(i, b);

// Converts an int to a string. The return value is statically allocated and
// will be overwritten on subsequent calls; see [[strings::dup]] to duplicate
// the result.
export fn itos(i: int, b: base = base::DEC) const str = i64tos(i, b);

@test fn itos_bases() void = {
	assert("11010" == i64tos(0b11010, base::BIN));
	assert("1234567" == i64tos(0o1234567, base::OCT));
	assert("123456789" == i64tos(123456789, base::DEC));
	assert("123456789ABCDEF" == i64tos(0x123456789ABCDEF, base::HEX));
	assert("123456789ABCDEF" == i64tos(0x123456789ABCDEF, base::HEX_UPPER));
	assert("123456789abcdef" == i64tos(0x123456789ABCDEF, base::HEX_LOWER));
	assert("-1000000000000000000000000000000000000000000000000000000000000000"
		== i64tos(types::I64_MIN, base::BIN));
};

@test fn itos() void = {
	const samples: [_]i64 = [
		1234,
		4321,
		-1337,
		0,
		types::I64_MAX,
		types::I64_MIN,
	];
	const expected = [
		"1234",
		"4321",
		"-1337",
		"0",
		"9223372036854775807",
		"-9223372036854775808",
	];

	for (let i = 0z; i < len(samples); i += 1) {
		const s = i64tos(samples[i]);
		assert(s == expected[i]);
	};
};
