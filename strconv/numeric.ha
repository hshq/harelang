// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Converts any [[types::signed]] to a string in a given base. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn signedtosb(n: types::signed, b: base) const str = {
	match (n) {
	case let i: int =>
		return itosb(i, b);
	case let i: i8 =>
		return i8tosb(i, b);
	case let i: i16 =>
		return i16tosb(i, b);
	case let i: i32 =>
		return i32tosb(i, b);
	case let i: i64 =>
		return i64tosb(i, b);
	};
};

// Converts any [[types::signed]] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn signedtos(n: types::signed) const str = signedtosb(n, base::DEC);

// Converts any [[types::unsigned]] to a string in a given base. The return value
// is statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn unsignedtosb(n: types::unsigned, b: base) const str = {
	match (n) {
	case let u: size =>
		return ztosb(u, b);
	case let u: uint =>
		return utosb(u, b);
	case let u: u8 =>
		return u8tosb(u, b);
	case let u: u16 =>
		return u16tosb(u, b);
	case let u: u32 =>
		return u32tosb(u, b);
	case let u: u64 =>
		return u64tosb(u, b);
	};
};

// Converts any [[types::unsigned]] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn unsignedtos(n: types::unsigned) const str = unsignedtosb(n, base::DEC);

// Converts any [[types::integer]] to a string in a given base. The return value
// is statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn integertosb(n: types::integer, b: base) const str = {
	match (n) {
	case let s: types::signed =>
		return signedtosb(s, b);
	case let u: types::unsigned =>
		return unsignedtosb(u, b);
	};
};

// Converts any [[types::integer]] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn integertos(n: types::integer) const str = integertosb(n, base::DEC);

// Converts any [[types::floating]] to a string in a given base. The return value
// is statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn floatingtosb(n: types::floating, b: base) const str = {
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

// Converts any [[types::floating]] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn floatingtos(n: types::floating) const str = floatingtosb(n, base::DEC);

// Converts any [[types::numeric]] to a string in a given base. The return value
// is statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn numerictosb(n: types::numeric, b: base) const str = {
	match (n) {
	case let i: types::integer =>
		return integertosb(i, b);
	case let f: types::floating =>
		return floatingtosb(f, b);
	};
};

// Converts any [[types::numeric]] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [[strings::dup]] to duplicate the result.
export fn numerictos(n: types::numeric) const str = numerictosb(n, base::DEC);

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
