// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Converts any [[types::signed]] to a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. If base is not specified, base 10 is used.
export fn signedtos(n: types::signed, b: base = base::DEC) const str = {
	match (n) {
	case let i: int =>
		return itos(i, b);
	case let i: i8 =>
		return i8tos(i, b);
	case let i: i16 =>
		return i16tos(i, b);
	case let i: i32 =>
		return i32tos(i, b);
	case let i: i64 =>
		return i64tos(i, b);
	};
};

// Converts any [[types::unsigned]] to a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. If base is not specified, base 10 is used.
export fn unsignedtos(n: types::unsigned, b: base = base::DEC) const str = {
	match (n) {
	case let u: size =>
		return ztos(u, b);
	case let u: uint =>
		return utos(u, b);
	case let u: u8 =>
		return u8tos(u, b);
	case let u: u16 =>
		return u16tos(u, b);
	case let u: u32 =>
		return u32tos(u, b);
	case let u: u64 =>
		return u64tos(u, b);
	};
};

// Converts any [[types::integer]] to a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. If base is not specified, base 10 is used.
export fn integertos(n: types::integer, b: base = base::DEC) const str = {
	match (n) {
	case let s: types::signed =>
		return signedtos(s, b);
	case let u: types::unsigned =>
		return unsignedtos(u, b);
	};
};

// Converts any [[types::floating]] to a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. If base is not specified, base 10 is used.
export fn floatingtos(n: types::floating, b: base = base::DEC) const str = {
	if (b == base::DEFAULT) {
		b = base::DEC;
	};
	assert(b == base::DEC);
	match (n) {
	case let f: f32 =>
		return f32tos(f);
	case let f: f64 =>
		return f64tos(f);
	};
};

// Converts any [[types::numeric]] to a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. If base is not specified, base 10 is used.
export fn numerictos(n: types::numeric, b: base = base::DEC) const str = {
	match (n) {
	case let i: types::integer =>
		return integertos(i, b);
	case let f: types::floating =>
		return floatingtos(f, b);
	};
};

@test fn numeric() void = {
	const cases: [_]types::numeric = [
		42u8, 1337u16, 1337u32, 1337u64, 42i8, -42i8, 1337i16, -1337i16,
		1337i32, -1337i32, 1337i64, -1337i64, 1337i, -1337i, 1337u,
		-1337i,
	];
	const expected = [
		"42", "1337", "1337", "1337", "42", "-42", "1337", "-1337",
		"1337", "-1337", "1337", "-1337", "1337", "-1337", "1337",
		"-1337",
	];
	for (let i = 0z; i < len(cases); i += 1) {
		assert(numerictos(cases[i]) == expected[i]);
	};
};
