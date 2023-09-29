// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Returns the binary representation of the given f64.
export fn f64bits(n: f64) u64 = *(&n: *u64);

// Returns the binary representation of the given f32.
export fn f32bits(n: f32) u32 = *(&n: *u32);

// Returns f64 with the given binary representation.
export fn f64frombits(n: u64) f64 = *(&n: *f64);

// Returns f32 with the given binary representation.
export fn f32frombits(n: u32) f32 = *(&n: *f32);

// The number of bits in the significand of the binary representation of f64.
export def F64_MANTISSA_BITS: u64 = 52;

// The number of bits in the exponent of the binary representation of f64.
export def F64_EXPONENT_BITS: u64 = 11;

// The bias of the exponent of the binary representation of f64. Subtract this
// from the exponent in the binary representation to get the actual exponent.
export def F64_EXPONENT_BIAS: u16 = 1023;

// The number of bits in the significand of the binary representation of f32.
export def F32_MANTISSA_BITS: u64 = 23;

// The number of bits in the exponent of the binary representation of f32.
export def F32_EXPONENT_BITS: u64 = 8;

// The bias of the exponent of the binary representation of f32. Subtract this
// from the exponent in the binary representation to get the actual exponent.
export def F32_EXPONENT_BIAS: u16 = 127;

// Mask with each bit of an f64's mantissa set.
export def F64_MANTISSA_MASK: u64 = (1 << F64_MANTISSA_BITS) - 1;

// Mask with each bit of an f64's exponent set.
export def F64_EXPONENT_MASK: u64 = (1 << F64_EXPONENT_BITS) - 1;

// Mask with each bit of an f32's mantissa set.
export def F32_MANTISSA_MASK: u64 = (1 << F32_MANTISSA_BITS) - 1;

// Mask with each bit of an f32's exponent set.
export def F32_EXPONENT_MASK: u64 = (1 << F32_EXPONENT_BITS) - 1;

// The largest representable f64 value which is less than Infinity.
export def F64_MAX_NORMAL: f64 = 1.7976931348623157e+308;

// The smallest representable normal f64 value.
export def F64_MIN_NORMAL: f64 = 2.2250738585072014e-308;

// The smallest (subnormal) f64 value greater than zero.
export def F64_MIN: f64 = 5.0e-324;

// The difference between 1 and the smallest f64 representable value that is
// greater than 1.
export def F64_EPS: f64 = 2.22040000000000004884e-16;

// The largest representable f32 value which is less than Infinity.
export def F32_MAX_NORMAL: f32 = 3.4028234e+38;

// The smallest representable normal f32 value.
export def F32_MIN_NORMAL: f32 = 1.1754944e-38;

// The smallest (subnormal) f32 value greater than zero.
export def F32_MIN: f32 = 1.0e-45;

// The difference between 1 and the smallest f32 representable value that is
// greater than 1.
export def F32_EPS: f32 = 1.1920928955078125e-7;

// The mask that gets an f64's sign.
def F64_SIGN_MASK: u64 = 1u64 << 63;

// The mask that sets all exponent bits to 0.
// NOTE: Replace with the following expression once the lexer supports it
// 0u64 & ~(F64_EXPONENT_MASK << F64_MANTISSA_BITS);
def F64_EXP_REMOVAL_MASK: u64 =
	0b1000000000001111111111111111111111111111111111111111111111111111;

// The f64 that contains only an exponent that evaluates to zero.
def F64_EXP_ZERO: u64 = ((F64_EXPONENT_BIAS: u64) - 1) << F64_MANTISSA_BITS;

// The mask that gets an f32's sign.
def F32_SIGN_MASK: u32 = 1u32 << 31;

// The mask that sets all exponent bits to 0.
// NOTE: Replace with the following expression once the lexer supports it
// 0u32 & ~(F32_EXPONENT_MASK << F32_MANTISSA_BITS);
def F32_EXP_REMOVAL_MASK: u32 = 0b10000000011111111111111111111111;

// The f32 that contains only an exponent that evaluates to zero.
def F32_EXP_ZERO: u32 =
	((F32_EXPONENT_BIAS: u32) - 1) << (F32_MANTISSA_BITS: u32);

// The bits that represent the number 1f64.
def F64_ONE: u64 = 0x3FF0000000000000;

// Contains information about the structure of a specific floating point number
// type.
export type floatinfo = struct {
	// Bits in significand.
	mantbits: u64,
	// Bits in exponent.
	expbits: u64,
	// Bias of exponent.
	expbias: int,
	// Mask for mantissa.
	mantmask: u64,
	// Mask for exponent.
	expmask: u64,
};

// A [[floatinfo]] structure defining the structure of the f64 type.
export const f64info: floatinfo = floatinfo {
	mantbits = 52,
	expbits = 11,
	expbias = 1023,
	mantmask = (1 << 52) - 1,
	expmask = (1 << 11) - 1,
};

// A [[floatinfo]] structure defining the structure of the f32 type.
export const f32info: floatinfo = floatinfo {
	mantbits = 23,
	expbits = 8,
	expbias = 127,
	mantmask = (1 << 23) - 1,
	expmask = (1 << 8) - 1,
};

// The floating point value representing Not a Number, i.e. an undefined or
// unrepresentable value. You cannot test if a number is NaN by comparing to
// this value; see [[isnan]] instead.
export def NAN: f32 = 0.0 / 0.0;

// The floating point value representing positive infinity. Use -[[INF]] for
// negative infinity.
export def INF: f32 = 1.0 / 0.0;

// Returns true if the given floating-point number is NaN.
export fn isnan(n: f64) bool = n != n;

// Returns true if the given floating-point number is infinite.
export fn isinf(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp == F64_EXPONENT_MASK && mant == 0;
};

@test fn isinf() void = {
	assert(isinf(INF));
	assert(isinf(-INF));
	assert(!isinf(NAN));
	assert(!isinf(1.23));
	assert(!isinf(-1.23f32));
};

// Returns true if the given floating-point number is normal.
export fn isnormal(n: types::floating) bool = {
	match (n) {
	case let n: f32 =>
		return isnormalf32(n);
	case let n: f64 =>
		return isnormalf64(n);
	};
};

// Returns true if the given f64 is normal.
export fn isnormalf64(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp != F64_EXPONENT_MASK && (exp > 0 || mant == 0);
};

// Returns true if the given f32 is normal.
export fn isnormalf32(n: f32) bool = {
	const bits = f32bits(n);
	const mant = bits & F32_MANTISSA_MASK;
	const exp = bits >> F32_MANTISSA_BITS & F32_EXPONENT_MASK;
	return exp != F32_EXPONENT_MASK && (exp > 0 || mant == 0);
};

// Returns true if the given floating-point number is subnormal.
export fn issubnormal(n: types::floating) bool = {
	match (n) {
	case let n: f32 =>
		return issubnormalf32(n);
	case let n: f64 =>
		return issubnormalf64(n);
	};
};

// Returns true if the given f64 is subnormal.
export fn issubnormalf64(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp == 0 && mant != 0;
};

// Returns true if the given f32 is subnormal.
export fn issubnormalf32(n: f32) bool = {
	const bits = f32bits(n);
	const mant = bits & F32_MANTISSA_MASK;
	const exp = bits >> F32_MANTISSA_BITS & F32_EXPONENT_MASK;
	return exp == 0 && mant != 0;
};

// Returns the absolute value of f64 n.
export fn absf64(n: f64) f64 = {
	if (isnan(n)) {
		return n;
	};
	return f64frombits(f64bits(n) & ~F64_SIGN_MASK);
};

// Returns the absolute value of f32 n.
export fn absf32(n: f32) f32 = {
	if (isnan(n)) {
		return n;
	};
	return f32frombits(f32bits(n) & ~F32_SIGN_MASK);
};

// Returns the absolute value of floating-point number n.
export fn absf(n: types::floating) f64 = {
	match (n) {
	case let n: f64 =>
		return absf64(n);
	case let n: f32 =>
		return (absf32(n): f64);
	};
};

// Returns 1 if x is positive and -1 if x is negative. Note that zero is also
// signed.
export fn signf64(x: f64) i64 = {
	if (f64bits(x) & F64_SIGN_MASK == 0) {
		return 1i64;
	} else {
		return -1i64;
	};
};

// Returns 1 if x is positive and -1 if x is negative. Note that zero is also
// signed.
export fn signf32(x: f32) i64 = {
	if (f32bits(x) & F32_SIGN_MASK == 0) {
		return 1i64;
	} else {
		return -1i64;
	};
};

// Returns 1 if x is positive and -1 if x is negative. Note that zero is also
// signed.
export fn signf(x: types::floating) i64 = {
	match (x) {
	case let n: f64 =>
		return signf64(n);
	case let n: f32 =>
		return signf32(n);
	};
};

// Returns whether or not x is positive.
export fn ispositivef64(x: f64) bool = signf64(x) == 1i64;

// Returns whether or not x is positive.
export fn ispositivef32(x: f32) bool = signf32(x) == 1i32;

// Returns whether or not x is positive.
export fn ispositive(x: types::floating) bool = {
	match (x) {
	case let n: f64 =>
		return ispositivef64(n);
	case let n: f32 =>
		return ispositivef32(n);
	};
};

// Returns whether or not x is negative.
export fn isnegativef64(x: f64) bool = signf64(x) == -1i64;

// Returns whether or not x is negative.
export fn isnegativef32(x: f32) bool = signf32(x) == -1i32;

// Returns whether or not x is negative.
export fn isnegative(x: types::floating) bool = {
	match (x) {
	case let n: f64 =>
		return isnegativef64(n);
	case let n: f32 =>
		return isnegativef32(n);
	};
};

// Returns x, but with the sign of y.
export fn copysignf64(x: f64, y: f64) f64 = {
	return f64frombits((f64bits(x) & ~F64_SIGN_MASK) |
		(f64bits(y) & F64_SIGN_MASK));
};

// Returns x, but with the sign of y.
export fn copysignf32(x: f32, y: f32) f32 = {
	return f32frombits((f32bits(x) & ~F32_SIGN_MASK) |
		(f32bits(y) & F32_SIGN_MASK));
};

// Returns x, but with the sign of y.
export fn copysign(x: types::floating, y: types::floating) f64 = {
	match (x) {
	case let n: f64 =>
		return copysignf64(n, (y: f64));
	case let n: f32 =>
		return (copysignf32(n, (y: f32)): f64);
	};
};

// Takes a potentially subnormal f64 n and returns a normal f64 normal_float
// and an exponent exp such that n == normal_float * 2^{exp}.
export fn normalizef64(n: f64) (f64, i64) = {
	if (issubnormalf64(n)) {
		const factor = 1i64 << (F64_MANTISSA_BITS: i64);
		const normal_float = (n * (factor: f64));
		return (normal_float, -(F64_MANTISSA_BITS: i64));
	};
	return (n, 0);
};

// Takes a potentially subnormal f32 n and returns a normal f32 normal_float
// and an exponent exp such that n == normal_float * 2^{exp}.
export fn normalizef32(n: f32) (f32, i64) = {
	if (issubnormalf32(n)) {
		const factor = 1i32 << (F32_MANTISSA_BITS: i32);
		const normal_float = n * factor: f32;
		return (normal_float, -(F32_MANTISSA_BITS: i64));
	};
	return (n, 0);
};

// Breaks a f64 down into its mantissa and exponent. The mantissa will be
// between 0.5 and 1.
export fn frexpf64(n: f64) (f64, i64) = {
	if (isnan(n) || isinf(n) || n == 0f64) {
		return (n, 0);
	};
	const normalized = normalizef64(n);
	const normal_float = normalized.0;
	const normalization_exp = normalized.1;
	const bits = f64bits(normal_float);
	const raw_exp: u64 = (bits >> F64_MANTISSA_BITS) & F64_EXPONENT_MASK;
	const exp: i64 = normalization_exp +
		(raw_exp: i64) - (F64_EXPONENT_BIAS: i64) + 1;
	const mantissa: f64 =
		f64frombits((bits & F64_EXP_REMOVAL_MASK) | F64_EXP_ZERO);
	return (mantissa, exp);
};

// Breaks a f32 down into its mantissa and exponent. The mantissa will be
// between 0.5 and 1.
export fn frexpf32(n: f32) (f32, i64) = {
	if (isnan(n) || isinf(n) || n == 0f32) {
		return (n, 0);
	};
	const normalized = normalizef32(n);
	const normal_float = normalized.0;
	const normalization_exp = normalized.1;
	const bits = f32bits(normal_float);
	const raw_exp: u64 = ((bits >> (F32_MANTISSA_BITS: u32)) &
		(F32_EXPONENT_MASK: u32));
	const exp: i64 = normalization_exp +
		(raw_exp: i64) - (F32_EXPONENT_BIAS: i64) + 1;
	const mantissa: f32 =
		f32frombits((bits & F32_EXP_REMOVAL_MASK) | F32_EXP_ZERO);
	return (mantissa, exp);
};

// Breaks a float down into its mantissa and exponent. The mantissa will be
// between 0.5 and 1.
export fn frexp(n: types::floating) (f64, i64) = {
	match (n) {
	case let n: f64 =>
		return frexpf64(n);
	case let n: f32 =>
		let (mantissa, exp) = frexpf32(n);
		return (mantissa, exp);
	};
};

// Creates an f64 from a mantissa and an exponent.
export fn ldexpf64(mantissa: f64, exp: i64) f64 = {
	if (isnan(mantissa) || isinf(mantissa) || mantissa == 0f64) {
		return mantissa;
	};
	const normalized = normalizef64(mantissa);
	const normal_float = normalized.0;
	const normalization_exp = normalized.1;
	const bits = f64bits(normal_float);
	const mantissa_exp =
		(((bits >> F64_MANTISSA_BITS) & F64_EXPONENT_MASK): i64) -
		(F64_EXPONENT_BIAS: i64);
	let res_exp = exp + normalization_exp + mantissa_exp;
	// Underflow
	if (res_exp < -(F64_EXPONENT_BIAS: i64) - (F64_MANTISSA_BITS: i64)) {
		return copysign(0f64, mantissa);
	};
	// Overflow
	if (res_exp > (F64_EXPONENT_BIAS: i64)) {
		if (mantissa < 0f64) {
			return -INF;
		} else {
			return INF;
		};
	};
	// Subnormal
	let subnormal_factor = 1f64;
	if (res_exp < -(F64_EXPONENT_BIAS: i64) + 1) {
		res_exp += (F64_MANTISSA_BITS: i64) - 1;
		subnormal_factor = 1f64 /
			((1i64 << ((F64_MANTISSA_BITS: i64) - 1)): f64);
	};
	const res: u64 = (bits & F64_EXP_REMOVAL_MASK) |
		(
			((res_exp: u64) + F64_EXPONENT_BIAS)
			<< F64_MANTISSA_BITS
		);
	return subnormal_factor * f64frombits(res);
};

// Creates an f32 from a mantissa and an exponent.
export fn ldexpf32(mantissa: f32, exp: i64) f32 = {
	if (isnan(mantissa) || isinf(mantissa) || mantissa == 0f32) {
		return mantissa;
	};
	const normalized = normalizef32(mantissa);
	const normal_float = normalized.0;
	const normalization_exp = normalized.1;
	const bits = f32bits(normal_float);
	const mantissa_exp =
		(((bits >> F32_MANTISSA_BITS) & F32_EXPONENT_MASK): i32) -
		(F32_EXPONENT_BIAS: i32);
	let res_exp = exp + normalization_exp + mantissa_exp;
	// Underflow
	if (res_exp < -(F32_EXPONENT_BIAS: i32) - (F32_MANTISSA_BITS: i32)) {
		return copysignf32(0.0f32, mantissa);
	};
	// Overflow
	if (res_exp > (F32_EXPONENT_BIAS: i32)) {
		if (mantissa < 0.0f32) {
			return -INF;
		} else {
			return INF;
		};
	};
	// Subnormal
	let subnormal_factor = 1.0f32;
	if (res_exp < -(F32_EXPONENT_BIAS: i32) + 1) {
		res_exp += (F32_MANTISSA_BITS: i32) - 1;
		subnormal_factor = 1.0f32 /
			((1i32 << ((F32_MANTISSA_BITS: i32) - 1)): f32);
	};
	const res: u32 = (bits & F32_EXP_REMOVAL_MASK) |
		(
			((res_exp: u32) + F32_EXPONENT_BIAS)
			<< (F32_MANTISSA_BITS: u32)
		);
	return subnormal_factor * f32frombits(res);
};

// Returns the integer and fractional parts of an f64.
export fn modfracf64(n: f64) (f64, f64) = {
	if (n < 1f64) {
		if (n < 0f64) {
			let positive_parts = modfracf64(-n);
			return (-positive_parts.0, -positive_parts.1);
		};
		if (n == 0f64) {
			return (n, n);
		};
		return (0f64, n);
	};
	let bits = f64bits(n);
	const exp = (((bits >> F64_MANTISSA_BITS) & F64_EXPONENT_MASK): i64) -
		(F64_EXPONENT_BIAS: i64);
	// For exponent exp, all integers can be represented with the top exp
	// bits of the mantissa
	const sign_and_exp_bits = 64u64 - (F64_EXPONENT_BITS: u64) - 1u64;
	if (exp < (sign_and_exp_bits: i64)) {
		const bits_to_shift = (((sign_and_exp_bits: i64) - exp): u64);
		bits = bits & ~((1u64 << bits_to_shift) - 1);
	};
	const int_part = f64frombits(bits);
	const frac_part = n - int_part;
	return (int_part, frac_part);
};

// Returns the integer and fractional parts of an f32.
export fn modfracf32(n: f32) (f32, f32) = {
	if (n < 1.0f32) {
		if (n < 0.0f32) {
			let positive_parts = modfracf32(-n);
			return (-positive_parts.0, -positive_parts.1);
		};
		if (n == 0.0f32) {
			return (n, n);
		};
		return (0f32, n);
	};
	let bits = f32bits(n);
	const exp = (((bits >> F32_MANTISSA_BITS) & F32_EXPONENT_MASK): i32) -
		(F32_EXPONENT_BIAS: i32);
	// For exponent exp, all integers can be represented with the top exp
	// bits of the mantissa
	const sign_and_exp_bits = 32u32 - (F32_EXPONENT_BITS: u32) - 1u32;
	if (exp < (sign_and_exp_bits: i32)) {
		const bits_to_shift = (((sign_and_exp_bits: i32) - exp): u32);
		bits = bits & ~((1u32 << bits_to_shift) - 1);
	};
	const int_part = f32frombits(bits);
	const frac_part = n - int_part;
	return (int_part, frac_part);
};

// Returns the f32 that is closest to 'x' in direction of 'y'. Returns NaN
// if either parameter is NaN. Returns 'x' if both parameters are same.
export fn nextafterf32(x: f32, y: f32) f32 = {
	if (isnan(x) || isnan(y)) {
		return x + y;
	};
	let ux = f32bits(x);
	let uy = f32bits(y);
	if (ux == uy) {
		return x;
	};

	let absx = ux & 0x7fffffff, absy = uy & 0x7fffffff;
	if (absx == 0) {
		if (absy == 0) {
			return x;
		};
		ux = uy & 0x80000000 | 1;
	} else if (absx > absy || (ux ^ uy) & 0x80000000 != 0) {
		ux -= 1;
	} else {
		ux += 1;
	};
	// TODO handle over/underflow
	return f32frombits(ux);
};

// Returns the f64 that is closest to 'x' in direction of 'y' Returns NaN
// if either parameter is NaN. Returns 'x' if both parameters are same.
export fn nextafterf64(x: f64, y: f64) f64 = {
	if (isnan(x) || isnan(y)) {
		return x + y;
	};
	let ux = f64bits(x);
	let uy = f64bits(y);
	if (ux == uy) {
		return x;
	};

	let absx = ux & ~(1u64 << 63), absy = uy & ~(1u64 << 63);
	if (absx == 0) {
		if (absy == 0) {
			return x;
		};
		ux = uy & (1u64 << 63) | 1u64;
	} else if (absx > absy || (ux ^ uy) & (1u64 << 63) != 0) {
		ux -= 1;
	} else {
		ux += 1;
	};
	// TODO handle over/underflow
	return f64frombits(ux);
};

// Round a f32 to nearest integer value in floating point format
fn nearbyintf32(x: f32) f32 = {
	let n = f32bits(x);
	let e = n >> 23 & 0xff;
	if (e >= 0x7f + 23) {
		return x;
	};
	let s = n >> 31;
	let y = if (s != 0)
		x - 1.0 / F32_EPS + 1.0 / F32_EPS
	else
		x + 1.0 / F32_EPS - 1.0 / F32_EPS;

	if (y == 0.0f32)
		return if (s != 0) -0.0f32 else 0.0f32
	else
		return y;
};

// Round a f64 to nearest integer value in floating point format
fn nearbyintf64(x: f64) f64 = {
	let n = f64bits(x);
	let e = n >> 52 & 0x7ff;
	if (e >= 0x3ff + 52) {
		return x;
	};
	let s = n >> 63;
	let y = if (s != 0)
		x - 1.0 / F64_EPS + 1.0 / F64_EPS
	else
		x + 1.0 / F64_EPS - 1.0 / F64_EPS;

	if (y == 0.0f64)
		return if (s != 0) -0.0f64 else 0.0f64
	else
		return y;
};
