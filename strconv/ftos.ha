// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Uses Ryū for shortest, falls back to multiprecision for fixed precision.

use ascii;
use io;
use math;
use memio;
use strings;
use types;

// Format styles for the [[ftosf]] functions.
export type ffmt = enum {
	// General format. Uses whichever of E and F is shortest, not accounting
	// for flags.
	G,
	// Scientific notation. Consists of a number in [1, 10), an 'e' (or 'E',
	// if UPPER_EXP flag is present), then an exponent.
	E,
	// Fixed-point notation.
	F,
};

// Flags for the [[ftosf]] functions.
export type fflags = enum uint {
	NONE = 0,
	// Use a sign for both positive and negative numbers.
	SHOW_POS = 1 << 0,
	// Include at least one decimal digit.
	SHOW_POINT = 1 << 1,
	// Uppercase INFINITY and NAN.
	UPPERCASE = 1 << 2,
	// Uppercase exponent symbols E and P rather than e and p.
	UPPER_EXP = 1 << 3,
	// Use a sign for both positive and negative exponents.
	SHOW_POS_EXP = 1 << 4,
	// Show at least two digits of the exponent.
	SHOW_TWO_EXP_DIGITS = 1 << 5,
};

// Just for convenience... inline functions when?
fn ffpos(f: fflags) bool = f & fflags::SHOW_POS != 0;
fn ffpoint(f: fflags) bool = f & fflags::SHOW_POINT != 0;
fn ffcaps(f: fflags) bool = f & fflags::UPPERCASE != 0;
fn ffcaps_exp(f: fflags) bool = f & fflags::UPPER_EXP != 0;
fn ffpos_exp(f: fflags) bool = f & fflags::SHOW_POS_EXP != 0;
fn fftwodigs(f: fflags) bool = f & fflags::SHOW_TWO_EXP_DIGITS != 0;

fn declen(n: u64) uint = {
	assert(n <= 1e17);
	return if (n >= 1e17) 18
	else if (n >= 1e16) 17
	else if (n >= 1e15) 16
	else if (n >= 1e14) 15
	else if (n >= 1e13) 14
	else if (n >= 1e12) 13
	else if (n >= 1e11) 12
	else if (n >= 1e10) 11
	else if (n >= 1e9) 10
	else if (n >= 1e8) 9
	else if (n >= 1e7) 8
	else if (n >= 1e6) 7
	else if (n >= 1e5) 6
	else if (n >= 1e4) 5
	else if (n >= 1e3) 4
	else if (n >= 100) 3
	else if (n >= 10) 2
	else 1;
};

fn writestr(h: io::handle, s: str) (size | io::error) = {
	return io::writeall(h, strings::toutf8(s))?;
};

// XXX: this can likely be dedup'd with the other encode functions.
fn encode_zero(
	h: io::handle,
	f: ffmt,
	prec: (void | uint),
	flag: fflags,
) (size | io::error) = {
	let z = 0z;
	z += memio::appendrune(h, '0')?;
	let hasdec = false;
	match (prec) {
	case void => void;
	case let u: uint =>
		if (u > 0 && f != ffmt::G) {
			z += memio::appendrune(h, '.')?;
			for (let i = 0u; i < u; i += 1) {
				z += memio::appendrune(h, '0')?;
			};
			hasdec = true;
		};
	};
	if (!hasdec && ffpoint(flag)) {
		z += memio::appendrune(h, '.')?;
		z += memio::appendrune(h, '0')?;
	};
	if (f == ffmt::E) {
		z += memio::appendrune(h, if (ffcaps_exp(flag)) 'E' else 'e')?;
		if (ffpos_exp(flag)) z += memio::appendrune(h, '+')?;
		z += memio::appendrune(h, '0')?;
		if (fftwodigs(flag)) z += memio::appendrune(h, '0')?;
	};
	return z;
};

fn encode_f_mp(
	m: *mp,
	h: io::handle,
	f: ffmt,
	prec: (void | uint),
	flag: fflags,
) (size | io::error) = {
	// we will loop from lo <= i < hi, printing either zeros or a digit.
	// lo is simple, but hi depends intricately on f, prec, and the
	// SHOW_POINT flag.
	const lo = if (m.dp <= 0) m.dp - 1 else 0;
	let hi = match (prec) {
	case void =>
		yield if (m.nd: int > m.dp) m.nd: int else m.dp;
	case let u: uint =>
		yield if (m.dp <= 0) lo + u: int + 1 else m.dp + u: int;
	};
	// ffmt::G: we need to remove trailing zeros
	if (f == ffmt::G) {
		// first, make sure we include at least prec digits
		if (prec is uint) {
			const p = prec as uint;
			if (m.dp <= 0 && hi < p: int) {
				hi = p: int;
			};
		};
		// then, cut back to the decimal point or nd
		if (hi > m.nd: int && m.dp <= 0) {
			hi = m.nd: int;
		} else if (hi > m.dp && m.dp > 0) {
			hi = if (m.nd: int > m.dp) m.nd: int else m.dp;
		};
	};
	// SHOW_POINT: we need to go at least one past the decimal
	if (ffpoint(flag) && hi <= m.dp) {
		hi = m.dp + 1;
	};
	let z = 0z;
	for (let i = lo; i < hi; i += 1) {
		if (i == m.dp) {
			z += memio::appendrune(h, '.')?;
		};
		if (0 <= i && i < m.nd: int) {
			z += memio::appendrune(h, (m.buf[i] + '0'): rune)?;
		} else {
			z += memio::appendrune(h, '0')?;
		};
	};
	return z;
};

fn encode_e_mp(
	m: *mp,
	h: io::handle,
	f: ffmt,
	prec: (void | uint),
	flag: fflags,
) (size | io::error) = {
	let z = 0z;
	assert(m.nd > 0);
	z += memio::appendrune(h, (m.buf[0] + '0'): rune)?;
	const zeros: uint = match (prec) {
	case void =>
		yield 0;
	case let u: uint =>
		yield switch (f) {
		case ffmt::G =>
			yield if (m.nd + 1 < u) u - m.nd + 1 else 0;
		case ffmt::E =>
			yield if (m.nd < u + 1) u - m.nd + 1 else 0;
		case => abort();
		};
	};
	if (m.nd <= 1 && ffpoint(flag) && zeros < 1) {
		zeros = 1;
	};
	if (m.nd > 1 || zeros > 0) {
		z += memio::appendrune(h, '.')?;
	};
	for (let i = 1z; i < m.nd; i += 1) {
		z += memio::appendrune(h, (m.buf[i] + '0'): rune)?;
	};
	for (let i = 0u; i < zeros; i += 1) {
		z += memio::appendrune(h, '0')?;
	};
	z += memio::appendrune(h, if (ffcaps_exp(flag)) 'E' else 'e')?;
	let e = m.dp - 1;
	if (e < 0) {
		e = -e;
		z += memio::appendrune(h, '-')?;
	} else if (ffpos_exp(flag)) {
		z += memio::appendrune(h, '+')?;
	};
	let ebuf: [3]u8 = [0...]; // max and min exponents are 3 digits
	let l = declen(e: u64);
	for (let i = 0z; i < l; i += 1) {
		ebuf[2 - i] = (e % 10): u8;
		e /= 10;
	};
	if (fftwodigs(flag) && l == 1) {
		l = 2;
	};
	for (let i = 3 - l; i < 3; i += 1) {
		z += memio::appendrune(h, (ebuf[i] + '0'): rune)?;
	};
	return z;
};

// Converts a [[types::floating]] to a string in base 10 and writes the result
// to the provided handle. Format parameters are as in [[ftosf]].
export fn fftosf(
	h: io::handle,
	n: types::floating,
	f: ffmt,
	prec: (void | uint),
	flag: fflags,
) (size | io::error) = {
	const (mantissa, exponent, sign, special) = match (n) {
	case let n: f64 =>
		const bits = math::f64bits(n);
		const mantissa = bits & math::F64_MANTISSA_MASK;
		const exponent = ((bits >> math::F64_MANTISSA_BITS) &
			math::F64_EXPONENT_MASK): u32;
		const sign = bits >> (math::F64_EXPONENT_BITS +
			math::F64_MANTISSA_BITS) > 0;
		const special = exponent == math::F64_EXPONENT_MASK;
		yield (mantissa, exponent, sign, special);
	case let n: f32 =>
		const bits = math::f32bits(n);
		const mantissa = bits & math::F32_MANTISSA_MASK;
		const exponent = ((bits >> math::F32_MANTISSA_BITS) &
			math::F32_EXPONENT_MASK): u32;
		const sign = bits >> (math::F32_EXPONENT_BITS +
			math::F32_MANTISSA_BITS) > 0;
		const special = exponent == math::F32_EXPONENT_MASK;
		yield (mantissa, exponent, sign, special);
	};

	if (special && mantissa != 0) {
		return writestr(h, if (ffcaps(flag)) "NAN" else "nan");
	};

	let z = 0z;
	if (sign) {
		z += memio::appendrune(h, '-')?;
	} else if (ffpos(flag)) {
		z += memio::appendrune(h, '+')?;
	};

	if (special) {
		return z + writestr(h,
			if (ffcaps(flag)) "INFINITY" else "infinity")?;
	} else if (exponent == 0 && mantissa == 0) {
		return z + encode_zero(h, f, prec, flag)?;
	};

	let m = mp { ... };
	let ok = false;
	if (prec is void) {
		// Shortest via Ryū. It is not correct to use f64todecf64 for
		// f32s, they must be handled separately.
		const (mdec, edec) = match (n) {
		case f64 =>
			const d = f64todecf64(mantissa, exponent);
			yield (d.mantissa, d.exponent);
		case f32 =>
			const d = f32todecf32(mantissa: u32, exponent);
			yield (d.mantissa: u64, d.exponent);
		};
		init_mp_dec(&m, mdec, edec);
		// If SHOW_POINT and we have too few digits, then we need to
		// fall back to multiprecision.
		ok = !ffpoint(flag) || m.dp < m.nd: int;
	};

	if (!ok) {
		// Fall back to multiprecision.
		match (n) {
		case f64 =>
			init_mp(&m, mantissa, exponent, math::F64_EXPONENT_BIAS,
				math::F64_MANTISSA_BITS);
		case f32 =>
			init_mp(&m, mantissa, exponent, math::F32_EXPONENT_BIAS,
				math::F32_MANTISSA_BITS);
		};
		trim_mp(&m);
		const nd = compute_round_mp(&m, f, prec, flag);
		round_mp(&m, nd);
	};

	if (f == ffmt::G) {
		trim_mp(&m);
	};

	if (f == ffmt::G && prec is uint) {
		if (prec as uint == 0) prec = 1;
	};

	if (m.nd == 0) {
		// rounded to zero
		return z + encode_zero(h, f, prec, flag)?;
	} else if (f == ffmt::E || (f == ffmt::G &&
			(m.dp < -1 || m.dp - m.nd: int > 2))) {
		return z + encode_e_mp(&m, h, f, prec, flag)?;
	} else {
		return z + encode_f_mp(&m, h, f, prec, flag)?;
	};
};

// Converts any [[types::floating]] to a string in base 10. The return value
// must be freed.
//
// A precision of void yields the smallest number of digits that can be parsed
// into the exact same number. Otherwise, the meaning depends on f:
// - ffmt::F, ffmt::E: Number of digits after the decimal point.
// - ffmt::G: Number of significant digits. 0 is equivalent to 1 precision, and
//   trailing zeros are removed.
export fn ftosf(
	n: types::floating,
	f: ffmt,
	prec: (void | uint),
	flag: fflags,
) str = {
	let m = memio::dynamic();
	fftosf(&m, n, f, prec, flag)!;
	return memio::string(&m)!;
};

// Converts a f64 to a string in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. The result is equivalent to [[ftosf]] with format G
// and precision void.
export fn f64tos(n: f64) const str = {
	// The biggest string produced by a f64 number in base 10 would have the
	// negative sign, followed by a digit and decimal point, and then
	// sixteen more decimal digits, followed by 'e' and another negative
	// sign and the maximum of three digits for exponent.
	// (1 + 1 + 1 + 16 + 1 + 1 + 3) = 24
	static let buf: [24]u8 = [0...];
	let m = memio::fixed(buf);
	fftosf(&m, n, ffmt::G, void, 0)!;
	return memio::string(&m)!;
};

// Converts a f32 to a string in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]]
// to duplicate the result. The result is equivalent to [[ftosf]] with format G
// and precision void.
export fn f32tos(n: f32) const str = {
	// The biggest string produced by a f32 number in base 10 would have the
	// negative sign, followed by a digit and decimal point, and then seven
	// more decimal digits, followed by 'e' and another negative sign and
	// the maximum of two digits for exponent.
	// (1 + 1 + 1 + 7 + 1 + 1 + 2) = 14
	static let buf: [14]u8 = [0...];
	let m = memio::fixed(buf);
	fftosf(&m, n, ffmt::G, void, 0)!;
	return memio::string(&m)!;
};
