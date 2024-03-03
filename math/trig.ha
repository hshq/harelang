// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Sections of the code below are based on Go's implementation, which is, in
// turn, based on:
// * the Cephes Mathematical Library (cephes/cmath/{sin,..}), available from
//   http://www.netlib.org/cephes/cmath.tgz.
// * FreeBSD's /usr/src/lib/msun/src/{s_asinh.c,...}
// The original C code, as well as the respective comments and constants are
// from these libraries.
//
// The Cephes copyright notice:
// ====================================================
// Cephes Math Library Release 2.8:  June, 2000
// Copyright 1984, 1987, 1989, 1992, 2000 by Stephen L. Moshier
//
// The readme file at http://netlib.sandia.gov/cephes/ says:
//    Some software in this archive may be from the book _Methods and
// Programs for Mathematical Functions_ (Prentice-Hall or Simon & Schuster
// International, 1989) or from the Cephes Mathematical Library, a
// commercial product. In either event, it is copyrighted by the author.
// What you see here may be used freely but it comes with no support or
// guarantee.
//
//   The two known misprints in the book are repaired here in the
// source listings for the gamma function and the incomplete beta
// integral.
//
//   Stephen L. Moshier
//   moshier@na-net.ornl.gov
// ====================================================
//
// The FreeBSD copyright notice:
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//
// The Go copyright notice:
// ====================================================
// Copyright (c) 2009 The Go Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ====================================================

// sin coefficients
const SIN_CF: [_]f64 = [
	1.58962301576546568060e-10, // 0x3de5d8fd1fd19ccd
	-2.50507477628578072866e-8, // 0xbe5ae5e5a9291f5d
	2.75573136213857245213e-6, // 0x3ec71de3567d48a1
	-1.98412698295895385996e-4, // 0xbf2a01a019bfdf03
	8.33333333332211858878e-3, // 0x3f8111111110f7d0
	-1.66666666666666307295e-1, // 0xbfc5555555555548
];

// cos coefficients
const COS_CF: [_]f64 = [
	-1.13585365213876817300e-11, // 0xbda8fa49a0861a9b
	2.08757008419747316778e-9, // 0x3e21ee9d7b4e3f05
	-2.75573141792967388112e-7, // 0xbe927e4f7eac4bc6
	2.48015872888517045348e-5, // 0x3efa01a019c844f5
	-1.38888888888730564116e-3, // 0xbf56c16c16c14f91
	4.16666666666665929218e-2, // 0x3fa555555555554b
];

// PI / 4 split into three parts
def PI4A: f64 = 7.85398125648498535156e-1; // 0x3fe921fb40000000
def PI4B: f64 = 3.77489470793079817668e-8; // 0x3e64442d00000000
def PI4C: f64 = 2.69515142907905952645e-15; // 0x3ce8469898cc5170

// reduce_threshold is the maximum value of x where the reduction using PI/4
// in 3 float64 parts still gives accurate results. This threshold
// is set by y*C being representable as a float64 without error
// where y is given by y = floor(x * (4 / PI)) and C is the leading partial
// terms of 4/PI. Since the leading terms (PI4A and PI4B in sin.go) have 30
// and 32 trailing zero bits, y should have less than 30 significant bits.
//	y < 1<<30  -> floor(x*4/PI) < 1<<30 -> x < (1<<30 - 1) * PI/4
// So, conservatively we can take x < 1<<29.
// Above this threshold Payne-Hanek range reduction must be used.
def REDUCE_THRESHOLD: f64 = ((1u64 << 29): f64);

// MPI4 is the binary digits of 4/pi as a uint64 array,
// that is, 4/pi = Sum MPI4[i]*2^(-64*i)
// 19 64-bit digits and the leading one bit give 1217 bits
// of precision to handle the largest possible float64 exponent.
const MPI4: [_]u64 = [
	0x0000000000000001,
	0x45f306dc9c882a53,
	0xf84eafa3ea69bb81,
	0xb6c52b3278872083,
	0xfca2c757bd778ac3,
	0x6e48dc74849ba5c0,
	0x0c925dd413a32439,
	0xfc3bd63962534e7d,
	0xd1046bea5d768909,
	0xd338e04d68befc82,
	0x7323ac7306a673e9,
	0x3908bf177bf25076,
	0x3ff12fffbc0b301f,
	0xde5e2316b414da3e,
	0xda6cfd9e4f96136e,
	0x9e8c7ecd3cbfd45a,
	0xea4f758fd7cbe2f6,
	0x7a0e73ef14a525d4,
	0xd7f6bf623f1aba10,
	0xac06608df8f6d757,
];

// trig_reduce implements Payne-Hanek range reduction by PI/4 for x > 0. It
// returns the integer part mod 8 (j) and the fractional part (z) of x / (PI/4).
fn trig_reduce(x: f64) (u64, f64) = {
	// The implementation is based on: "ARGUMENT REDUCTION FOR HUGE
	// ARGUMENTS: Good to the Last Bit" K. C. Ng et al, March 24, 1992
	// The simulated multi-precision calculation of x * B uses 64-bit
	// integer arithmetic.
	const PI4 = PI / 4f64;
	if (x < PI4) {
		return (0u64, x);
	};
	// Extract out the integer and exponent such that x = ix * 2 ** exp
	let ix = f64bits(x);
	const exp =
		((ix >> F64_MANTISSA_BITS &
			F64_EXPONENT_MASK): i64) -
		(F64_EXPONENT_BIAS: i64) -
		(F64_MANTISSA_BITS: i64);
	ix = ix & ~(F64_EXPONENT_MASK << F64_MANTISSA_BITS);
	ix |= 1 << F64_MANTISSA_BITS;
	// Use the exponent to extract the 3 appropriate uint64 digits from
	// MPI4, B ~ (z0, z1, z2), such that the product leading digit has the
	// exponent -61. Note, exp >= -53 since x >= PI4 and exp < 971 for
	// maximum float64.
	const digit = ((exp + 61): u64) / 64;
	const bitshift = ((exp + 61): u64) % 64;
	const z0 = (MPI4[digit] << bitshift) |
		(MPI4[digit + 1] >> (64 - bitshift));
	const z1 = (MPI4[digit + 1] << bitshift) |
		(MPI4[digit + 2] >> (64 - bitshift));
	const z2 = (MPI4[digit + 2] << bitshift) |
		(MPI4[digit + 3] >> (64 - bitshift));
	// Multiply mantissa by the digits and extract the upper two digits
	// (hi, lo).
	const z2 = mulu64(z2, ix);
	const z2hi = z2.0;
	const z1 = mulu64(z1, ix);
	const z1hi = z1.0;
	const z1lo = z1.1;
	const z0lo = z0 * ix;
	const add1 = addu64(z1lo, z2hi, 0);
	const lo = add1.0;
	const c = add1.1;
	const add2 = addu64(z0lo, z1hi, c);
	let hi = add2.0;
	// The top 3 bits are j.
	let j = hi >> 61;
	// Extract the fraction and find its magnitude.
	hi = hi << 3 | lo >> 61;
	const lz = ((leading_zeros_u64(hi)): uint);
	const e = ((F64_EXPONENT_BIAS - (lz + 1)): u64);
	// Clear implicit mantissa bit and shift into place.
	hi = (hi << (lz + 1)) | (lo >> (64 - (lz + 1)));
	hi >>= 64 - F64_MANTISSA_BITS;
	// Include the exponent and convert to a float.
	hi |= e << F64_MANTISSA_BITS;
	let z = f64frombits(hi);
	// Map zeros to origin.
	if (j & 1 == 1) {
		j += 1;
		j &= 7;
		z -= 1f64;
	};
	// Multiply the fractional part by pi/4.
	return (j, z * PI4);
};

//      cos.c
//
//      Circular cosine
//
// SYNOPSIS:
//
// double x, y, cos();
// y = cos( x );
//
// DESCRIPTION:
//
// Range reduction is into intervals of pi/4.  The reduction error is nearly
// eliminated by contriving an extended precision modular arithmetic.
//
// Two polynomial approximating functions are employed.
// Between 0 and pi/4 the cosine is approximated by
//      1  -  x**2 Q(x**2).
// Between pi/4 and pi/2 the sine is represented as
//      x  +  x**3 P(x**2).
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain      # trials      peak         rms
//    IEEE -1.07e9,+1.07e9  130000       2.1e-16     5.4e-17
//    DEC        0,+1.07e9   17000       3.0e-17     7.2e-18

// Returns the cosine of x, in radians.
export fn cosf64(x: f64) f64 = {
	if (isnan(x) || isinf(x)) {
		return NAN;
	};

	// Make argument positive
	let is_negative = false;
	x = absf(x);

	let j = 0u64;
	let y = 0f64;
	let z = 0f64;
	if (x >= REDUCE_THRESHOLD) {
		const reduce_res = trig_reduce(x);
		j = reduce_res.0;
		z = reduce_res.1;
	} else {
		// Integer part of x/(PI/4), as integer for tests on the phase
		// angle
		j = ((x * (4f64 / PI)): i64: u64);
		// Integer part of x/(PI/4), as float
		y = (j: i64: f64);

		// Map zeros to origin
		if (j & 1 == 1) {
			j += 1;
			y += 1f64;
		};
		// Octant modulo 2PI radians (360 degrees)
		j &= 7;
		// Extended precision modular arithmetic
		z = ((x - (y * PI4A)) - (y * PI4B)) - (y * PI4C);
	};

	if (j > 3) {
		j -= 4;
		is_negative = !is_negative;
	};
	if (j > 1) {
		is_negative = !is_negative;
	};

	const zz = z * z;
	if (j == 1 || j == 2) {
		y = z + z * zz * ((((((SIN_CF[0] * zz) +
			SIN_CF[1]) * zz +
			SIN_CF[2]) * zz +
			SIN_CF[3]) * zz +
			SIN_CF[4]) * zz +
			SIN_CF[5]);
	} else {
		y = 1.0 - 0.5 * zz + zz * zz * ((((((COS_CF[0] * zz) +
			COS_CF[1]) * zz +
			COS_CF[2]) * zz +
			COS_CF[3]) * zz +
			COS_CF[4]) * zz +
			COS_CF[5]);
	};
	if (is_negative) {
		y = -y;
	};
	return y;
};

//      sin.c
//
//      Circular sine
//
// SYNOPSIS:
//
// double x, y, sin();
// y = sin( x );
//
// DESCRIPTION:
//
// Range reduction is into intervals of pi/4.  The reduction error is nearly
// eliminated by contriving an extended precision modular arithmetic.
//
// Two polynomial approximating functions are employed.
// Between 0 and pi/4 the sine is approximated by
//      x  +  x**3 P(x**2).
// Between pi/4 and pi/2 the cosine is represented as
//      1  -  x**2 Q(x**2).
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain      # trials      peak         rms
//    DEC       0, 10       150000       3.0e-17     7.8e-18
//    IEEE -1.07e9,+1.07e9  130000       2.1e-16     5.4e-17
//
// Partial loss of accuracy begins to occur at x = 2**30 = 1.074e9.  The loss
// is not gradual, but jumps suddenly to about 1 part in 10e7.  Results may
// be meaningless for x > 2**49 = 5.6e14.

// Returns the sine of x, in radians.
export fn sinf64(x: f64) f64 = {
	if (x == 0f64 || isnan(x)) {
		return x;
	} else if (isinf(x)) {
		return NAN;
	};

	// Make argument positive but save the sign
	let is_negative = false;
	if (x < 0f64) {
		x = -x;
		is_negative = true;
	};

	let j = 0u64;
	let y = 0f64;
	let z = 0f64;
	if (x >= REDUCE_THRESHOLD) {
		const reduce_res = trig_reduce(x);
		j = reduce_res.0;
		z = reduce_res.1;
	} else {
		// Integer part of x/(PI/4), as integer for tests on the phase
		// angle
		j = ((x * (4f64 / PI)): i64: u64);
		// Integer part of x/(PI/4), as float
		y = (j: i64: f64);

		// Map zeros to origin
		if (j & 1 == 1) {
			j += 1;
			y += 1f64;
		};
		// Octant modulo 2PI radians (360 degrees)
		j &= 7;
		// Extended precision modular arithmetic
		z = ((x - (y * PI4A)) - (y * PI4B)) - (y * PI4C);
	};

	// Reflect in x axis
	if (j > 3) {
		j -= 4;
		is_negative = !is_negative;
	};

	const zz = z * z;
	if (j == 1 || j == 2) {
		y = 1.0 - 0.5 * zz + zz * zz *
			((((((COS_CF[0] * zz) +
				COS_CF[1]) * zz +
				COS_CF[2]) * zz +
				COS_CF[3]) * zz +
				COS_CF[4]) * zz +
				COS_CF[5]);
	} else {
		y = z + z * zz *
			((((((SIN_CF[0] * zz) +
				SIN_CF[1]) * zz +
				SIN_CF[2]) * zz +
				SIN_CF[3]) * zz +
				SIN_CF[4]) * zz +
				SIN_CF[5]);
	};
	if (is_negative) {
		y = -y;
	};
	return y;
};

//      tan.c
//
//      Circular tangent
//
// SYNOPSIS:
//
// double x, y, tan();
// y = tan( x );
//
// DESCRIPTION:
//
// Returns the circular tangent of the radian argument x.
//
// Range reduction is modulo pi/4.  A rational function
//       x + x**3 P(x**2)/Q(x**2)
// is employed in the basic interval [0, pi/4].
//
// ACCURACY:
//                      Relative error:
// arithmetic   domain     # trials      peak         rms
//    DEC      +-1.07e9      44000      4.1e-17     1.0e-17
//    IEEE     +-1.07e9      30000      2.9e-16     8.1e-17
//
// Partial loss of accuracy begins to occur at x = 2**30 = 1.074e9.  The loss
// is not gradual, but jumps suddenly to about 1 part in 10e7.  Results may
// be meaningless for x > 2**49 = 5.6e14.
// [Accuracy loss statement from sin.go comments.]

// tan coefficients
const TAN_P: [_]f64 = [
	-1.30936939181383777646e4, // 0xc0c992d8d24f3f38
	1.15351664838587416140e6, // 0x413199eca5fc9ddd
	-1.79565251976484877988e7, // 0xc1711fead3299176
];
const TAN_Q: [_]f64 = [
	1.00000000000000000000e0,
	1.36812963470692954678e4, // 0x40cab8a5eeb36572
	-1.32089234440210967447e6, // 0xc13427bc582abc96
	2.50083801823357915839e7, // 0x4177d98fc2ead8ef
	-5.38695755929454629881e7, // 0xc189afe03cbe5a31
];

// Returns the tangent of x, in radians.
export fn tanf64(x: f64) f64 = {
	if (x == 0f64 || isnan(x)) {
		return x;
	} else if (isinf(x)) {
		return NAN;
	};

	// Make argument positive but save the sign
	let is_negative = false;
	if (x < 0f64) {
		x = -x;
		is_negative = true;
	};
	let j = 0u64;
	let y = 0f64;
	let z = 0f64;
	if (x >= REDUCE_THRESHOLD) {
		const reduce_res = trig_reduce(x);
		j = reduce_res.0;
		z = reduce_res.1;
	} else {
		// Integer part of x/(PI/4), as integer for tests on the phase
		// angle
		j = ((x * (4f64 / PI)): i64: u64);
		// Integer part of x/(PI/4), as float
		y = (j: i64: f64);

		// Map zeros and singularities to origin
		if (j & 1 == 1) {
			j += 1;
			y += 1f64;
		};

		z = ((x - (y * PI4A)) - (y * PI4B)) - (y * PI4C);
	};
	const zz = z * z;

	if (zz > 1e-14) {
		y = z + z * (zz *
			(((TAN_P[0] * zz) + TAN_P[1]) * zz + TAN_P[2]) /
			((((zz + TAN_Q[1]) * zz +
				TAN_Q[2]) * zz +
				TAN_Q[3]) * zz +
				TAN_Q[4]));
	} else {
		y = z;
	};
	if (j & 2 == 2) {
		y = -1f64 / y;
	};
	if (is_negative) {
		y = -y;
	};
	return y;
};

// Evaluates a series valid in the range [0, 0.66].
fn xatan(x: f64) f64 = {
	const P0 = -8.750608600031904122785e-01;
	const P1 = -1.615753718733365076637e+01;
	const P2 = -7.500855792314704667340e+01;
	const P3 = -1.228866684490136173410e+02;
	const P4 = -6.485021904942025371773e+01;
	const Q0 =  2.485846490142306297962e+01;
	const Q1 =  1.650270098316988542046e+02;
	const Q2 =  4.328810604912902668951e+02;
	const Q3 =  4.853903996359136964868e+02;
	const Q4 =  1.945506571482613964425e+02;
	let z = x * x;
	z = z * ((((P0 * z + P1) * z + P2) * z + P3) * z + P4) /
		(((((z + Q0) * z + Q1) * z + Q2) * z + Q3) * z + Q4);
	z = (x * z) + x;
	return z;
};

// Reduces argument (known to be positive) to the range [0, 0.66] and calls
// xatan.
fn satan(x: f64) f64 = {
	// pi / 2 = PIO2 + morebits
	const morebits = 6.123233995736765886130e-17;
	// tan(3 * pi / 8)
	const tan3pio8 = 2.41421356237309504880;
	if (x <= 0.66) {
		return xatan(x);
	};
	if (x > tan3pio8) {
		return (PI / 2f64) - xatan(1f64 / x) + morebits;
	};
	return (PI / 4f64) +
		xatan((x - 1f64) / (x + 1f64)) +
		(0.5f64 * morebits);
};

// Returns the arcsine, in radians, of x.
export fn asinf64(x: f64) f64 = {
	if (x == 0f64) {
		return x;
	};
	let is_negative = false;
	if (x < 0.064) {
		x = -x;
		is_negative = true;
	};
	if (x > 1f64) {
		return NAN;
	};
	let temp = sqrtf64(1f64 - x * x);
	if (x > 0.7f64) {
		temp = PI / 2f64 - satan(temp / x);
	} else {
		temp = satan(x / temp);
	};

	if (is_negative) {
		temp = -temp;
	};
	return temp;
};

// Returns the arccosine, in radians, of x.
export fn acosf64(x: f64) f64 = {
	return PI / 2f64 - asinf64(x);
};

// atan.c
// Inverse circular tangent (arctangent)
//
// SYNOPSIS:
// double x, y, atan();
// y = atan( x );
//
// DESCRIPTION:
// Returns radian angle between -pi/2 and +pi/2 whose tangent is x.
//
// Range reduction is from three intervals into the interval from zero to 0.66.
// The approximant uses a rational function of degree 4/5 of the form
// x + x**3 P(x)/Q(x).
//
// ACCURACY:
//                      Relative error:
// arithmetic   domain    # trials  peak     rms
//    DEC       -10, 10   50000     2.4e-17  8.3e-18
//    IEEE      -10, 10   10^6      1.8e-16  5.0e-17

// Returns the arctangent, in radians, of x.
export fn atanf64(x: f64) f64 = {
	if (x == 0f64) {
		return x;
	};
	if (x > 0f64) {
		return satan(x);
	};
	return -satan(-x);
};

// Floating-point hyperbolic sine and cosine.
// The exponential func is called for arguments greater in magnitude than 0.5.
// A series is used for arguments smaller in magnitude than 0.5.
// Cosh(x) is computed from the exponential func for all arguments.

// Returns the hyperbolic sine of x.
export fn sinhf64(x: f64) f64 = {
	// The coefficients are #2029 from Hart & Cheney. (20.36D)
	const P0 = -0.6307673640497716991184787251e+6;
	const P1 = -0.8991272022039509355398013511e+5;
	const P2 = -0.2894211355989563807284660366e+4;
	const P3 = -0.2630563213397497062819489e+2;
	const Q0 = -0.6307673640497716991212077277e+6;
	const Q1 = 0.1521517378790019070696485176e+5;
	const Q2 = -0.173678953558233699533450911e+3;

	let is_negative = false;
	if (x < 0f64) {
		x = -x;
		is_negative = true;
	};

	let temp = 0f64;
	if (x > 21f64) {
		temp = expf64(x) * 0.5f64;
	} else if (x > 0.5f64) {
		const ex = expf64(x);
		temp = (ex - (1f64 / ex)) * 0.5f64;
	} else {
		const sq = x * x;
		temp = (((P3 * sq + P2) * sq + P1) * sq + P0) * x;
		temp = temp / (((sq + Q2) * sq + Q1) * sq + Q0);
	};

	if (is_negative) {
		temp = -temp;
	};

	return temp;
};

// Returns the hyperbolic cosine of x.
export fn coshf64(x: f64) f64 = {
	x = absf64(x);
	if (x > 21f64) {
		return expf64(x) * 0.5f64;
	};
	const ex = expf64(x);
	return (ex + 1f64 / ex) * 0.5f64;
};

//      tanh.c
//
//      Hyperbolic tangent
//
// SYNOPSIS:
//
// double x, y, tanh();
//
// y = tanh( x );
//
// DESCRIPTION:
//
// Returns hyperbolic tangent of argument in the range MINLOG to MAXLOG.
//      MAXLOG = 8.8029691931113054295988e+01 = log(2**127)
//      MINLOG = -8.872283911167299960540e+01 = log(2**-128)
//
// A rational function is used for |x| < 0.625.  The form
// x + x**3 P(x)/Q(x) of Cody & Waite is employed.
// Otherwise,
//      tanh(x) = sinh(x)/cosh(x) = 1  -  2/(exp(2x) + 1).
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain     # trials      peak         rms
//    IEEE      -2,2        30000       2.5e-16     5.8e-17

// tanh coefficients
const TANH_P: [_]f64 = [
	-9.64399179425052238628e-1,
	-9.92877231001918586564e1,
	-1.61468768441708447952e3,
];
const TANH_Q: [_]f64 = [
	1.12811678491632931402e2,
	2.23548839060100448583e3,
	4.84406305325125486048e3,
];

// Returns the hyperbolic tangent of x.
export fn tanhf64(x: f64) f64 = {
	const MAXLOG = 8.8029691931113054295988e+01; // log(2**127)
	let z = absf64(x);
	if (z > 0.5f64 * MAXLOG) {
		if (x < 0f64) {
			return -1f64;
		};
		return 1f64;
	} else if (z >= 0.625f64) {
		const s = expf64(2f64 * z);
		z = 1f64 - 2f64 / (s + 1f64);
		if (x < 0f64) {
			z = -z;
		};
	} else {
		if (x == 0f64) {
			return x;
		};
		const s = x * x;
		z = x + x * s * ((TANH_P[0] * s + TANH_P[1]) * s + TANH_P[2]) /
			(((s + TANH_Q[0]) * s + TANH_Q[1]) * s + TANH_Q[2]);
	};
	return z;
};

// asinh(x)
// Method :
//	Based on
//	        asinh(x) = sign(x) * log [ |x| + sqrt(x*x+1) ]
//	we have
//	asinh(x) := x  if  1+x*x=1,
//	         := sign(x)*(log(x)+ln2)) for large |x|, else
//	         := sign(x)*log(2|x|+1/(|x|+sqrt(x*x+1))) if|x|>2, else
//	         := sign(x)*log1p(|x| + x**2/(1 + sqrt(1+x**2)))
//

// Returns the inverse hyperbolic sine of x.
export fn asinhf64(x: f64) f64 = {
	const NEAR_ZERO = 1f64 / ((1i64 << 28): f64);
	const LARGE = ((1i64 << 28): f64);

	if (isnan(x) || isinf(x)) {
		return x;
	};

	let is_negative = false;
	if (x < 0f64) {
		x = -x;
		is_negative = true;
	};

	let temp = 0f64;

	if (x > LARGE) {
		// |x| > 2**28
		temp = logf64(x) + LN_2;
	} else if (x > 2f64) {
		// 2**28 > |x| > 2.0
		temp = logf64(2f64 * x +
			1f64 / (sqrtf64(x * x + 1f64) + x));
	} else if (x < NEAR_ZERO) {
		// |x| < 2**-28
		temp = x;
	} else {
		// 2.0 > |x| > 2**-28
		temp = log1pf64(x + x * x /
			(1f64 + sqrtf64(1f64 + x * x)));
	};
	if (is_negative) {
		temp = -temp;
	};
	return temp;
};

// __ieee754_acosh(x)
// Method :
//	Based on
//	        acosh(x) = log [ x + sqrt(x*x-1) ]
//	we have
//	        acosh(x) := log(x)+ln2,	if x is large; else
//	        acosh(x) := log(2x-1/(sqrt(x*x-1)+x)) if x>2; else
//	        acosh(x) := log1p(t+sqrt(2.0*t+t*t)); where t=x-1.
//
// Special cases:
//	acosh(x) is NaN with signal if x<1.
//	acosh(NaN) is NaN without signal.
//

// Returns the inverse hyperbolic cosine of x.
export fn acoshf64(x: f64) f64 = {
	const LARGE = ((1i64 << 28): f64);

	if (x < 1f64 || isnan(x)) {
		return NAN;
	} else if (x == 1f64) {
		return 0f64;
	} else if (x >= LARGE) {
		// x > 2**28
		return logf64(x) + LN_2;
	} else if (x > 2f64) {
		// 2**28 > x > 2
		return logf64(2f64 * x - 1f64 /
			(x + sqrtf64(x * x - 1f64)));
	};
	const t = x - 1f64;
	// 2 >= x > 1
	return log1pf64(t + sqrtf64(2f64 * t + t * t));
};

// __ieee754_atanh(x)
// Method :
//	1. Reduce x to positive by atanh(-x) = -atanh(x)
//	2. For x>=0.5
//	            1              2x                          x
//	atanh(x) = --- * log(1 + -------) = 0.5 * log1p(2 * --------)
//	            2             1 - x                      1 - x
//
//	For x<0.5
//	atanh(x) = 0.5*log1p(2x+2x*x/(1-x))
//
// Special cases:
//	atanh(x) is NaN if |x| > 1 with signal;
//	atanh(NaN) is that NaN with no signal;
//	atanh(+-1) is +-INF with signal.
//

// Returns the inverse hyperbolic tangent of x.
export fn atanhf64(x: f64) f64 = {
	const NEAR_ZERO = 1f64 / ((1i64 << 28): f64);

	if (x < -1f64 || x > 1.064) {
		return NAN;
	} else if (isnan(x)) {
		return NAN;
	} else if (x == 1f64) {
		return INF;
	} else if (x == -1f64) {
		return -INF;
	};

	let is_negative = false;

	if (x < 0f64) {
		x = -x;
		is_negative = true;
	};

	let temp = 0f64;

	if (x < NEAR_ZERO) {
		temp = x;
	} else if (x < 0.5f64) {
		temp = x + x;
		temp = 0.5f64 * log1pf64(temp + temp * x / (1f64 - x));
	} else {
		temp = 0.5f64 * log1pf64((x + x) / (1f64 - x));
	};
	if (is_negative) {
		temp = -temp;
	};
	return temp;
};

// Returns the arctangent, in radians, of y / x.
export fn atan2f64(y: f64, x: f64) f64 = {
	if (isnan(y) || isnan(x)) {
		return NAN;
	} else if (y == 0f64) {
		x = if (x >= 0f64 && signf64(x) > 0) 0f64 else PI;
		return copysignf64(x, y);
	} else if (x == 0f64) {
		return copysignf64(PI / 2f64, y);
	} else if (isinf(x)) {
		if (signf64(x) > 0) {
			x = if (isinf(y)) PI / 4f64 else 0f64;
			return copysignf64(x, y);
		} else {
			x = if (isinf(y)) 3f64 * PI / 4f64 else PI;
			return copysignf64(x, y);
		};
	} else if (isinf(y)) {
		return copysignf64(PI / 2f64, y);
	};

	const q = atanf64(y / x);
	if (x < 0f64) {
		return if (q <= 0f64) q + PI else q - PI;
	};
	return q;
};

// Returns the square root of a*a + b*b, taking care to avoid unnecessary
// overflow and underflow.
export fn hypotf64(a: f64, b: f64) f64 = {
	if (isinf(a) || isinf(b)) {
		return INF;
	} else if (isnan(a) || isnan(b)) {
		return NAN;
	};
	a = absf64(a);
	b = absf64(b);
	if (a < b) {
		const temp = a;
		a = b;
		b = temp;
	};
	if (a == 0f64) {
		return 0f64;
	};
	b = b / a;
	return a * sqrtf64(1f64 + b * b);
};
