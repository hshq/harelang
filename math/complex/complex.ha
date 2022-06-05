// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>

// Sections of the code below are based on Go's implementation, which is, in
// turn, based on Cephes Math Library. The original C code can be found at
// http://netlib.sandia.gov/cephes/c9x-complex/.
//
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

use math;

// A complex number containing a real component and an imaginary component,
// represented as two single-precision floating point numbers.
export type c64 = (f32, f32);

// A complex number containing a real component and an imaginary component,
// represented as two double-precision floating point numbers.
export type c128 = (f64, f64);

// A tagged union of all complex types.
export type complex = (c64 | c128);

// Converts a [[c64]] to a [[c128]].
export fn c64to128(z: c64) c128 = (z.0: f64, z.1: f64);

// Truncates a [[c128]] to a [[c64]]. Precision may be lost.
export fn c128to64(z: c128) c64 = (z.0: f32, z.1: f32);

// Adds two complex numbers
export fn addc64(a: c64, b: c64) c64 = (a.0 + b.0, a.1 + b.1);

// Adds two complex numbers.
export fn addc128(a: c128, b: c128) c128 = (a.0 + b.0, a.1 + b.1);

// Subtracts two complex numbers.
export fn subc64(a: c64, b: c64) c64 = (a.0 - b.0, a.1 - b.1);

// Subtracts two complex numbers.
export fn subc128(a: c128, b: c128) c128 = (a.0 - b.0, a.1 - b.1);

// Multiplies two complex numbers.
export fn mulc64(a: c64, b: c64) c64 =
	(a.0 * b.0 - a.1 * b.1, a.1 * b.0 + a.0 * b.1);

// Multiplies two complex numbers.
export fn mulc128(a: c128, b: c128) c128 =
	(a.0 * b.0 - a.1 * b.1, a.1 * b.0 + a.0 * b.1);

// Divides two complex numbers.
export fn divc64(a: c64, b: c64) c64 = {
	const denom = b.0 * b.0 + b.1 * b.1;
	return (
		(a.0 * b.0 + a.1 * b.1) / denom,
		(a.1 * b.0 - a.0 * b.1) / denom,
	);
};

// Divides two complex numbers.
export fn divc128(a: c128, b: c128) c128 = {
	const denom = b.0 * b.0 + b.1 * b.1;
	return (
		(a.0 * b.0 + a.1 * b.1) / denom,
		(a.1 * b.0 - a.0 * b.1) / denom,
	);
};

// Takes the conjugate of a complex number by negating the imaginary component.
export fn conjc64(z: c64) c64 = (z.0, -z.1);

// Takes the conjugate of a complex number by negating the imaginary component.
export fn conjc128(z: c128) c128 = (z.0, -z.1);

// Takes the absolute value of a complex number.
export fn absc128(z: c128) f64 = math::hypotf64(z.0, z.1);

// Gets the argument, or phase, of a complex number.
export fn argc128(z: c128) f64 = math::atan2f64(z.1, z.0);

// Checks if two complex numbers are equal. Be sure to take floating point
// round-off errors into account.
export fn equalc64(a: c64, b: c64) bool = a.0 == b.0 && a.1 == b.1;

// Checks if two complex numbers are equal. Be sure to take floating point
// round-off errors into account.
export fn equalc128(a: c128, b: c128) bool = a.0 == b.0 && a.1 == b.1;

// Returns [[math::E]] raised to the power of z.
export fn expc128(z: c128) c128 = {
	if (math::isinf(z.0)) {
		if (z.0 > 0f64 && z.1 == 0f64) {
			return z;
		};
		if (math::isinf(z.1) || math::isnan(z.1)) {
			if (z.0 < 0f64) {
				return (0f64, math::copysignf64(0f64, z.1));
			} else {
				return (math::INF, math::NAN);
			};
		};
	} else if (math::isnan(z.0) && z.1 == 0f64) {
		return (math::NAN, z.1);
	};
	return rectc128(math::expf64(z.0), z.1);
};

// Returns true if the given complex number is infinite.
export fn isinf(z: c128) bool = math::isinf(z.0) || math::isinf(z.1);

// Returns true if the given complex number is NaN.
export fn isnan(z: c128) bool =
	!isinf(z) && (math::isnan(z.0) || math::isnan(z.1));

// Returns the natural logarithm of z.
export fn logc128(z: c128) c128 = (math::logf64(absc128(z)), argc128(z));

// Negates z.
export fn negc64(z: c64) c64 = (-z.0, -z.1);

// Negates z.
export fn negc128(z: c128) c128 = (-z.0, -z.1);

// Creates a new [[c128]] from the polar coordinates (r, theta).
export fn rectc128(r: f64, theta: f64) c128 =
	(r * math::cosf64(theta), r * math::sinf64(theta));

// Returns the polar coordinates of z.
export fn polarc128(z: c128) (f64, f64) = (absc128(z), argc128(z));

// Returns a raised to the power of b.
export fn powc128(a: c128, b: c128) c128 = {
	if (a.0 == 0f64 && a.1 == 0f64) {
		if (isnan(b)) {
			return (math::NAN, math::NAN);
		} else if (b.0 == 0f64) {
			return (1f64, 0f64);
		} else if (b.0 < 0f64) {
			return (math::INF, if (b.1 == 0f64) 0f64 else math::INF);
		} else {
			assert(b.0 > 0f64);
			return (0f64, 0f64);
		};
	};
	const mod = absc128(a);
	if (mod == 0f64) {
		return (0f64, 0f64);
	};
	let r = math::powf64(mod, b.0);
	const phase = argc128(a);
	let theta = b.0 * phase;
	if (b.1 != 0f64) {
		r *= math::expf64(-b.1 * phase);
		theta += b.1 * math::logf64(mod);
	};
	return rectc128(r, theta);
};

// Projects z onto the surface of a Riemann Sphere. If z is finite, it projects
// to itself. If z is infinite, it projects to positive infinity on the real
// axis.
export fn projc64(z: c64) c64 =
	if (!isinf(c64to128(z))) z else (math::INF, math::copysignf32(0f32, z.1));

// Projects z onto the surface of a Riemann Sphere. If z is finite, it projects
// to itself. If z is infinite, it projects to positive infinity on the real
// axis.
export fn projc128(z: c128) c128 =
	if (!isinf(z)) z else (math::INF, math::copysignf64(0f64, z.1));

// Returns the square root of z.
export fn sqrtc128(z: c128) c128 = {
	if (z.1 == 0f64) {
		if (z.0 == 0f64) {
			return (0f64, z.1);
		};
		if (z.0 < 0f64) {
			return (0f64, math::copysignf64(math::sqrtf64(-z.0), z.1));
		};
		return (math::sqrtf64(z.0), z.1);
	};
	if (math::isinf(z.1)) {
		return (math::INF, z.1);
	};
	if (z.0 == 0f64) {
		if (z.1 < 0f64) {
			const r = math::sqrtf64(-0.5 * z.1);
			return (r, -r);
		} else {
			const r = math::sqrtf64(0.5 * z.1);
			return (r, r);
		};
	};
	let a = z.0, b = z.1;
	const scale = if (math::absf64(a) > 4f64 || math::absf64(b) > 4f64) {
		a *= 0.25;
		b *= 0.25;
		yield 2f64;
	} else {
		a *= 1.8014398509481984e16; // 2**54
		b *= 1.8014398509481984e16;
		yield 7.450580596923828125e-9; // 2**-27
	};
	let r = math::hypotf64(a, b);
	const t = if (a > 0f64) {
		const t = math::sqrtf64(0.5 * r + 0.5 * a);
		r = scale * math::absf64(0.5 * b / t);
		yield t * scale;
	} else {
		r = math::sqrtf64(0.5 * r - 0.5 * a);
		const t = scale * math::absf64(0.5 * b / r);
		r *= scale;
		yield t;
	};
	return (t, if (b < 0f64) -r else r);
};

// Returns the sine of z, in radians.
export fn sinc128(z: c128) c128 = {
	if (z.1 == 0f64 && (math::isinf(z.0) || math::isnan(z.0))) {
		return (math::NAN, z.1);
	} else if (math::isinf(z.1)) {
		if (z.0 == 0f64) {
			return z;
		} else if (math::isinf(z.0) || math::isnan(z.0)) {
			return (math::NAN, z.1);
		};
	} else if (z.0 == 0f64 && math::isnan(z.1)) {
		return z;
	};
	const shch = sinhcosh(z.1);
	return (math::sinf64(z.0) * shch.1, math::cosf64(z.0) * shch.0);
};

// Returns the hyperbolic sine of z.
export fn sinhc128(z: c128) c128 = {
	if (z.0 == 0f64 && (math::isinf(z.1) || math::isnan(z.1))) {
		return (z.0, math::NAN);
	} else if (math::isinf(z.0)) {
		if (z.1 == 0f64) {
			return z;
		} else if (math::isinf(z.1) || math::isnan(z.1)) {
			return (z.0, math::NAN);
		};
	} else if (z.1 == 0f64 && math::isnan(z.0)) {
		return (math::NAN, z.1);
	};
	const shch = sinhcosh(z.0);
	return (math::cosf64(z.1) * shch.0, math::sinf64(z.1) * shch.1);
};

// Returns the arcsine, in radians, of z.
export fn asinc128(z: c128) c128 = {
	if (z.1 == 0f64 && math::absf64(z.0) <= 1f64) {
		return (math::asinf64(z.0), z.1);
	} else if (z.0 == 0f64 && math::absf64(z.1) <= 1f64) {
		return (z.0, math::asinhf64(z.1));
	} else if (math::isnan(z.1)) {
		if (z.0 == 0f64) {
			return (z.0, math::NAN);
		} else if (math::isinf(z.0)) {
			return (math::NAN, z.0);
		} else {
			return (math::NAN, math::NAN);
		};
	} else if (math::isinf(z.1)) {
		if (math::isnan(z.0)) {
			return z;
		} else if (math::isinf(z.0)) {
			return (math::copysignf64(math::PI / 4f64, z.0), z.1);
		} else {
			return (math::copysignf64(0f64, z.0), z.1);
		};
	} else if (math::isinf(z.0)) {
		return (math::copysignf64(math::PI / 2f64, z.0),
			math::copysignf64(z.0, z.1));
	};
	const ct = (-z.1, z.0); // i * z
	const zz = mulc128(z, z);
	const z1 = (1f64 - zz.0, -zz.1); // 1 - z * z
	const z2 = sqrtc128(z1); // z2 = sqrt(1 - z * z)
	const w = logc128(addc128(ct, z2));
	return (w.1, -w.0); // -i * w
};

// Returns the inverse hyperbolic sine of z.
export fn asinhc128(z: c128) c128 = {
	if (z.1 == 0f64 && math::absf64(z.0) <= 1f64) {
		return (math::asinhf64(z.0), z.1);
	} else if (z.0 == 0f64 && math::absf64(z.1) <= 1f64) {
		return (z.0, math::asinf64(z.1));
	} else if (math::isinf(z.0)) {
		if (math::isinf(z.1)) {
			return (z.0, math::copysignf64(math::PI / 4f64, z.1));
		} else if (math::isnan(z.1)) {
			return z;
		} else {
			return (z.0, math::copysignf64(0f64, z.1));
		};
	} else if (math::isnan(z.0)) {
		if (z.1 == 0f64) {
			return z;
		} else if (math::isinf(z.1)) {
			return (z.1, z.0);
		} else {
			return (math::NAN, math::NAN);
		};
	} else if (math::isinf(z.1)) {
		return (math::copysignf64(z.1, z.0),
			math::copysign(math::PI / 2f64, z.1));
	};
	const zz = mulc128(z, z);
	const z1 = (1f64 + zz.0, zz.1); // 1 + z * z
	return logc128(addc128(z, sqrtc128(z1))); // log(x + sqrt(1 + x * x))
};

// Returns the cosine of z, in radians.
export fn cosc128(z: c128) c128 = {
	if (z.1 == 0f64 && (math::isinf(z.0) || math::isnan(z.0))) {
		return (math::NAN, -z.1 * math::copysignf64(0f64, z.0));
	} else if (math::isinf(z.1)) {
		if (z.0 == 0f64) {
			return (math::INF, -z.0 * math::copysignf64(0f64, z.1));
		} else if (math::isinf(z.0) || math::isnan(z.0)) {
			return (math::INF, math::NAN);
		};
	} else if (z.0 == 0f64 && math::isnan(z.1)) {
		return (math::NAN, 0f64);
	};
	const shch = sinhcosh(z.1);
	return (math::cosf64(z.0) * shch.1, -math::sinf64(z.0) * shch.0);
};

// Returns the hyperbolic cosine of z.
export fn coshc128(z: c128) c128 = {
	if (z.0 == 0f64 && (math::isinf(z.1) || math::isnan(z.1))) {
		return (math::NAN, z.0 * math::copysignf64(0f64, z.1));
	} else if (math::isinf(z.0)) {
		if (z.1 == 0f64) {
			return (math::INF, z.1 * math::copysignf64(0f64, z.0));
		} else if (math::isinf(z.1) || math::isnan(z.1)) {
			return (math::INF, math::NAN);
		};
	} else if (z.1 == 0f64 && math::isnan(z.0)) {
		return (math::NAN, z.1);
	};
	const shch = sinhcosh(z.0);
	return (math::cosf64(z.1) * shch.1, math::sinf64(z.1) * shch.0);
};

// Returns the arccosine, in radians, of z.
export fn acosc128(z: c128) c128 = {
	const w = asinc128(z);
	return (math::PI / 2f64 - w.0, -w.1);
};

// Returns the inverse hyperbolic cosine of z.
export fn acoshc128(z: c128) c128 = {
	if (z.0 == 0f64 && z.1 == 0f64) {
		return (0f64, math::copysignf64(math::PI / 2f64, z.1));
	};
	const w = acosc128(z);
	if (w.1 <= 0f64) {
		return (-w.1, w.0); // i * w
	};
	return (w.1, -w.0); // -i * w
};

fn sinhcosh(x: f64) (f64, f64) = {
	if (math::absf64(x) <= 0.5) {
		return (math::sinhf64(x), math::coshf64(x));
	};
	let e = math::expf64(x);
	const ei = 0.5 / e;
	e *= 0.5;
	return (e - ei, e + ei);
};
