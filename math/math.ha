// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Sections of the code below, in particular log() and exp(), are based on Go's
// implementation, which is, in turn, based on FreeBSD's. The original C code,
// as well as the respective comments and constants are from
// /usr/src/lib/msun/src/{e_log,e_exp}.c.
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

// The standard tolerance used by isclose(), which is just an arbitrary way to
// measure whether two floating-point numbers are "sufficiently" close to each
// other.
export def STANDARD_TOL: f64 = 1e-14;

// Returns whether x and y are within tol of each other.
export fn eqwithinf64(x: f64, y: f64, tol: f64) bool = {
	if (isnan(x) || isnan(y) || isnan(tol)) {
		return false;
	};
	return absf64(x - y) < tol;
};

// Returns whether x and y are within tol of each other.
export fn eqwithinf32(x: f32, y: f32, tol: f32) bool = {
	if (isnan(x) || isnan(y) || isnan(tol)) {
		return false;
	};
	return absf32(x - y) < tol;
};

// Returns whether x and y are within tol of each other.
export fn eqwithin(
	x: types::floating,
	y: types::floating,
	tol: types::floating,
) bool = {
	match (x) {
	case let n: f64 =>
		return eqwithinf64(n, y as f64, tol as f64);
	case let n: f32 =>
		return eqwithinf32(n, y as f32, tol as f32);
	};
};

// Returns whether x and y are within [[STANDARD_TOL]] of each other.
export fn isclosef64(x: f64, y: f64) bool = {
	return eqwithinf64(x, y, STANDARD_TOL);
};

// Returns whether x and y are within [[STANDARD_TOL]] of each other.
export fn isclosef32(x: f32, y: f32) bool = {
	return eqwithinf32(x, y, STANDARD_TOL: f32);
};

// Returns whether x and y are within [[STANDARD_TOL]] of each other.
export fn isclose(x: types::floating, y: types::floating) bool = {
	match (x) {
	case let n: f64 =>
		return isclosef64(n, y as f64);
	case let n: f32 =>
		return isclosef32(n, y as f32);
	};
};

// e - https://oeis.org/A001113
export def E: f64 = 2.71828182845904523536028747135266249775724709369995957496696763;
// pi - https://oeis.org/A000796
export def PI: f64 = 3.14159265358979323846264338327950288419716939937510582097494459;
// tau - https://oeis.org/A019692
export def TAU: f64 = 6.2831853071795864769252867665590057683943387987502116419498892;
// phi - https://oeis.org/A001622
export def PHI: f64 = 1.61803398874989484820458683436563811772030917980576286213544862;
// sqrt(2) - https://oeis.org/A002193
export def SQRT_2: f64 = 1.41421356237309504880168872420969807856967187537694807317667974;
// sqrt(e) - https://oeis.org/A019774
export def SQRT_E: f64 = 1.64872127070012814684865078781416357165377610071014801157507931;
// sqrt(pi) - https://oeis.org/A002161
export def SQRT_PI: f64 = 1.77245385090551602729816748334114518279754945612238712821380779;
// sqrt(phi) - https://oeis.org/A139339
export def SQRT_PHI: f64 = 1.27201964951406896425242246173749149171560804184009624861664038;
// ln(2) - https://oeis.org/A002162
export def LN_2: f64 = 0.693147180559945309417232121458176568075500134360255254120680009;
// ln(2) - https://oeis.org/A002162
export def LN2_HI: f64 = 6.93147180369123816490e-01;
// ln(2) - https://oeis.org/A002162
export def LN2_LO: f64 = 1.90821492927058770002e-10;
// log_{2}(e)
export def LOG2_E: f64 = 1f64 / LN_2;
// ln(10) - https://oeis.org/A002392
export def LN_10: f64 = 2.30258509299404568401799145468436420760110148862877297603332790;
// log_{10}(e)
export def LOG10_E: f64 = 1f64 / LN_10;

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
	const L1 = 6.666666666666735130e-01; // 3fe55555 55555593
	const L2 = 3.999999999940941908e-01; // 3fd99999 9997fa04
	const L3 = 2.857142874366239149e-01; // 3fd24924 94229359
	const L4 = 2.222219843214978396e-01; // 3fcc71c5 1d8e78af
	const L5 = 1.818357216161805012e-01; // 3fc74664 96cb03de
	const L6 = 1.531383769920937332e-01; // 3fc39a09 d078c69f
	const L7 = 1.479819860511658591e-01; // 3fc2f112 df3e5244

	// special cases
	if (isnan(x) || x == INF) {
		return x;
	} else if (x < 0f64) {
		return NAN;
	} else if (x == 0f64) {
		return -INF;
	};

	// Reduce
	const f1_and_ki = frexp(x);
	let f1 = f1_and_ki.0;
	let ki = f1_and_ki.1;
	if (f1 < (SQRT_2 / 2f64)) {
		f1 *= 2f64;
		ki -= 1i64;
	};
	let f = f1 - 1f64;
	let k = (ki: f64);

	// Compute
	const s = f / (2f64 + f);
	const s2 = s * s;
	const s4 = s2 * s2;
	const t1 = s2 * (L1 + s4 * (L3 + s4 * (L5 + s4 * L7)));
	const t2 = s4 * (L2 + s4 * (L4 + s4 * L6));
	const R = t1 + t2;
	const hfsq = 0.5f64 * f * f;
	return k * LN2_HI - ((hfsq - (s * (hfsq + R) + k * LN2_LO)) - f);
};

// Returns the decimal logarithm of x.
export fn log10f64(x: f64) f64 = {
	return logf64(x) * (1f64 / LN_10);
};

// Returns the binary logarithm of x.
export fn log2f64(x: f64) f64 = {
	const frexp_res = frexpf64(x);
	let frac = frexp_res.0;
	let exp = frexp_res.1;
	// Make sure exact powers of two give an exact answer.
	// Don't depend on log(0.5) * (1 / LN_2) + exp being exactly exp - 1.
	if (frac == 0.5f64) {
		return ((exp - 1): f64);
	};
	return logf64(frac) * (1f64 / LN_2) + (exp: f64);
};

// double log1p(double x)
//
// Method :
//   1. Argument Reduction: find k and f such that
//                      1+x = 2**k * (1+f),
//         where  sqrt(2)/2 < 1+f < sqrt(2) .
//
//      Note. If k=0, then f=x is exact. However, if k!=0, then f
//      may not be representable exactly. In that case, a correction
//      term is need. Let u=1+x rounded. Let c = (1+x)-u, then
//      log(1+x) - log(u) ~ c/u. Thus, we proceed to compute log(u),
//      and add back the correction term c/u.
//      (Note: when x > 2**53, one can simply return log(x))
//
//   2. Approximation of log1p(f).
//      Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
//               = 2s + 2/3 s**3 + 2/5 s**5 + .....,
//               = 2s + s*R
//      We use a special Reme algorithm on [0,0.1716] to generate
//      a polynomial of degree 14 to approximate R The maximum error
//      of this polynomial approximation is bounded by 2**-58.45. In
//      other words,
//                      2      4      6      8      10      12      14
//          R(z) ~ LP1*s +LP2*s +LP3*s +LP4*s +LP5*s  +LP6*s  +LP7*s
//      (the values of LP1 to LP7 are listed in the program)
//      and
//          |      2          14          |     -58.45
//          | LP1*s +...+LP7*s    -  R(z) | <= 2
//          |                             |
//      Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
//      In order to guarantee error in log below 1ulp, we compute log
//      by
//              log1p(f) = f - (hfsq - s*(hfsq+R)).
//
//   3. Finally, log1p(x) = k*ln2 + log1p(f).
//                        = k*ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*ln2_lo)))
//      Here ln2 is split into two floating point number:
//                   ln2_hi + ln2_lo,
//      where n*ln2_hi is always exact for |n| < 2000.
//
// Special cases:
//      log1p(x) is NaN with signal if x < -1 (including -INF) ;
//      log1p(+INF) is +INF; log1p(-1) is -INF with signal;
//      log1p(NaN) is that NaN with no signal.
//
// Accuracy:
//      according to an error analysis, the error is always less than
//      1 ulp (unit in the last place).
//
// Constants:
// The hexadecimal values are the intended ones for the following
// constants. The decimal values may be used, provided that the
// compiler will convert from decimal to binary accurately enough
// to produce the hexadecimal values shown.
//
// Note: Assuming log() return accurate answer, the following
//       algorithm can be used to compute log1p(x) to within a few ULP:
//
//              u = 1+x;
//              if(u==1.0) return x ; else
//                         return log(u)*(x/(u-1.0));
//
//       See HP-15C Advanced Functions Handbook, p.193.

// Returns the natural logarithm of 1 plus its argument x.
// It is more accurate than log(1 + x) when x is near zero.
export fn log1pf64(x: f64) f64 = {
	// sqrt(2) - 1
	const SQRT2M1 = 4.142135623730950488017e-01; // 0x3fda827999fcef34
	// sqrt(2) / 2 - 1
	const SQRT2HALFM1 = -2.928932188134524755992e-01; // 0xbfd2bec333018866
	const SMALL = 1f64 / ((1i64 << 29): f64); // 2**-29
	const TINY = 1f64 / ((1i64 << 54): f64); // 2**-54
	const TWO53 = ((1i64 << 53): f64); // 2**53
	const LN2HI = 6.93147180369123816490e-01; // 3fe62e42fee00000
	const LN2LO = 1.90821492927058770002e-10; // 3dea39ef35793c76
	const LP1 = 6.666666666666735130e-01; // 3fe5555555555593
	const LP2 = 3.999999999940941908e-01; // 3fd999999997fa04
	const LP3 = 2.857142874366239149e-01; // 3fd2492494229359
	const LP4 = 2.222219843214978396e-01; // 3fcc71c51d8e78af
	const LP5 = 1.818357216161805012e-01; // 3fc7466496cb03de
	const LP6 = 1.531383769920937332e-01; // 3fc39a09d078c69f
	const LP7 = 1.479819860511658591e-01; // 3fc2f112df3e5244

	if (x < -1f64 || isnan(x)) {
		return NAN;
	} else if (x == -1f64) {
		return -INF;
	} else if (x == INF) {
		return INF;
	};

	const absx = absf64(x);

	let f = 0f64;
	let iu = 0u64;
	let k = 1i64;
	if (absx < SQRT2M1) { //  |x| < Sqrt(2)-1
		if (absx < SMALL) { // |x| < 2**-29
			if (absx < TINY) { // |x| < 2**-54
				return x;
			};
			return x - (x * x * 0.5f64);
		};
		if (x > SQRT2HALFM1) { // Sqrt(2)/2-1 < x
			// (Sqrt(2)/2-1) < x < (Sqrt(2)-1)
			k = 0;
			f = x;
			iu = 1;
		};
	};
	let c = 0f64;
	if (k != 0) {
		let u = 0f64;
		if (absx < TWO53) { // 1<<53
			u = 1.0 + x;
			iu = f64bits(u);
			k = (((iu >> 52) - 1023): i64);
			// Correction term
			if (k > 0) {
				c = 1f64 - (u - x);
			} else {
				c = x - (u - 1f64);
			};
			c /= u;
		} else {
			u = x;
			iu = f64bits(u);
			k = (((iu >> 52) - 1023): i64);
			c = 0f64;
		};
		iu &= 0x000fffffffffffff;
		if (iu < 0x0006a09e667f3bcd) { // Mantissa of Sqrt(2)
			// Normalize u
			u = f64frombits(iu | 0x3ff0000000000000);
		} else {
			k += 1;
			// Normalize u/2
			u = f64frombits(iu | 0x3fe0000000000000);
			iu = (0x0010000000000000 - iu) >> 2;
		};
		f = u - 1f64; // Sqrt(2)/2 < u < Sqrt(2)
	};
	const hfsq = 0.5 * f * f;
	let s = 0f64;
	let R = 0f64;
	let z = 0f64;
	if (iu == 0) { // |f| < 2**-20
		if (f == 0f64) {
			if (k == 0) {
				return 0f64;
			};
			c += (k: f64) * LN2LO;
			return (k: f64) * LN2HI + c;
		};
		R = hfsq * (1.0 - 0.66666666666666666 * f); // Avoid division
		if (k == 0) {
			return f - R;
		};
		return (k: f64) * LN2HI - ((R - ((k: f64) * LN2LO + c)) - f);
	};
	s = f / (2f64 + f);
	z = s * s;
	R = z * (LP1 +
		z * (LP2 +
		z * (LP3 +
		z * (LP4 +
		z * (LP5 +
		z * (LP6 +
		z * LP7))))));
	if (k == 0) {
		return f - (hfsq - s * (hfsq + R));
	};
	return (k: f64) * LN2HI -
		((hfsq - (s * (hfsq + R) + ((k: f64) * LN2LO + c))) - f);
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
	const P1 = 1.66666666666666657415e-01; // 0x3fc55555; 0x55555555
	const P2 = -2.77777777770155933842e-03; // 0xbf66c16c; 0X16bebd9n
	const P3 = 6.61375632143793436117e-05; // 0x3f11566a; 0Xaf25de2c
	const P4 = -1.65339022054652515390e-06; // 0xbebbbd41; 0Xc5d26bf1
	const P5 = 4.13813679705723846039e-08; // 0x3e663769; 0X72bea4d0

	let r = hi - lo;
	let t = r * r;
	let c = r - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5))));
	const y = 1f64 - ((lo - (r * c) / (2f64 - c)) - hi);
	return ldexpf64(y, k);
};

// Returns e^x.
export fn expf64(x: f64) f64 = {
	const overflow = 7.09782712893383973096e+02;
	const underflow = -7.45133219101941108420e+02;
	const near_zero = 1f64 / ((1i64 << 28i64): f64);

	if (isnan(x) || x == INF) {
		return x;
	} else if (x == -INF) {
		return 0f64;
	} else if (x > overflow) {
		return INF;
	} else if (x < underflow) {
		return 0f64;
	} else if (-near_zero < x && x < near_zero) {
		return 1f64 + x;
	};

	// Reduce; computed as r = hi - lo for extra precision.
	let k = 0i64;
	if (x < 0f64) {
		k = (((LOG2_E * x) - 0.5): i64);
	} else if (x > 0f64) {
		k = (((LOG2_E * x) + 0.5): i64);
	};
	const hi = x - ((k: f64) * LN2_HI);
	const lo = (k: f64) * LN2_LO;

	// Compute
	return expmultif64(hi, lo, k);
};

// Returns 2^x.
export fn exp2f64(x: f64) f64 = {
	const overflow = 1.0239999999999999e+03;
	const underflow = -1.0740e+03;

	if (isnan(x) || x == INF) {
		return x;
	} else if (x == -INF) {
		return 0f64;
	} else if (x > overflow) {
		return INF;
	} else if (x < underflow) {
		return 0f64;
	};

	// Argument reduction; x = r×lg(e) + k with |r| ≤ ln(2)/2.
	// Computed as r = hi - lo for extra precision.
	let k = 0i64;
	if (x > 0f64) {
		k = ((x + 0.5): i64);
	} else if (x < 0f64) {
		k = ((x - 0.5): i64);
	};
	const t = x - (k: f64);
	const hi = t * LN2_HI;
	const lo = -t * LN2_LO;

	// Compute
	return expmultif64(hi, lo, k);
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
	if (x == 0f64) {
		return x;
	} else if (isnan(x) || x == INF) {
		return x;
	} else if (x < 0f64) {
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
		const t = s + r;
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

fn is_f64_odd_int(x: f64) bool = {
	const (x_int, x_frac) = modfracf64(x);
	const has_no_frac = (x_frac == 0f64);
	const is_odd = ((x_int: i64 & 1i64) == 1i64);
	return has_no_frac && is_odd;
};

// Returns x^p.
export fn powf64(x: f64, p: f64) f64 = {
	if (x == 1f64 || p == 0f64) {
		return 1f64;
	} else if (p == 1f64) {
		return x;
	} else if (isnan(x)) {
		return NAN;
	} else if (isnan(p)) {
		return NAN;
	} else if (x == 0f64) {
		if (p < 0f64) {
			if (is_f64_odd_int(p)) {
				return copysignf64(INF, x);
			} else {
				return INF;
			};
		} else if (p > 0f64) {
			if (is_f64_odd_int(p)) {
				return x;
			} else {
				return 0f64;
			};
		};
	} else if (isinf(p)) {
		if (x == -1f64) {
			return 1f64;
		} else if ((absf64(x) < 1f64) == (p == INF)) {
			return 0f64;
		};
		return INF;
	} else if (isinf(x)) {
		if (x == -INF) {
			return powf64(-0f64, -p);
		} else if (p < 0f64) {
			return 0f64;
		} else if (p > 0f64) {
			return INF;
		};
	} else if (p == 0.5f64) {
		return sqrtf64(x);
	} else if (p == -0.5f64) {
		return 1f64 / sqrtf64(x);
	};

	let (p_int, p_frac) = modfracf64(absf64(p));
	if (p_frac != 0f64 && x < 0f64) {
		return NAN;
	};
	if (p_int > types::I64_MAX: f64) {
		if (x == -1f64) {
			return 1f64;
		} else if ((absf64(x) < 1f64) == (p > 0f64)) {
			return 0f64;
		} else {
			return INF;
		};
	};

	let res_mantissa = 1f64;
	let res_exp = 0i64;

	// The method used later in this function doesn't apply to fractional
	// powers, so we have to handle these separately with
	// x^p = e^{p * ln(x)}
	if (p_frac != 0f64) {
		if (p_frac > 0.5f64) {
			p_frac -= 1f64;
			p_int += 1f64;
		};
		res_mantissa = expf64(p_frac * logf64(x));
	};

	// Repeatedly square our number x, for each bit in our power p.
	// If the current bit is 1 in p, add the respective power of x to our
	// result.
	let (x_mantissa, x_exp) = frexp(x);
	for (let i = p_int: i64; i != 0; i >>= 1) {
		// Check for over/underflow.
		if (x_exp <= -1i64 << (F64_EXPONENT_BITS: i64)) {
			return 0f64;
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

	if (p < 0f64) {
		res_mantissa = 1f64 / res_mantissa;
		res_exp = -res_exp;
	};

	return ldexpf64(res_mantissa, res_exp);
};

// Returns the greatest integer value less than or equal to x.
export fn floorf64(x: f64) f64 = {
	if (x == 0f64 || isnan(x) || isinf(x)) {
		return x;
	};
	if (x < 0f64) {
		let (int_part, frac_part) = modfracf64(-x);
		if (frac_part != 0f64) {
			int_part += 1f64;
		};
		return -int_part;
	};
	return modfracf64(x).0;
};

// Returns the least integer value greater than or equal to x.
export fn ceilf64(x: f64) f64 = -floorf64(-x);

// Returns the integer value of x.
export fn truncf64(x: f64) f64 = {
	if (x == 0f64 || isnan(x) || isinf(x)) {
		return x;
	};
	return modfracf64(x).0;
};

// Returns the nearest integer, rounding half away from zero.
export fn roundf64(x: f64) f64 = {
	let bits = f64bits(x);
	let e = (bits >> F64_MANTISSA_BITS) & F64_EXPONENT_MASK;
	if (e < F64_EXPONENT_BIAS) {
		// Round abs(x) < 1 including denormals.
		bits &= F64_SIGN_MASK; // +-0
		if (e == F64_EXPONENT_BIAS - 1) {
			bits |= F64_ONE; // +-1
		};
	} else if (e < F64_EXPONENT_BIAS + F64_MANTISSA_BITS) {
		// Round any abs(x) >= 1 containing a fractional component
		// [0,1).
		// Numbers with larger exponents are returned unchanged since
		// they must be either an integer, infinity, or NaN.
		const half = 1 << (F64_MANTISSA_BITS - 1);
		e -= F64_EXPONENT_BIAS;
		bits += half >> e;
		bits = bits & ~(F64_MANTISSA_MASK >> e);
	};
	return f64frombits(bits);
};

// Returns the floating-point remainder of x / y. The magnitude of the result
// is less than y and its sign agrees with that of x.
export fn modf64(x: f64, y: f64) f64 = {
	if (y == 0f64) {
		return NAN;
	};
	if (isinf(x) || isnan(x) || isnan(y)) {
		return NAN;
	};

	y = absf64(y);

	const y_frexp = frexpf64(y);
	const y_frac = y_frexp.0;
	const y_exp = y_frexp.1;
	let r = x;
	if (x < 0f64) {
		r = -x;
	};

	for (r >= y) {
		const r_frexp = frexpf64(r);
		const r_frac = r_frexp.0;
		let r_exp = r_frexp.1;
		if (r_frac < y_frac) {
			r_exp -= 1i64;
		};
		r = r - ldexpf64(y, r_exp - y_exp);
	};
	if (x < 0f64) {
		r = -r;
	};
	return r;
};
