// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Ported from BearSSL
//
// Copyright (c) 2017 Thomas Pornin <pornin@bolet.org>
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

use bytes;
use crypto::math::*;
use crypto::bigint::*;
use io;


type curveparams = struct {
	p: []word,
	b: []word,
	r2: []word,
	p0i: word,
	pointlen: size,
	g: []u8,
};

// Parameters for supported curves (field modulus, and 'b' equation
// parameter; both values use the 'i31' format, and 'b' is in Montgomery
// representation).
const p384params = curveparams {
	p = [
		0x0000018C, 0x7FFFFFFF, 0x00000001, 0x00000000, 0x7FFFFFF8,
		0x7FFFFFEF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
		0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x00000FFF
	],
	b = [
		0x0000018C, 0x6E666840, 0x070D0392, 0x5D810231, 0x7651D50C,
		0x17E218D6, 0x1B192002, 0x44EFE441, 0x3A524E2B, 0x2719BA5F,
		0x41F02209, 0x36C5643E, 0x5813EFFE, 0x000008A5
	],
	r2 = [
		0x0000018C, 0x00000000, 0x00000080, 0x7FFFFE00, 0x000001FF,
		0x00000800, 0x00000000, 0x7FFFE000, 0x00001FFF, 0x00008000,
		0x00008000, 0x00000000, 0x00000000, 0x00000000
	],
	p0i = 0x00000001,
	pointlen = 97,
	g = [ // XXX: use P384_G, when possible
		0x04, 0xaa, 0x87, 0xca, 0x22, 0xbe, 0x8b, 0x05, 0x37, 0x8e,
		0xb1, 0xc7, 0x1e, 0xf3, 0x20, 0xad, 0x74, 0x6e, 0x1d, 0x3b,
		0x62, 0x8b, 0xa7, 0x9b, 0x98, 0x59, 0xf7, 0x41, 0xe0, 0x82,
		0x54, 0x2a, 0x38, 0x55, 0x02, 0xf2, 0x5d, 0xbf, 0x55, 0x29,
		0x6c, 0x3a, 0x54, 0x5e, 0x38, 0x72, 0x76, 0x0a, 0xb7, 0x36,
		0x17, 0xde, 0x4a, 0x96, 0x26, 0x2c, 0x6f, 0x5d, 0x9e, 0x98,
		0xbf, 0x92, 0x92, 0xdc, 0x29, 0xf8, 0xf4, 0x1d, 0xbd, 0x28,
		0x9a, 0x14, 0x7c, 0xe9, 0xda, 0x31, 0x13, 0xb5, 0xf0, 0xb8,
		0xc0, 0x0a, 0x60, 0xb1, 0xce, 0x1d, 0x7e, 0x81, 0x9d, 0x7a,
		0x43, 0x1d, 0x7c, 0x90, 0xea, 0x0e, 0x5f,
	],
};

const p521params = curveparams {
	p = [
		0x00000219, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
		0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
		0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
		0x7FFFFFFF, 0x7FFFFFFF, 0x01FFFFFF
	],
	b = [
		0x00000219, 0x540FC00A, 0x228FEA35, 0x2C34F1EF, 0x67BF107A,
		0x46FC1CD5, 0x1605E9DD, 0x6937B165, 0x272A3D8F, 0x42785586,
		0x44C8C778, 0x15F3B8B4, 0x64B73366, 0x03BA8B69, 0x0D05B42A,
		0x21F929A2, 0x2C31C393, 0x00654FAE
	],
	r2 = [
		0x00000219, 0x00001000, 0x00000000, 0x00000000, 0x00000000,
		0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
		0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
		0x00000000, 0x00000000, 0x00000000
	],
	p0i = 0x00000001,
	pointlen = 133,
	g = [ // XXX: use P384_G, when possible
		0x04, 0x00, 0xC6, 0x85, 0x8E, 0x06, 0xB7, 0x04, 0x04, 0xE9,
		0xCD, 0x9E, 0x3E, 0xCB, 0x66, 0x23, 0x95, 0xB4, 0x42, 0x9C,
		0x64, 0x81, 0x39, 0x05, 0x3F, 0xB5, 0x21, 0xF8, 0x28, 0xAF,
		0x60, 0x6B, 0x4D, 0x3D, 0xBA, 0xA1, 0x4B, 0x5E, 0x77, 0xEF,
		0xE7, 0x59, 0x28, 0xFE, 0x1D, 0xC1, 0x27, 0xA2, 0xFF, 0xA8,
		0xDE, 0x33, 0x48, 0xB3, 0xC1, 0x85, 0x6A, 0x42, 0x9B, 0xF9,
		0x7E, 0x7E, 0x31, 0xC2, 0xE5, 0xBD, 0x66, 0x01, 0x18, 0x39,
		0x29, 0x6A, 0x78, 0x9A, 0x3B, 0xC0, 0x04, 0x5C, 0x8A, 0x5F,
		0xB4, 0x2C, 0x7D, 0x1B, 0xD9, 0x98, 0xF5, 0x44, 0x49, 0x57,
		0x9B, 0x44, 0x68, 0x17, 0xAF, 0xBD, 0x17, 0x27, 0x3E, 0x66,
		0x2C, 0x97, 0xEE, 0x72, 0x99, 0x5E, 0xF4, 0x26, 0x40, 0xC5,
		0x50, 0xB9, 0x01, 0x3F, 0xAD, 0x07, 0x61, 0x35, 0x3C, 0x70,
		0x86, 0xA2, 0x72, 0xC2, 0x40, 0x88, 0xBE, 0x94, 0x76, 0x9F,
		0xD1, 0x66, 0x50,
	],
};

@test fn bigint_support() void = {
	// This is a port of the i31 variant from BearSSL. Word must be an u32
	// in order for this code to work.
	static assert(size(word) == 4);
};

def MAX_COORDSZ = (MAX_COORDBITSZ + 61) / 31;

type prime_jacobian = struct {
	// TODO things would be a lot easier if this is a flat array
	c: [3][MAX_COORDSZ]word,
};
type reg = []word;

// XXX: BearSSL is using memcpy. Can I do this here also?
fn jcpy(d: *prime_jacobian, a: *prime_jacobian) void = {
	for (let i = 0z; i < len(d.c); i += 1) {
		d.c[i][..] = a.c[i][..]; // XXX: is this copy ct?
	};
};

fn jccpy(ctl: u32, d: *prime_jacobian, a: *prime_jacobian) void = {
	for (let i = 0z; i < len(d.c); i += 1) {
		ccopyu32(ctl, d.c[i]: []u32, a.c[i][..]: []u32);
	};
};

fn mset(d: reg, a: reg) void = {
	for (let i = 0z; i < len(d); i += 1) {
		d[i] = a[i];
	};
};

fn madd(d: reg, a: reg, cc: *curveparams) void = {
	let ctl = add(d, a, 1);
	ctl |= notu32(sub(d, cc.p, 0));
	sub(d, cc.p, ctl);
};

fn msub(d: reg, a: reg, cc: *curveparams) void = {
	add(d, cc.p, sub(d, a, 1));
};

fn mmul(d: reg, a: reg, b: reg, cc: *curveparams) void = {
	montymul(d, a, b, cc.p, cc.p0i);
};

fn minv(d: reg, a: reg, b: reg, cc: *curveparams) void = {
	let tp: [MAX_POINTSZ / 2]u8 = [0...];
	let plen = (cc.p[0] - (cc.p[0] >> 5) + 7) >> 3;
	decode(tp[..plen], cc.p);
	tp[plen - 1] -= 2;

	// XXX: change modpow to use two bigints as buf, like it was intended
	let buf: [2 * MAX_COORDSZ]word = [0...];
	modpow(d, tp[..plen], cc.p, cc.p0i, buf);
};

fn prime_zero(p: *prime_jacobian, cc: *curveparams) void = {
	for (let i = 0z; i < len(p.c); i += 1) {
		for (let j = 0z; j < len(p.c[i]); j += 1) {
			p.c[i][j] = 0;
		};
	};

	p.c[0][0] = cc.p[0];
	p.c[1][0] = cc.p[0];
	p.c[2][0] = cc.p[0];
};

// Doubling formulas are:
//
//   s = 4*x*y^2
//   m = 3*(x + z^2)*(x - z^2)
//   x' = m^2 - 2*s
//   y' = m*(s - x') - 8*y^4
//   z' = 2*y*z
//
// If y = 0 (P has order 2) then this yields infinity (z' = 0), as it
// should. This case should not happen anyway, because our curves have
// prime order, and thus do not contain any point of order 2.
//
// If P is infinity (z = 0), then again the formulas yield infinity,
// which is correct. Thus, this code works for all points.
//
// Cost: 8 multiplications
fn point_double(p: *prime_jacobian, cc: *curveparams) void = {
	let px: [MAX_COORDSZ]word = p.c[0];
	let py: [MAX_COORDSZ]word = p.c[1];
	let pz: [MAX_COORDSZ]word = p.c[2];
	let t1: [MAX_COORDSZ]word = [0...];
	let t2: [MAX_COORDSZ]word = [0...];
	let t3: [MAX_COORDSZ]word = [0...];
	let t4: [MAX_COORDSZ]word = [0...];

	// Compute z^2 (in t1).
	mmul(t1, pz, pz, cc);

	// Compute x-z^2 (in t2) and then x+z^2 (in t1).
	mset(t2, px);
	msub(t2, t1, cc);
	madd(t1, px, cc);

	// Compute m = 3*(x+z^2)*(x-z^2) (in t1).
	mmul(t3, t1, t2, cc);
	mset(t1, t3);
	madd(t1, t3, cc);
	madd(t1, t3, cc);

	// Compute s = 4*x*y^2 (in t2) and 2*y^2 (in t3).
	mmul(t3, py, py, cc);
	madd(t3, t3, cc);
	mmul(t2, px, t3, cc);
	madd(t2, t2, cc);

	// Compute x' = m^2 - 2*s.
	mmul(px, t1, t1, cc);
	msub(px, t2, cc);
	msub(px, t2, cc);

	// Compute z' = 2*y*z.
	mmul(t4, py, pz, cc);
	mset(pz, t4);
	madd(pz, t4, cc);

	// Compute y' = m*(s - x') - 8*y^4. Note that we already have
	// 2*y^2 in t3.
	msub(t2, px, cc);
	mmul(py, t1, t2, cc);
	mmul(t4, t3, t3, cc);
	msub(py, t4, cc);
	msub(py, t4, cc);

	// copy back result
	p.c[0][..] = px[..];
	p.c[1][..] = py[..];
	p.c[2][..] = pz[..];
};

// Addtions formulas are:
//
//   u1 = x1 * z2^2
//   u2 = x2 * z1^2
//   s1 = y1 * z2^3
//   s2 = y2 * z1^3
//   h = u2 - u1
//   r = s2 - s1
//   x3 = r^2 - h^3 - 2 * u1 * h^2
//   y3 = r * (u1 * h^2 - x3) - s1 * h^3
//   z3 = h * z1 * z2
//
// If both P1 and P2 are infinity, then z1 == 0 and z2 == 0, implying that
// z3 == 0, so the result is correct.
// If either of P1 or P2 is infinity, but not both, then z3 == 0, which is
// not correct.
// h == 0 only if u1 == u2; this happens in two cases:
// -- if s1 == s2 then P1 and/or P2 is infinity, or P1 == P2
// -- if s1 != s2 then P1 + P2 == infinity (but neither P1 or P2 is infinity)
//
// Thus, the following situations are not handled correctly:
// -- P1 = 0 and P2 != 0
// -- P1 != 0 and P2 = 0
// -- P1 = P2
// All other cases are properly computed. However, even in "incorrect"
// situations, the three coordinates still are properly formed field
// elements.
//
// The returned flag is cleared if r == 0. This happens in the following
// cases:
// -- Both points are on the same horizontal line (same Y coordinate).
// -- Both points are infinity.
// -- One point is infinity and the other is on line Y = 0.
// The third case cannot happen with our curves (there is no valid point
// on line Y = 0 since that would be a point of order 2). If the two
// source points are non-infinity, then remains only the case where the
// two points are on the same horizontal line.
//
// This allows us to detect the "P1 == P2" case, assuming that P1 != 0 and
// P2 != 0:
// -- If the returned value is not the point at infinity, then it was properly
// computed.
// -- Otherwise, if the returned flag is 1, then P1+P2 = 0, and the result
// is indeed the point at infinity.
// -- Otherwise (result is infinity, flag is 0), then P1 = P2 and we should
// use the 'double' code.
//
// Cost: 16 multiplications
fn point_add(p1: *prime_jacobian, p2: *prime_jacobian, cc: *curveparams) u32 = {
	let p1x: [MAX_COORDSZ]word = p1.c[0];
	let p1y: [MAX_COORDSZ]word = p1.c[1];
	let p1z: [MAX_COORDSZ]word = p1.c[2];
	let p2x: [MAX_COORDSZ]word = p2.c[0];
	let p2y: [MAX_COORDSZ]word = p2.c[1];
	let p2z: [MAX_COORDSZ]word = p2.c[2];
	let t1: [MAX_COORDSZ]word = [0...];
	let t2: [MAX_COORDSZ]word = [0...];
	let t3: [MAX_COORDSZ]word = [0...];
	let t4: [MAX_COORDSZ]word = [0...];
	let t5: [MAX_COORDSZ]word = [0...];
	let t6: [MAX_COORDSZ]word = [0...];
	let t7: [MAX_COORDSZ]word = [0...];

	let r: u32 = 1;

	// Compute u1 = x1*z2^2 (in t1) and s1 = y1*z2^3 (in t3).
	mmul(t3, p2z, p2z, cc);
	mmul(t1, p1x, t3, cc);
	mmul(t4, p2z, t3, cc);
	mmul(t3, p1y, t4, cc);

	// Compute u2 = x2*z1^2 (in t2) and s2 = y2*z1^3 (in t4).
	mmul(t4, p1z, p1z, cc);
	mmul(t2, p2x, t4, cc);
	mmul(t5, p1z, t4, cc);
	mmul(t4, p2y, t5, cc);

	// Compute h = u2 - u1 (in t2) and r = s2 - s1 (in t4).
	msub(t2, t1, cc);
	msub(t4, t3, cc);

	// Report cases where r = 0 through the returned flag.
	r &= ~iszero(t4);

	// Compute u1*h^2 (in t6) and h^3 (in t5).
	mmul(t7, t2, t2, cc);
	mmul(t6, t1, t7, cc);
	mmul(t5, t7, t2, cc);

	// Compute x3 = r^2 - h^3 - 2*u1*h^2.
	// t1 and t7 can be used as scratch registers.
	mmul(p1x, t4, t4, cc);
	msub(p1x, t5, cc);
	msub(p1x, t6, cc);
	msub(p1x, t6, cc);

	// Compute y3 = r*(u1*h^2 - x3) - s1*h^3.
	msub(t6, p1x, cc);
	mmul(p1y, t4, t6, cc);
	mmul(t1, t5, t3, cc);
	msub(p1y, t1, cc);

	// Compute z3 = h*z1*z2.
	mmul(t1, p1z, p2z, cc);
	mmul(p1z, t1, t2, cc);

	// copy back result
	p1.c[0][..] = p1x[..];
	p1.c[1][..] = p1y[..];
	p1.c[2][..] = p1z[..];

	return r;
};

// Check that the point is on the curve. This code snippet assumes the
// following conventions:
// -- Coordinates x and y have been freshly decoded in P1 (but not
// converted to Montgomery coordinates yet).
// -- P2x, P2y and P2z are set to, respectively, R^2, b*R and 1.
fn prime_check(p1: *prime_jacobian, p2: *prime_jacobian, cc: *curveparams) u32 = {
	let p1x: [MAX_COORDSZ]word = p1.c[0];
	let p1y: [MAX_COORDSZ]word = p1.c[1];
	let p1z: [MAX_COORDSZ]word = p1.c[2];
	let p2x: [MAX_COORDSZ]word = p2.c[0];
	let p2y: [MAX_COORDSZ]word = p2.c[1];
	let p2z: [MAX_COORDSZ]word = p2.c[2];
	let t1: [MAX_COORDSZ]word = [0...];
	let t2: [MAX_COORDSZ]word = [0...];

	let r: u32 = 1;

	// Convert x and y to Montgomery representation.
	mmul(t1, p1x, p2x, cc);
	mmul(t2, p1y, p2x, cc);
	mset(p1x, t1);
	mset(p1y, t2);

	// Compute x^3 in t1. */
	mmul(t2, p1x, p1x, cc);
	mmul(t1, p1x, t2, cc);

	// Subtract 3*x from t1. */
	msub(t1, p1x, cc);
	msub(t1, p1x, cc);
	msub(t1, p1x, cc);

	// Add b. */
	madd(t1, p2y, cc);

	// Compute y^2 in t2. */
	mmul(t2, p1y, p1y, cc);

	// Compare y^2 with x^3 - 3*x + b; they must match. */
	msub(t1, t2, cc);
	r &= ~iszero(t1);

	// Set z to 1 (in Montgomery representation). */
	mmul(p1z, p2x, p2z, cc);

	// copy back result
	p1.c[0][..] = p1x[..];
	p1.c[1][..] = p1y[..];
	p1.c[2][..] = p1z[..];

	return r;
};

// Conversion back to affine coordinates. This code snippet assumes that
// the z coordinate of P2 is set to 1 (not in Montgomery representation).
fn prime_affine(p1: *prime_jacobian, p2: *prime_jacobian, cc: *curveparams) void = {
	let p1x: [MAX_COORDSZ]word = p1.c[0];
	let p1y: [MAX_COORDSZ]word = p1.c[1];
	let p1z: [MAX_COORDSZ]word = p1.c[2];
	let p2x: [MAX_COORDSZ]word = p2.c[0];
	let p2y: [MAX_COORDSZ]word = p2.c[1];
	let p2z: [MAX_COORDSZ]word = p2.c[2];
	let t1: [MAX_COORDSZ]word = [0...];
	let t2: [MAX_COORDSZ]word = [0...];
	let t3: [MAX_COORDSZ]word = [0...];
	let t4: [MAX_COORDSZ]word = [0...];
	let t5: [MAX_COORDSZ]word = [0...];
	let t6: [MAX_COORDSZ]word = [0...];
	let t7: [MAX_COORDSZ]word = [0...];

	let r: u32 = 1;

	// Save z*R in t1. */
	mset(t1, p1z);

	// Compute z^3 in t2. */
	mmul(t2, p1z, p1z, cc);
	mmul(t3, p1z, t2, cc);
	mmul(t2, t3, p2z, cc);

	// Invert to (1/z^3) in t2. */
	minv(t2, t3, t4, cc);

	// Compute y. */
	mset(t3, p1y);
	mmul(p1y, t2, t3, cc);

	// Compute (1/z^2) in t3. */
	mmul(t3, t2, t1, cc);

	// Compute x. */
	mset(t2, p1x);
	mmul(p1x, t2, t3, cc);

	// copy back result
	p1.c[0][..] = p1x[..];
	p1.c[1][..] = p1y[..];
	p1.c[2][..] = p1z[..];
};

fn prime_setone(x: []word, p: []word) void = {
	for (let i = 0z; i < len(x); i += 1) {
		x[i] = 0;
	};
	x[0] = p[0];
	x[1] = 1;
};

fn prime_pointzero(p: *prime_jacobian) void = {
	// XXX: bytes::zero?
	for (let i = 0z; i < len(p.c); i += 1) {
		for (let j = 0z; j < len(p.c[i]); j += 1) {
			p.c[i][j] = 0;
		};
	};
};

fn point_mul(p: *prime_jacobian, x: []u8, cc: *curveparams) void = {
	// We do a simple double-and-add ladder with a 2-bit window
	// to make only one add every two doublings. We thus first
	// precompute 2P and 3P in some local buffers.
	//
	// We always perform two doublings and one addition; the
	// addition is with P, 2P and 3P and is done in a temporary
	// array.
	//
	// The addition code cannot handle cases where one of the
	// operands is infinity, which is the case at the start of the
	// ladder. We therefore need to maintain a flag that controls
	// this situation.
	let p2 = prime_jacobian { ... };
	let p3 = prime_jacobian { ... };
	let q = prime_jacobian { ... };
	let t = prime_jacobian { ... };
	let u = prime_jacobian { ... };

	jcpy(&p2, p);
	point_double(&p2, cc);

	jcpy(&p3, p);
	point_add(&p3, &p2, cc);

	prime_zero(&q, cc);
	let qz: u32 = 1;
	for (let i = 0z; i < len(x); i += 1) {
		for (let k: i32 = 6; k >= 0; k -= 2) {
			point_double(&q, cc);
			point_double(&q, cc);
			jcpy(&t, p);
			jcpy(&u, &q);
			let bits: u32 = (x[i]: u32 >> k: u32) & 3;
			let bnz: u32 = nequ32(bits, 0);
			jccpy(equ32(bits, 2), &t, &p2);
			jccpy(equ32(bits, 3), &t, &p3);
			point_add(&u, &t, cc);
			jccpy(bnz & qz, &q, &t);
			jccpy(bnz & ~qz, &q, &u);
			qz &= ~bnz;
		};
	};
	jcpy(p, &q);
};

// Decode point into Jacobian coordinates. This function does not support
// the point at infinity. If the point is invalid then this returns 0, but
// the coordinates are still set to properly formed field elements.
fn point_decode(p: *prime_jacobian, src: []u8, cc: *curveparams) u32 = {
	// Points must use uncompressed format:
	// -- first byte is 0x04;
	// -- coordinates X and Y use unsigned big-endian, with the same
	//    length as the field modulus.
	//
	// We don't support hybrid format (uncompressed, but first byte
	// has value 0x06 or 0x07, depending on the least significant bit
	// of Y) because it is rather useless, and explicitly forbidden
	// by PKIX (RFC 5480, section 2.2).
	//
	// We don't support compressed format either, because it is not
	// much used in practice (there are or were patent-related
	// concerns about point compression, which explains the lack of
	// generalised support). Also, point compression support would
	// need a bit more code.
	let q = prime_jacobian { ... };

	let buf = src;
	prime_pointzero(p);
	let plen: size = (cc.p[0] - (cc.p[0] >> 5) + 7) >> 3;
	if (len(src) != 1 + (plen << 1)) {
		return 0;
	};
	let r: u32 = encodemod(p.c[0], buf[1..1 + plen], cc.p);
	r &= encodemod(p.c[1], buf[1 + plen..1 + 2*plen], cc.p);

	// Check first byte.
	r &= equ32(buf[0], 0x04);

	// Convert coordinates and check that the point is valid.
	let zlen: size = ((cc.p[0] + 63) >> 5);

	q.c[0][..zlen] = cc.r2[..zlen];
	q.c[1][..zlen] = cc.b[..zlen];
	prime_setone(q.c[2], cc.p);

	r &= ~prime_check(p, &q, cc);
	return r;
};

// Encode a point. This method assumes that the point is correct and is
// not the point at infinity. Encoded size is always 1+2*plen, where
// plen is the field modulus length, in bytes.
fn point_encode(dest: []u8, p: *prime_jacobian, cc: *curveparams) void = {
	let q = prime_jacobian { ... };
	let t = prime_jacobian { ... };

	let xbl: u32 = cc.p[0];
	xbl -= (xbl >> 5);
	let plen: size = (xbl + 7) >> 3;
	dest[0] = 0x04;
	jcpy(&q, p);
	prime_setone(t.c[2], cc.p);

	prime_affine(&q, &t, cc);
	decode(dest[1..1+plen], q.c[0]);
	decode(dest[1+plen..1+2*plen], q.c[1]);
};

fn prime_mul(g: []u8, x: []u8, cc: *curveparams) u32 = {
	if (len(g) != cc.pointlen) {
		return 0;
	};
	let p = prime_jacobian { ... };
	let r = point_decode(&p, g, cc);
	point_mul(&p, x, cc);
	point_encode(g, &p, cc);

	return r;
};

const P384_G: [_]u8 = [
	0x04, 0xaa, 0x87, 0xca, 0x22, 0xbe, 0x8b, 0x05, 0x37, 0x8e, 0xb1, 0xc7,
	0x1e, 0xf3, 0x20, 0xad, 0x74, 0x6e, 0x1d, 0x3b, 0x62, 0x8b, 0xa7, 0x9b,
	0x98, 0x59, 0xf7, 0x41, 0xe0, 0x82, 0x54, 0x2a, 0x38, 0x55, 0x02, 0xf2,
	0x5d, 0xbf, 0x55, 0x29, 0x6c, 0x3a, 0x54, 0x5e, 0x38, 0x72, 0x76, 0x0a,
	0xb7, 0x36, 0x17, 0xde, 0x4a, 0x96, 0x26, 0x2c, 0x6f, 0x5d, 0x9e, 0x98,
	0xbf, 0x92, 0x92, 0xdc, 0x29, 0xf8, 0xf4, 0x1d, 0xbd, 0x28, 0x9a, 0x14,
	0x7c, 0xe9, 0xda, 0x31, 0x13, 0xb5, 0xf0, 0xb8, 0xc0, 0x0a, 0x60, 0xb1,
	0xce, 0x1d, 0x7e, 0x81, 0x9d, 0x7a, 0x43, 0x1d, 0x7c, 0x90, 0xea, 0x0e,
	0x5f,
];

fn p384_generator() const []u8 = P384_G;

const P384_N: [_]u8 = [
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xc7, 0x63, 0x4d, 0x81, 0xf4, 0x37, 0x2d, 0xdf, 0x58, 0x1a, 0x0d, 0xb2,
	0x48, 0xb0, 0xa7, 0x7a, 0xec, 0xec, 0x19, 0x6a, 0xcc, 0xc5, 0x29, 0x73,
];

fn p384_order() const []u8 = P384_N;

fn p384_mul(p: []u8, x: []u8) u32 = {
	return prime_mul(p, x, &p384params);
};


fn p384_mulgen(r: []u8, x: []u8) size = {
	const g = P384_G[..];
	r[..len(g)] = P384_G[..];
	p384_mul(r[..len(g)], x);
	return len(g);
};

fn prime_muladd(cc: *curveparams, a: []u8, b: []u8, x: []u8, y: []u8) u32 = {
	let p = prime_jacobian { ... };
	let q = prime_jacobian { ... };

	// TODO: see about merging the two ladders. Right now, we do
	// two independent point multiplications, which is a bit
	// wasteful of CPU resources (but yields short code).

	if (len(a) != cc.pointlen) {
		return 0;
	};
	let r = point_decode(&p, a, cc);
	if (len(b) == 0) {
		b = cc.g[..];
	};
	r &= point_decode(&q, b, cc);
	point_mul(&p, x, cc);
	point_mul(&q, y, cc);

	// We want to compute P+Q. Since the base points A and B are distinct
	// from infinity, and the multipliers are non-zero and lower than the
	// curve order, then we know that P and Q are non-infinity. This
	// leaves two special situations to test for:
	// -- If P = Q then we must use point_double().
	// -- If P+Q = 0 then we must report an error.
	let t = point_add(&p, &q, cc);
	point_double(&q, cc);
	let z = iszero(p.c[2]);

	// If z is 1 then either P+Q = 0 (t = 1) or P = Q (t = 0). So we
	// have the following:
	//
	//   z = 0, t = 0   return P (normal addition)
	//   z = 0, t = 1   return P (normal addition)
	//   z = 1, t = 0   return Q (a 'double' case)
	//   z = 1, t = 1   report an error (P+Q = 0)
	jccpy(z & ~t, &p, &q);
	point_encode(a, &p, cc);
	r &= ~(z & t);

	return r;
};

fn p384_muladd(a: []u8, b: []u8, x: []u8, y: []u8) u32 =
	prime_muladd(&p384params, a, b, x, y);

const _p384: curve = curve {
	pointsz = P384_POINTSZ,
	order = &p384_order,
	generator = &p384_generator,
	mul = &p384_mul,
	mulgen = &p384_mulgen,
	muladd = &p384_muladd,
	keygen = &mask_keygen,
};

// Size of a [[p384]] point in bytes.
export def P384_POINTSZ = len(P384_G);

// Size of a [[p384]] scalar in bytes.
export def P384_SCALARSZ = len(P384_N);

// A [[curve]] implementation of P-384, also known as secp384r1;
export const p384: *curve = &_p384;

const P521_N: [_]u8 = [
	0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFA, 0x51, 0x86,
	0x87, 0x83, 0xBF, 0x2F, 0x96, 0x6B, 0x7F, 0xCC, 0x01, 0x48, 0xF7, 0x09,
	0xA5, 0xD0, 0x3B, 0xB5, 0xC9, 0xB8, 0x89, 0x9C, 0x47, 0xAE, 0xBB, 0x6F,
	0xB7, 0x1E, 0x91, 0x38, 0x64, 0x09,
];

fn p521_order() const []u8 = P521_N;

const P521_G: [_]u8 = [
	0x04, 0x00, 0xC6, 0x85, 0x8E, 0x06, 0xB7, 0x04, 0x04, 0xE9, 0xCD, 0x9E,
	0x3E, 0xCB, 0x66, 0x23, 0x95, 0xB4, 0x42, 0x9C, 0x64, 0x81, 0x39, 0x05,
	0x3F, 0xB5, 0x21, 0xF8, 0x28, 0xAF, 0x60, 0x6B, 0x4D, 0x3D, 0xBA, 0xA1,
	0x4B, 0x5E, 0x77, 0xEF, 0xE7, 0x59, 0x28, 0xFE, 0x1D, 0xC1, 0x27, 0xA2,
	0xFF, 0xA8, 0xDE, 0x33, 0x48, 0xB3, 0xC1, 0x85, 0x6A, 0x42, 0x9B, 0xF9,
	0x7E, 0x7E, 0x31, 0xC2, 0xE5, 0xBD, 0x66, 0x01, 0x18, 0x39, 0x29, 0x6A,
	0x78, 0x9A, 0x3B, 0xC0, 0x04, 0x5C, 0x8A, 0x5F, 0xB4, 0x2C, 0x7D, 0x1B,
	0xD9, 0x98, 0xF5, 0x44, 0x49, 0x57, 0x9B, 0x44, 0x68, 0x17, 0xAF, 0xBD,
	0x17, 0x27, 0x3E, 0x66, 0x2C, 0x97, 0xEE, 0x72, 0x99, 0x5E, 0xF4, 0x26,
	0x40, 0xC5, 0x50, 0xB9, 0x01, 0x3F, 0xAD, 0x07, 0x61, 0x35, 0x3C, 0x70,
	0x86, 0xA2, 0x72, 0xC2, 0x40, 0x88, 0xBE, 0x94, 0x76, 0x9F, 0xD1, 0x66,
	0x50
];

fn p521_generator() const []u8 = P521_G;


fn p521_mul(p: []u8, x: []u8) u32 = {
	return prime_mul(p, x, &p521params);
};

fn p521_mulgen(r: []u8, x: []u8) size = {
	const g = P521_G[..];
	r[..len(g)] = P521_G[..];
	p521_mul(r[..len(g)], x);
	return len(g);
};

fn p521_muladd(a: []u8, b: []u8, x: []u8, y: []u8) u32 =
	prime_muladd(&p521params, a, b, x, y);

const _p521: curve = curve {
	pointsz = P521_POINTSZ,
	order = &p521_order,
	generator = &p521_generator,
	mul = &p521_mul,
	mulgen = &p521_mulgen,
	muladd = &p521_muladd,
	keygen = &mask_keygen,
};

// Size of a [[p521]] point in bytes.
export def P521_POINTSZ = len(P521_G);

// Size of a [[p521]] scalar in bytes.
export def P521_SCALARSZ = len(P521_N);

// A [[curve]] implementation of P-521, also known as secp521r1;
export const p521: *curve = &_p521;
