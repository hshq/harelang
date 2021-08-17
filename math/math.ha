// Sections of the code below, in particular log() and exp(), are based on Go's
// implementation, which is, in turn, based on FreeBSD's. The original C code,
// as well as the respective comments and constants are from
// /usr/src/lib/msun/src/e_log.c.
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

use types;

// Returns whether x and y are within tol of each other.
export fn eqwithinf64(x: f64, y: f64, tol: f64) bool = {
	return absf64(x - y) < tol;
};

// Returns whether x and y are within tol of each other.
export fn eqwithinf32(x: f32, y: f32, tol: f32) bool = {
	return absf32(x - y) < tol;
};

// Returns whether x and y are within tol of each other.
export fn eqwithin(x: types::floating, y: types::floating,
		tol: types::floating) bool = {
	return match (x) {
		n: f64 => eqwithinf64(n, y as f64, tol as f64),
		n: f32 => eqwithinf32(n, y as f32, tol as f32),
	};
};

@test fn equalwithin() void = {
	assert(eqwithin(1.0f64, 2.0f64, 2.0f64));
	assert(eqwithin(1.0f32, 2.0f32, 2.0f32));
	assert(!eqwithin(1.0005f32, 1.0004f32, 0.00001f32));
};

// e - https://oeis.org/A001113
export def E: f64 = 2.71828182845904523536028747135266249775724709369995957496696763;
// pi - https://oeis.org/A000796
export def PI: f64 = 3.14159265358979323846264338327950288419716939937510582097494459;
// phi - https://oeis.org/A001622
export def PHI: f64 = 1.61803398874989484820458683436563811772030917980576286213544862;
// sqrt(2) - https://oeis.org/A002193
def SQRT_2: f64 = 1.41421356237309504880168872420969807856967187537694807317667974;
// sqrt(e) - https://oeis.org/A019774
def SQRT_E: f64 = 1.64872127070012814684865078781416357165377610071014801157507931;
// sqrt(pi) - https://oeis.org/A002161
def SQRT_PI: f64 = 1.77245385090551602729816748334114518279754945612238712821380779;
// sqrt(phi) - https://oeis.org/A139339
def SQRT_PHI: f64 = 1.27201964951406896425242246173749149171560804184009624861664038;
// ln(2) - https://oeis.org/A002162
def LN_2: f64 = 0.693147180559945309417232121458176568075500134360255254120680009;
def LN2_HI: f64 = 6.93147180369123816490e-01;
def LN2_LO: f64 = 1.90821492927058770002e-10;
// log_{2}(e)
def LOG2_E: f64 = 1.0f64 / LN_2;
// ln(10) - https://oeis.org/A002392
def LN_10: f64 = 2.30258509299404568401799145468436420760110148862877297603332790;
// log_{10}(e)
def LOG10_E: f64 = 1.0f64 / LN_10;

// __ieee754_log(x)
// Return the logarithm of x
//
// Method :
//   1. Argument Reduction: find k and f such that
//			x = 2**k * (1+f),
//	   where  sqrt(2)/2 < 1+f < sqrt(2) .
//
//   2. Approximation of log(1+f).
//	Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
//		 = 2s + 2/3 s**3 + 2/5 s**5 + .....,
//	     	 = 2s + s*R
//      We use a special Reme algorithm on [0,0.1716] to generate
//	a polynomial of degree 14 to approximate R.  The maximum error
//	of this polynomial approximation is bounded by 2**-58.45. In
//	other words,
//		        2      4      6      8      10      12      14
//	    R(z) ~ L1*s +L2*s +L3*s +L4*s +L5*s  +L6*s  +L7*s
//	(the values of L1 to L7 are listed in the program) and
//	    |      2          14          |     -58.45
//	    | L1*s +...+L7*s    -  R(z) | <= 2
//	    |                             |
//	Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
//	In order to guarantee error in log below 1ulp, we compute log by
//		log(1+f) = f - s*(f - R)		(if f is not too large)
//		log(1+f) = f - (hfsq - s*(hfsq+R)).	(better accuracy)
//
//	3. Finally,  log(x) = k*Ln2 + log(1+f).
//			    = k*Ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*Ln2_lo)))
//	   Here Ln2 is split into two floating point number:
//			Ln2_hi + Ln2_lo,
//	   where n*Ln2_hi is always exact for |n| < 2000.
//
// Special cases:
//	log(x) is NaN with signal if x < 0 (including -INF) ;
//	log(+INF) is +INF; log(0) is -INF with signal;
//	log(NaN) is that NaN with no signal.
//
// Accuracy:
//	according to an error analysis, the error is always less than
//	1 ulp (unit in the last place).
//
// Constants:
// The hexadecimal values are the intended ones for the following
// constants. The decimal values may be used, provided that the
// compiler will convert from decimal to binary accurately enough
// to produce the hexadecimal values shown.

// Returns the natural logarithm of x.
export fn logf64(x: f64) f64 = {
	const L1 = 6.666666666666735130e-01; // 3FE55555 55555593
	const L2 = 3.999999999940941908e-01; // 3FD99999 9997FA04
	const L3 = 2.857142874366239149e-01; // 3FD24924 94229359
	const L4 = 2.222219843214978396e-01; // 3FCC71C5 1D8E78AF
	const L5 = 1.818357216161805012e-01; // 3FC74664 96CB03DE
	const L6 = 1.531383769920937332e-01; // 3FC39A09 D078C69F
	const L7 = 1.479819860511658591e-01; // 3FC2F112 DF3E5244

	// special cases
	if (isnan(x) || isposinf(x)) {
		return x;
	} else if (x < 0.0f64) {
		return NAN;
	} else if (x == 0.0f64) {
		return -INF;
	};

	// Reduce
	const f1_and_ki = frexp(x);
	let f1 = f1_and_ki.0;
	let ki = f1_and_ki.1;
	if (f1 < (SQRT_2 / 2.0f64)) {
		f1 *= 2.0f64;
		ki -= 1i64;
	};
	let f = f1 - 1.0f64;
	let k = (ki: f64);

	// Compute
	const s = f / (2.0f64 + f);
	const s2 = s * s;
	const s4 = s2 * s2;
	const t1 = s2 * (L1 + s4 * (L3 + s4 * (L5 + s4 * L7)));
	const t2 = s4 * (L2 + s4 * (L4 + s4 * L6));
	const R = t1 + t2;
	const hfsq = 0.5f64 * f * f;
	return k * LN2_HI - ((hfsq - (s * (hfsq + R) + k * LN2_LO)) - f);
};

@test fn logf64() void = {
	assert(logf64(E) == 1.0f64);
	assert(logf64(54.598150033144239078110261202860878402790f64) == 4.0f64);
	assert(isnan(logf64(-1.0f64)));
	assert(isposinf(logf64(INF)));
	assert(isneginf(logf64(0.0f64)));
	assert(isnan(logf64(NAN)));
};

// exp(x)
// Returns the exponential of x.
//
// Method
//   1. Argument reduction:
//      Reduce x to an r so that |r| <= 0.5*ln2 ~ 0.34658.
//      Given x, find r and integer k such that
//
//               x = k*ln2 + r,  |r| <= 0.5*ln2.
//
//      Here r will be represented as r = hi-lo for better
//      accuracy.
//
//   2. Approximation of exp(r) by a special rational function on
//      the interval [0,0.34658]:
//      Write
//          R(r**2) = r*(exp(r)+1)/(exp(r)-1) = 2 + r*r/6 - r**4/360 + ...
//      We use a special Remez algorithm on [0,0.34658] to generate
//      a polynomial of degree 5 to approximate R. The maximum error
//      of this polynomial approximation is bounded by 2**-59. In
//      other words,
//          R(z) ~ 2.0 + P1*z + P2*z**2 + P3*z**3 + P4*z**4 + P5*z**5
//      (where z=r*r, and the values of P1 to P5 are listed below)
//      and
//          |                  5          |     -59
//          | 2.0+P1*z+...+P5*z   -  R(z) | <= 2
//          |                             |
//      The computation of exp(r) thus becomes
//                             2*r
//              exp(r) = 1 + -------
//                            R - r
//                                 r*R1(r)
//                     = 1 + r + ----------- (for better accuracy)
//                                2 - R1(r)
//      where
//                               2       4             10
//              R1(r) = r - (P1*r  + P2*r  + ... + P5*r   ).
//
//   3. Scale back to obtain exp(x):
//      From step 1, we have
//         exp(x) = 2**k * exp(r)
//
// Special cases:
//      exp(INF) is INF, exp(NaN) is NaN;
//      exp(-INF) is 0, and
//      for finite argument, only exp(0)=1 is exact.
//
// Accuracy:
//      according to an error analysis, the error is always less than
//      1 ulp (unit in the last place).
//
// Misc. info.
//      For IEEE double
//          if x >  7.09782712893383973096e+02 then exp(x) overflow
//          if x < -7.45133219101941108420e+02 then exp(x) underflow
//
// Constants:
// The hexadecimal values are the intended ones for the following
// constants. The decimal values may be used, provided that the
// compiler will convert from decimal to binary accurately enough
// to produce the hexadecimal values shown.

// Returns e^r * 2^k where r = hi - lo and |r| <= (ln(2) / 2).
export fn expmultif64(hi: f64, lo: f64, k: i64) f64 = {
	const P1 = 1.66666666666666657415e-01; // 0x3FC55555; 0x55555555
	const P2 = -2.77777777770155933842e-03; // 0xBF66C16C; 0x16BEBD93
	const P3 = 6.61375632143793436117e-05; // 0x3F11566A; 0xAF25DE2C
	const P4 = -1.65339022054652515390e-06; // 0xBEBBBD41; 0xC5D26BF1
	const P5 = 4.13813679705723846039e-08; // 0x3E663769; 0x72BEA4D0

	let r = hi - lo;
	let t = r * r;
	let c = r - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5))));
	let y = 1.0f64 - ((lo - (r * c) / (2.0f64 - c)) - hi);
	return ldexpf64(y, k);
};

// Returns e^x.
export fn expf64(x: f64) f64 = {
	const overflow = 7.09782712893383973096e+02;
	const underflow = -7.45133219101941108420e+02;
	const near_zero = 1.0f64 / ((1i64 << 28i64): f64);

	// Special cases
	if (isnan(x) || isposinf(x)) {
		return x;
	} else if (isneginf(x)) {
		return 0.0f64;
	} else if (x > overflow) {
		return INF;
	} else if (x < underflow) {
		return 0.0f64;
	} else if (-near_zero < x && x < near_zero) {
		return 1.0f64 + x;
	};

	// Reduce; computed as r = hi - lo for extra precision.
	let k = 0i64;
	if (x < 0.0f64) {
		k = (((LOG2_E * x) - 0.5): i64);
	} else if (x > 0.0f64) {
		k = (((LOG2_E * x) + 0.5): i64);
	};
	let hi = x - ((k: f64) * LN2_HI);
	let lo = (k: f64) * LN2_LO;

	// Compute
	return expmultif64(hi, lo, k);
};

// Returns 2^x.
export fn exp2f64(x: f64) f64 = {
	const overflow = 1.0239999999999999e+03;
	const underflow = -1.0740e+03;

	// Special cases
	if (isnan(x) || isposinf(x)) {
		return x;
	} else if (isneginf(x)) {
		return 0.0f64;
	} else if (x > overflow) {
		return INF;
	} else if (x < underflow) {
		return 0.0f64;
	};

	// Argument reduction; x = r×lg(e) + k with |r| ≤ ln(2)/2.
	// Computed as r = hi - lo for extra precision.
	let k = 0i64;
	if (x > 0.0f64) {
		k = ((x + 0.5): i64);
	} else if (x < 0.0f64) {
		k = ((x - 0.5): i64);
	};
	let t = x - (k: f64);
	let hi = t * LN2_HI;
	let lo = -t * LN2_LO;

	// Compute
	return expmultif64(hi, lo, k);
};

@test fn expf64() void = {
	assert(expf64(1.0f64) == E);
	assert(isnan(expf64(NAN)));
	assert(isinf(expf64(INF)));
	assert(expf64(-INF) == 0.0f64);
	assert(isinf(expf64(99999.0f64)));
	assert(expf64(-99999.0f64) == 0.0f64);
	assert(expf64(0.5e-20) == 1.0f64);
};

@test fn exp2f64() void = {
	assert(exp2f64(0.0f64) == 1.0f64);
	assert(exp2f64(3.0f64) == 8.0f64);
	assert(exp2f64(-2.0f64) == 0.25f64);
	assert(!isinf(exp2f64(256.0f64)));
	assert(isinf(exp2f64(99999.0f64)));
	assert(exp2f64(-99999.0f64) == 0.0f64);
	assert(isnan(exp2f64(NAN)));
	assert(isinf(exp2f64(INF)));
	assert(exp2f64(-INF) == 0.0f64);
};

// __ieee754_sqrt(x)
// Return correctly rounded sqrt.
//           -----------------------------------------
//           | Use the hardware sqrt if you have one |
//           -----------------------------------------
// Method:
//   Bit by bit method using integer arithmetic. (Slow, but portable)
//   1. Normalization
//      Scale x to y in [1,4) with even powers of 2:
//      find an integer k such that  1 <= (y=x*2**(2k)) < 4, then
//              sqrt(x) = 2**k * sqrt(y)
//   2. Bit by bit computation
//      Let q  = sqrt(y) truncated to i bit after binary point (q = 1),
//           i                                                   0
//                                     i+1         2
//          s  = 2*q , and      y  =  2   * ( y - q  ).          (1)
//           i      i            i                 i
//
//      To compute q    from q , one checks whether
//                  i+1       i
//
//                            -(i+1) 2
//                      (q + 2      )  <= y.                     (2)
//                        i
//                                                            -(i+1)
//      If (2) is false, then q   = q ; otherwise q   = q  + 2      .
//                             i+1   i             i+1   i
//
//      With some algebraic manipulation, it is not difficult to see
//      that (2) is equivalent to
//                             -(i+1)
//                      s  +  2       <= y                       (3)
//                       i                i
//
//      The advantage of (3) is that s  and y  can be computed by
//                                    i      i
//      the following recurrence formula:
//          if (3) is false
//
//          s     =  s  ,       y    = y   ;                     (4)
//           i+1      i          i+1    i
//
//      otherwise,
//                         -i                      -(i+1)
//          s     =  s  + 2  ,  y    = y  -  s  - 2              (5)
//           i+1      i          i+1    i     i
//
//      One may easily use induction to prove (4) and (5).
//      Note. Since the left hand side of (3) contain only i+2 bits,
//            it is not necessary to do a full (53-bit) comparison
//            in (3).
//   3. Final rounding
//      After generating the 53 bits result, we compute one more bit.
//      Together with the remainder, we can decide whether the
//      result is exact, bigger than 1/2ulp, or less than 1/2ulp
//      (it will never equal to 1/2ulp).
//      The rounding mode can be detected by checking whether
//      huge + tiny is equal to huge, and whether huge - tiny is
//      equal to huge for some floating point number "huge" and "tiny".

// Returns the square root of x.
export fn sqrtf64(x: f64) f64 = {
	// Special cases
	if (x == 0.0f64) {
		return x;
	} else if (isnan(x) || isposinf(x)) {
		return x;
	} else if (x < 0.0f64) {
		return NAN;
	};

	let bits = f64bits(x);

	// Normalize x
	let exp = (((bits >> F64_MANTISSA_BITS) & F64_EXPONENT_MASK): i64);
	if (exp == 0i64) {
		// Subnormal x
		for (bits & (1 << F64_MANTISSA_BITS) == 0) {
			bits <<= 1;
			exp -= 1;
		};
		exp += 1;
	};
	// Unbias exponent
	exp -= (F64_EXPONENT_BIAS: i64);
	bits = bits & ~(F64_EXPONENT_MASK << F64_MANTISSA_BITS);
	bits = bits | (1u64 << (F64_MANTISSA_BITS: u64));
	// Odd exp, double x to make it even
	if (exp & 1i64 == 1i64) {
		bits <<= 1;
	};
	// exp = exp/2, exponent of square root
	exp >>= 1;
	// Generate sqrt(x) bit by bit
	bits <<= 1;
	// q = sqrt(x)
	let q = 0u64;
	let s = 0u64;
	// r = moving bit from MSB to LSB
	let r = ((1u64 << (F64_MANTISSA_BITS + 1u64)): u64);
	for (r != 0) {
		let t = s + r;
		if (t <= bits) {
			s = t + r;
			bits -= t;
			q += r;
		};
		bits <<= 1u64;
		r >>= 1u64;
	};
	// Final rounding
	if (bits != 0) {
		// Remainder, result not exact
		// Round according to extra bit
		q += q & 1;
	};
	// significand + biased exponent
	bits = (q >> 1) + (
		((exp - 1i64 + (F64_EXPONENT_BIAS: i64)): u64) <<
		F64_MANTISSA_BITS);
	return f64frombits(bits);
};

@test fn sqrt() void = {
	assert(sqrtf64(2.0f64) == SQRT_2);
	assert(sqrtf64(4.0f64) == 2.0f64);
	assert(sqrtf64(16.0f64) == 4.0f64);
	assert(sqrtf64(65536.0f64) == 256.0f64);
	assert(sqrtf64(powf64(123.0f64, 2.0f64)) == 123.0f64);
	assert(sqrtf64(0.0f64) == 0.0f64);
	assert(isnan(sqrtf64(NAN)));
	assert(isposinf(sqrtf64(INF)));
	assert(isnan(sqrtf64(-2.0f64)));
};

fn is_f64_odd_int(x: f64) bool = {
	let x_int_frac = modf64(x);
	let x_int = x_int_frac.0;
	let x_frac = x_int_frac.1;
	let has_no_frac = (x_frac == 0.0f64);
	let is_odd = ((x_int & 1i64) == 1i64);
	return has_no_frac && is_odd;
};

// Returns x^p.
export fn powf64(x: f64, p: f64) f64 = {
	if (x == 1.0f64 || p == 0.0f64) {
		return 1.0f64;
	} else if (p == 1.0f64) {
		return x;
	} else if (isnan(x)) {
		return NAN;
	} else if (isnan(p)) {
		return NAN;
	} else if (x == 0.0f64) {
		if (p < 0.0f64) {
			if (is_f64_odd_int(p)) {
				return copysignf64(INF, x);
			} else {
				return INF;
			};
		} else if (p > 0.0f64) {
			if (is_f64_odd_int(p)) {
				return x;
			} else {
				return 0.0f64;
			};
		};
	} else if (isinf(p)) {
		if (x == -1.0f64) {
			return 1.0f64;
		} else if ((absf64(x) < 1.0f64) == isposinf(p)) {
			return 0.0f64;
		};
		return INF;
	} else if (isinf(x)) {
		if (isneginf(x)) {
			return powf64(-0.0f64, -p);
		} else if (p < 0.0f64) {
			return 0.0f64;
		} else if (p > 0.0f64) {
			return INF;
		};
	} else if (p == 0.5f64) {
		return sqrtf64(x);
	} else if (p == -0.5f64) {
		return 1.0f64 / sqrtf64(x);
	};

	let x_parts = frexp(x);
	let x_mantissa = x_parts.0;
	let x_exp = x_parts.1;

	let p_int_frac = modf64(absf64(p));
	let p_int = p_int_frac.0;
	let p_frac = p_int_frac.1;

	let res_mantissa = 1.0f64;
	let res_exp = 0i64;

	// The method used later in this function doesn't apply to fractional
	// powers, so we have to handle these separately with
	// x^p = e^{p * ln(x)}
	if (p_frac != 0.0f64) {
		if (p_frac > 0.5f64) {
			p_frac -= 1.0f64;
			p_int += 1i64;
		};
		res_mantissa = expf64(p_frac * logf64(x));
	};

	// Repeatedly square our number x, for each bit in our power p.
	// If the current bit is 1 in p, add the respective power of x to our
	// result.
	for (let i = p_int; i != 0; i >>= 1) {
		// Check for over/underflow.
		if (x_exp <= -1i64 << (F64_EXPONENT_BITS: i64)) {
			return 0.0f64;
	};
		if (x_exp >= 1i64 << (F64_EXPONENT_BITS: i64)) {
			return INF;
		};
		// Perform squaring.
		if (i & 1i64 == 1i64) {
			res_mantissa *= x_mantissa;
			res_exp += x_exp;
		};
		x_mantissa *= x_mantissa;
		x_exp <<= 1;
		// Correct mantisa to be in [0.5, 1).
		if (x_mantissa < 0.5f64) {
			x_mantissa += x_mantissa;
			x_exp -= 1;
		};
	};

	if (p < 0.0f64) {
		res_mantissa = 1.0f64 / res_mantissa;
		res_exp = -res_exp;
	};

	let res = ldexpf64(res_mantissa, res_exp);
	return res;
};

@test fn powf64() void = {
	// Positive integer
	assert(powf64(2.0f64, 2.0f64) == 4.0f64);
	assert(powf64(3.0f64, 3.0f64) == 27.0f64);
	// Very large positive integer
	assert(!isinf(powf64(2.0f64, 1020.0f64)));
	assert(isinf(powf64(2.0f64, 1050.0f64)));
	// Negative integer
	assert(powf64(2.0f64, -1.0f64) == 0.5f64);
	assert(powf64(2.0f64, -2.0f64) == 0.25f64);
	// Very small negative integer
	assert(powf64(2.0f64, -1020.0f64) > 0.0f64);
	assert(powf64(2.0f64, -1080.0f64) == 0.0f64);
	// Positive fractional powers
	assert(eqwithin(powf64(2.0f64, 1.5f64),
		2.8284271247461900976033774f64,
		1e-10f64));
	assert(eqwithin(powf64(2.0f64, 5.5f64),
		45.254833995939041561654039f64,
		1e-10f64));
	// Negative fractional powers
	assert(eqwithin(powf64(2.0f64, -1.5f64),
		0.3535533905932737622004221f64,
		1e-10f64));
	assert(eqwithin(powf64(2.0f64, -5.5f64),
		0.0220970869120796101375263f64,
		1e-10f64));

	// Special cases
	// pow(x, ±0) = 1 for any x
	assert(powf64(123.0f64, 0.0f64) == 1.0f64);
	// pow(1, y) = 1 for any y
	assert(powf64(1.0f64, 123.0f64) == 1.0f64);
	// pow(x, 1) = x for any x
	assert(powf64(123.0f64, 1.0f64) == 123.0f64);
	// pow(NaN, y) = NaN
	assert(isnan(powf64(NAN, 123.0f64)));
	// pow(x, NaN) = NaN
	assert(isnan(powf64(123.0f64, NAN)));
	// pow(±0, y) = ±Inf for y an odd integer < 0
	assert(isposinf(powf64(0.0f64, -3.0f64)));
	assert(isneginf(powf64(-0.0f64, -3.0f64)));
	// pow(±0, -Inf) = +Inf
	assert(isposinf(powf64(0.0f64, -INF)));
	assert(isposinf(powf64(-0.0f64, -INF)));
	// pow(±0, +Inf) = +0
	assert(powf64(0.0f64, INF) == 0.0f64);
	assert(powf64(-0.0f64, INF) == 0.0f64);
	// pow(±0, y) = +Inf for finite y < 0 and not an odd integer
	assert(isposinf(powf64(0.0f64, -2.0f64)));
	assert(isposinf(powf64(-0.0f64, -2.0f64)));
	//pow(±0, y) = ±0 for y an odd integer > 0
	assert(powf64(0.0f64, 123.0f64) == 0.0f64);
	let neg_zero = powf64(-0.0f64, 123.0f64);
	assert(neg_zero == 0.0f64);
	assert(isnegative(neg_zero));
	// pow(±0, y) = +0 for finite y > 0 and not an odd integer
	assert(powf64(0.0f64, 8.0f64) == 0.0f64);
	// pow(-1, ±Inf) = 1
	assert(powf64(-1.0f64, INF) == 1.0f64);
	assert(powf64(-1.0f64, -INF) == 1.0f64);
	// pow(x, +Inf) = +Inf for |x| > 1
	assert(isposinf(powf64(123.0f64, INF)));
	// pow(x, -Inf) = +0 for |x| > 1
	assert(powf64(123.0f64, -INF) == 0.0f64);
	// pow(x, +Inf) = +0 for |x| < 1
	assert(powf64(0.5f64, INF) == 0.0f64);
	assert(powf64(-0.5f64, INF) == 0.0f64);
	// pow(x, -Inf) = +Inf for |x| < 1
	assert(isposinf(powf64(0.5f64, -INF)));
	assert(isposinf(powf64(-0.5f64, -INF)));
	// pow(+Inf, y) = +Inf for y > 0
	assert(isposinf(powf64(INF, 123.0f64)));
	// pow(+Inf, y) = +0 for y < 0
	assert(powf64(INF, -1.0f64) == 0.0f64);
	// pow(-Inf, y) = pow(-0, -y)
	assert(powf64(-INF, 123.0f64) == powf64(-0.0f64, -123.0f64));
	// pow(x, y) = NaN for finite x < 0 and finite non-integer y
	assert(isnan(powf64(-2.0f64, 1.23f64)));
	// sqrt
	assert(powf64(4.0f64, 0.5f64) == sqrtf64(4.0f64));
	assert(powf64(4.0f64, 0.5f64) == 2.0f64);
	assert(powf64(4.0f64, -0.5f64) == (1.0f64 / sqrtf64(4.0f64)));
	assert(powf64(4.0f64, -0.5f64) == (1.0f64 / 2.0f64));
};
