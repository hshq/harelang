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


// Note from the BearSSL documentation:
//
// The ec_p256_m31 implementation supports P-256 with specialised code,
// including modular reduction routines that leverage the special format of the
// field modulus, and internal split of data as sequences of 30-bit words, which
// helps with carry propagation. ec_p256_m31 also includes fixed point
// optimisations, for the common case of multiplying the conventional generator
// point. These implementations are faster than the generic "i31" code, but with
// a larger code footprint.
//
// Convert an integer from unsigned big-endian encoding to a sequence of 30-bit
// words in little-endian order. The final "partial" word is returned.
fn be8tole30(dest: []u32, src: []u8) u32 = {
	let acc: u32 = 0;
	let acclen: u32 = 0;
	let destpos = 0;

	for (let i = len(src); i > 0; i -= 1) {
		let b = src[i - 1]: u32;
		if (acclen < 22) {
			acc |= b << acclen;
			acclen += 8;
		} else {
			dest[destpos] = (acc | (b << acclen)) & 0x3FFFFFFF;
			destpos += 1;
			acc = b >> (30 - acclen);
			acclen -= 22;
		};
	};
	return acc;
};

// Convert an integer (30-bit words, little-endian) to unsigned
// big-endian encoding. The total encoding length is provided; all
// the destination bytes will be filled.
fn le30tobe8(dest: []u8, src: []u32) void = {
	let acc: u32 = 0;
	let acclen: u32 = 0;
	let srcpos: size = 0;

	for (let i = len(dest); i > 0; i -= 1) {
		if (acclen < 8) {
			let w = src[srcpos];
			srcpos += 1;

			dest[i - 1] = (acc | (w << acclen)): u8;
			acc = w >> (8 - acclen);
			acclen += 22;
		} else {
			dest[i - 1] = acc: u8;
			acc >>= 8;
			acclen -= 8;
		};
	};
};

@test fn be8tole30() void = {
	let be8: [6]u8 = [0x11, 0x22, 0xF3, 0x44, 0x55, 0x66];
	let le30result: [2]u32 = [0...];
	let be8result: [6]u8 = [0...];

	le30result[1] = be8tole30(le30result, be8);
	le30tobe8(be8result, le30result);

	assert(bytes::equal(be8, be8result));
};

fn arsh(x: u32, n: u32) u32 = (x: i32 >> n: i32): u32;
fn arshw(x: u64, n: u32) u64 = (x: i64 >> n: i32): u64;

@test fn arsh() void = assert(arsh(0x80000000u32, 2) == 0xe0000000);

// Multiply two integers. Source integers are represented as arrays of
// nine 30-bit words, for values up to 2^270-1. Result is encoded over
// 18 words of 30 bits each.
fn mul9(d: []u32, a: []u32, b: []u32) void = {
	// Maximum intermediate result is no more than
	// 10376293531797946367, which fits in 64 bits. Reason:
	//
	//   10376293531797946367 = 9 * (2^30-1)^2 + 9663676406
	//   10376293531797946367 < 9663676407 * 2^30
	//
	// Thus, adding together 9 products of 30-bit integers, with
	// a carry of at most 9663676406, yields an integer that fits
	// on 64 bits and generates a carry of at most 9663676406.
	let t: [17]u64 = [0...];

	t[0] = mulu32(a[0], b[0]);
	t[1] = mulu32(a[0], b[1])
		+ mulu32(a[1], b[0]);
	t[2] = mulu32(a[0], b[2])
		+ mulu32(a[1], b[1])
		+ mulu32(a[2], b[0]);
	t[3] = mulu32(a[0], b[3])
		+ mulu32(a[1], b[2])
		+ mulu32(a[2], b[1])
		+ mulu32(a[3], b[0]);
	t[4] = mulu32(a[0], b[4])
		+ mulu32(a[1], b[3])
		+ mulu32(a[2], b[2])
		+ mulu32(a[3], b[1])
		+ mulu32(a[4], b[0]);
	t[5] = mulu32(a[0], b[5])
		+ mulu32(a[1], b[4])
		+ mulu32(a[2], b[3])
		+ mulu32(a[3], b[2])
		+ mulu32(a[4], b[1])
		+ mulu32(a[5], b[0]);
	t[6] = mulu32(a[0], b[6])
		+ mulu32(a[1], b[5])
		+ mulu32(a[2], b[4])
		+ mulu32(a[3], b[3])
		+ mulu32(a[4], b[2])
		+ mulu32(a[5], b[1])
		+ mulu32(a[6], b[0]);
	t[7] = mulu32(a[0], b[7])
		+ mulu32(a[1], b[6])
		+ mulu32(a[2], b[5])
		+ mulu32(a[3], b[4])
		+ mulu32(a[4], b[3])
		+ mulu32(a[5], b[2])
		+ mulu32(a[6], b[1])
		+ mulu32(a[7], b[0]);
	t[8] = mulu32(a[0], b[8])
		+ mulu32(a[1], b[7])
		+ mulu32(a[2], b[6])
		+ mulu32(a[3], b[5])
		+ mulu32(a[4], b[4])
		+ mulu32(a[5], b[3])
		+ mulu32(a[6], b[2])
		+ mulu32(a[7], b[1])
		+ mulu32(a[8], b[0]);
	t[9] = mulu32(a[1], b[8])
		+ mulu32(a[2], b[7])
		+ mulu32(a[3], b[6])
		+ mulu32(a[4], b[5])
		+ mulu32(a[5], b[4])
		+ mulu32(a[6], b[3])
		+ mulu32(a[7], b[2])
		+ mulu32(a[8], b[1]);
	t[10] = mulu32(a[2], b[8])
		+ mulu32(a[3], b[7])
		+ mulu32(a[4], b[6])
		+ mulu32(a[5], b[5])
		+ mulu32(a[6], b[4])
		+ mulu32(a[7], b[3])
		+ mulu32(a[8], b[2]);
	t[11] = mulu32(a[3], b[8])
		+ mulu32(a[4], b[7])
		+ mulu32(a[5], b[6])
		+ mulu32(a[6], b[5])
		+ mulu32(a[7], b[4])
		+ mulu32(a[8], b[3]);
	t[12] = mulu32(a[4], b[8])
		+ mulu32(a[5], b[7])
		+ mulu32(a[6], b[6])
		+ mulu32(a[7], b[5])
		+ mulu32(a[8], b[4]);
	t[13] = mulu32(a[5], b[8])
		+ mulu32(a[6], b[7])
		+ mulu32(a[7], b[6])
		+ mulu32(a[8], b[5]);
	t[14] = mulu32(a[6], b[8])
		+ mulu32(a[7], b[7])
		+ mulu32(a[8], b[6]);
	t[15] = mulu32(a[7], b[8])
		+ mulu32(a[8], b[7]);
	t[16] = mulu32(a[8], b[8]);

	// Propagate carries.
	let cc: u64 = 0;
	for (let i = 0z; i < 17; i += 1) {
		let w = t[i] + cc;
		d[i] = w: u32 & 0x3FFFFFFF;
		cc = w >> 30;
	};
	d[17] = cc: u32;
};

// Square a 270-bit integer, represented as an array of nine 30-bit words.
// Result uses 18 words of 30 bits each.
fn square9(d: []u32, a: []u32) void = {
	let t: [17]u64 = [0...];

	t[0] = mulu32(a[0], a[0]);
	t[1] = ((mulu32(a[0], a[1])) << 1);
	t[2] = mulu32(a[1], a[1])
		+ ((mulu32(a[0], a[2])) << 1);
	t[3] = ((mulu32(a[0], a[3])
		+ mulu32(a[1], a[2])) << 1);
	t[4] = mulu32(a[2], a[2])
		+ ((mulu32(a[0], a[4])
		+ mulu32(a[1], a[3])) << 1);
	t[5] = ((mulu32(a[0], a[5])
		+ mulu32(a[1], a[4])
		+ mulu32(a[2], a[3])) << 1);
	t[6] = mulu32(a[3], a[3])
		+ ((mulu32(a[0], a[6])
		+ mulu32(a[1], a[5])
		+ mulu32(a[2], a[4])) << 1);
	t[7] = ((mulu32(a[0], a[7])
		+ mulu32(a[1], a[6])
		+ mulu32(a[2], a[5])
		+ mulu32(a[3], a[4])) << 1);
	t[8] = mulu32(a[4], a[4])
		+ ((mulu32(a[0], a[8])
		+ mulu32(a[1], a[7])
		+ mulu32(a[2], a[6])
		+ mulu32(a[3], a[5])) << 1);
	t[9] = ((mulu32(a[1], a[8])
		+ mulu32(a[2], a[7])
		+ mulu32(a[3], a[6])
		+ mulu32(a[4], a[5])) << 1);
	t[10] = mulu32(a[5], a[5])
		+ ((mulu32(a[2], a[8])
		+ mulu32(a[3], a[7])
		+ mulu32(a[4], a[6])) << 1);
	t[11] = ((mulu32(a[3], a[8])
		+ mulu32(a[4], a[7])
		+ mulu32(a[5], a[6])) << 1);
	t[12] = mulu32(a[6], a[6])
		+ ((mulu32(a[4], a[8])
		+ mulu32(a[5], a[7])) << 1);
	t[13] = ((mulu32(a[5], a[8])
		+ mulu32(a[6], a[7])) << 1);
	t[14] = mulu32(a[7], a[7])
		+ ((mulu32(a[6], a[8])) << 1);
	t[15] = ((mulu32(a[7], a[8])) << 1);
	t[16] = mulu32(a[8], a[8]);

	// Propagate carries.
	let cc: u64 = 0;
	for (let i = 0z; i < 17; i += 1) {
		let w = t[i] + cc;
		d[i] = w: u32 & 0x3FFFFFFF;
		cc = w >> 30;
	};
	d[17] = cc: u32;
};

// Base field modulus for P-256.
const F256: [_]u32 = [
	0x3FFFFFFF, 0x3FFFFFFF, 0x3FFFFFFF, 0x0000003F, 0x00000000, 0x00000000,
	0x00001000, 0x3FFFC000, 0x0000FFFF
];

// The 'b' curve equation coefficient for P-256.
const P256_B: [_]u32 = [
	0x27D2604B, 0x2F38F0F8, 0x053B0F63, 0x0741AC33, 0x1886BC65, 0x2EF555DA,
	0x293E7B3E, 0x0D762A8E, 0x00005AC6
];

// Addition in the field. Source operands shall fit on 257 bits; output
// will be lower than twice the modulus.
fn add_f256(d: []u32, a: []u32, b: []u32) void = {
	let w: u32 = 0;

	let cc: u32 = 0;
	for (let i = 0z; i < 9; i += 1) {
		w = a[i] + b[i] + cc;
		d[i] = w & 0x3FFFFFFF;
		cc = w >> 30;
	};
	w >>= 16;
	d[8] &= 0xFFFF;
	d[3] -= w << 6;
	d[6] -= w << 12;
	d[7] += w << 14;
	cc = w;
	for (let i = 0z; i < 9; i += 1) {
		w = d[i] + cc;
		d[i] = w & 0x3FFFFFFF;
		cc = arsh(w, 30);
	};
};

// Subtraction in the field. Source operands shall be smaller than twice
// the modulus; the result will fulfil the same property.
fn sub_f256(d: []u32, a: []u32, b: []u32) void = {
	let w: u32 = 0;
	let cc: u32 = 0;

	// We really compute a - b + 2*p to make sure that the result is
	// positive.
	w = a[0] - b[0] - 0x00002;
	d[0] = w & 0x3FFFFFFF;
	w = a[1] - b[1] + arsh(w, 30);
	d[1] = w & 0x3FFFFFFF;
	w = a[2] - b[2] + arsh(w, 30);
	d[2] = w & 0x3FFFFFFF;
	w = a[3] - b[3] + arsh(w, 30) + 0x00080;
	d[3] = w & 0x3FFFFFFF;
	w = a[4] - b[4] + arsh(w, 30);
	d[4] = w & 0x3FFFFFFF;
	w = a[5] - b[5] + arsh(w, 30);
	d[5] = w & 0x3FFFFFFF;
	w = a[6] - b[6] + arsh(w, 30) + 0x02000;
	d[6] = w & 0x3FFFFFFF;
	w = a[7] - b[7] + arsh(w, 30) - 0x08000;
	d[7] = w & 0x3FFFFFFF;
	w = a[8] - b[8] + arsh(w, 30) + 0x20000;
	d[8] = w & 0xFFFF;
	w >>= 16;
	d[8] &= 0xFFFF;
	d[3] -= w << 6;
	d[6] -= w << 12;
	d[7] += w << 14;
	cc = w;
	for (let i = 0z; i < 9; i += 1) {
		w = d[i] + cc;
		d[i] = w & 0x3FFFFFFF;
		cc = arsh(w, 30);
	};
};

// Compute a multiplication in F256. Source operands shall be less than
// twice the modulus.
fn mul_f256(d: []u32, a: []u32, b: []u32) void = {
	let t: [18]u32 = [0...];
	let s: [18]u64 = [0...];
	let x: u64 = 0;

	mul9(t, a, b);

	// Modular reduction: each high word in added/subtracted where
	// necessary.
	//
	// The modulus is:
	//    p = 2^256 - 2^224 + 2^192 + 2^96 - 1
	// Therefore:
	//    2^256 = 2^224 - 2^192 - 2^96 + 1 mod p
	//
	// For a word x at bit offset n (n >= 256), we have:
	//    x*2^n = x*2^(n-32) - x*2^(n-64)
	//	    - x*2^(n - 160) + x*2^(n-256) mod p
	//
	// Thus, we can nullify the high word if we reinject it at some
	// proper emplacements.
	//
	// We use 64-bit intermediate words to allow for carries to
	// accumulate easily, before performing the final propagation.
	for (let i = 0; i < 18; i += 1) {
		s[i] = t[i];
	};

	for (let i = 17; i >= 9; i -= 1) {
		let y = s[i];
		s[i - 1] += arshw(y, 2);
		s[i - 2] += (y << 28) & 0x3FFFFFFF;
		s[i - 2] -= arshw(y, 4);
		s[i - 3] -= (y << 26) & 0x3FFFFFFF;
		s[i - 5] -= arshw(y, 10);
		s[i - 6] -= (y << 20) & 0x3FFFFFFF;
		s[i - 8] += arshw(y, 16);
		s[i - 9] += (y << 14) & 0x3FFFFFFF;
	};

	// Carry propagation must be signed. Moreover, we may have overdone
	// it a bit, and obtain a negative result.
	//
	// The loop above ran 9 times; each time, each word was augmented
	// by at most one extra word (in absolute value). Thus, the top
	// word must in fine fit in 39 bits, so the carry below will fit
	// on 9 bits.
	let cc: u64 = 0;
	for (let i = 0z; i < 9; i += 1) {
		x = s[i] + cc;
		d[i] = x: u32 & 0x3FFFFFFF;
		cc = arshw(x, 30);
	};

	// All nine words fit on 30 bits, but there may be an extra
	// carry for a few bits (at most 9), and that carry may be
	// negative. Moreover, we want the result to fit on 257 bits.
	// The two lines below ensure that the word in d[] has length
	// 256 bits, and the (signed) carry (beyond 2^256) is in cc. The
	// significant length of cc is less than 24 bits, so we will be
	// able to switch to 32-bit operations.
	cc = arshw(x, 16);
	d[8] &= 0xFFFF;

	// One extra round of reduction, for cc*2^256, which means
	// adding cc*(2^224-2^192-2^96+1) to a 256-bit (nonnegative)
	// value. If cc is negative, then it may happen (rarely, but
	// not neglectibly so) that the result would be negative. In
	// order to avoid that, if cc is negative, then we add the
	// modulus once. Note that if cc is negative, then propagating
	// that carry must yield a value lower than the modulus, so
	// adding the modulus once will keep the final result under
	// twice the modulus.
	let z = cc: u32;
	d[3] -= z << 6;
	d[6] -= (z << 12) & 0x3FFFFFFF;
	d[7] -= arsh(z, 18);
	d[7] += (z << 14) & 0x3FFFFFFF;
	d[8] += arsh(z, 16);
	let c = z >> 31;
	d[0] -= c;
	d[3] += c << 6;
	d[6] += c << 12;
	d[7] -= c << 14;
	d[8] += c << 16;

	for (let i = 0z; i < 9; i += 1) {
		let w = d[i] + z;
		d[i] = w & 0x3FFFFFFF;
		z = arsh(w, 30);
	};
};


// Compute a square in F256. Source operand shall be less than
// twice the modulus.
fn square_f256(d: []u32, a: []u32) void = {
	let t: [18]u32 = [0...];
	let s: [18]u64 = [0...];

	square9(t, a);

	// Modular reduction: each high word in added/subtracted where
	// necessary.
	//
	// The modulus is:
	//    p = 2^256 - 2^224 + 2^192 + 2^96 - 1
	// Therefore:
	//    2^256 = 2^224 - 2^192 - 2^96 + 1 mod p
	//
	// For a word x at bit offset n (n >= 256), we have:
	//    x*2^n = x*2^(n-32) - x*2^(n-64)
	//	    - x*2^(n - 160) + x*2^(n-256) mod p
	//
	// Thus, we can nullify the high word if we reinject it at some
	// proper emplacements.
	//
	// We use 64-bit intermediate words to allow for carries to
	// accumulate easily, before performing the final propagation.
	for (let i = 0; i < 18; i += 1) {
		s[i] = t[i];
	};

	for (let i = 17; i >= 9; i -= 1) {
		let y = s[i];
		s[i - 1] += arshw(y, 2);
		s[i - 2] += (y << 28) & 0x3FFFFFFF;
		s[i - 2] -= arshw(y, 4);
		s[i - 3] -= (y << 26) & 0x3FFFFFFF;
		s[i - 5] -= arshw(y, 10);
		s[i - 6] -= (y << 20) & 0x3FFFFFFF;
		s[i - 8] += arshw(y, 16);
		s[i - 9] += (y << 14) & 0x3FFFFFFF;
	};

	// Carry propagation must be signed. Moreover, we may have overdone
	// it a bit, and obtain a negative result.
	//
	// The loop above ran 9 times; each time, each word was augmented
	// by at most one extra word (in absolute value). Thus, the top
	// word must in fine fit in 39 bits, so the carry below will fit
	// on 9 bits.
	let cc: u64 = 0;
	let x: u64 = 0;
	for (let i = 0; i < 9; i += 1) {
		x = s[i] + cc;
		d[i] = x: u32 & 0x3FFFFFFF;
		cc = arshw(x, 30);
	};

	// All nine words fit on 30 bits, but there may be an extra
	// carry for a few bits (at most 9), and that carry may be
	// negative. Moreover, we want the result to fit on 257 bits.
	// The two lines below ensure that the word in d[] has length
	// 256 bits, and the (signed) carry (beyond 2^256) is in cc. The
	// significant length of cc is less than 24 bits, so we will be
	// able to switch to 32-bit operations.
	cc = arshw(x, 16);
	d[8] &= 0xFFFF;

	// One extra round of reduction, for cc*2^256, which means
	// adding cc*(2^224-2^192-2^96+1) to a 256-bit (nonnegative)
	// value. If cc is negative, then it may happen (rarely, but
	// not neglectibly so) that the result would be negative. In
	// order to avoid that, if cc is negative, then we add the
	// modulus once. Note that if cc is negative, then propagating
	// that carry must yield a value lower than the modulus, so
	// adding the modulus once will keep the final result under
	// twice the modulus.
	let z = cc: u32;
	d[3] -= z << 6;
	d[6] -= (z << 12) & 0x3FFFFFFF;
	d[7] -= arsh(z, 18);
	d[7] += (z << 14) & 0x3FFFFFFF;
	d[8] += arsh(z, 16);
	let c = z >> 31;
	d[0] -= c;
	d[3] += c << 6;
	d[6] += c << 12;
	d[7] -= c << 14;
	d[8] += c << 16;

	for (let i = 0z; i < 9; i += 1) {
		let w = d[i] + z;
		d[i] = w & 0x3FFFFFFF;
		z = arsh(w, 30);
	};
};

// Perform a "final reduction" in field F256 (field for curve P-256).
// The source value must be less than twice the modulus. If the value
// is not lower than the modulus, then the modulus is subtracted and
// this function returns 1; otherwise, it leaves it untouched and it
// returns 0.
fn reduce_final_f256(d: []u32) u32 = {
	let t: [9]u32 = [0...];

	let cc: u32 = 0;
	for (let i = 0; i < 9; i += 1) {
		let w = d[i] - F256[i] - cc;
		cc = w >> 31;
		t[i] = w & 0x3FFFFFFF;
	};
	cc ^= 1;
	ccopyu32(cc, d, t);
	return cc;
};

// Jacobian coordinates for a point in P-256: affine coordinates (X,Y)
// are such that:
//   X = x / z^2
//   Y = y / z^3
// For the point at infinity, z = 0.
// Each point thus admits many possible representations.
//
// Coordinates are represented in arrays of 32-bit integers, each holding
// 30 bits of data. Values may also be slightly greater than the modulus,
// but they will always be lower than twice the modulus.
type p256_jacobian = struct {
	x: [9]u32,
	y: [9]u32,
	z: [9]u32,
};

// Convert a point to affine coordinates:
//  - If the point is the point at infinity, then all three coordinates
//    are set to 0.
//  - Otherwise, the 'z' coordinate is set to 1, and the 'x' and 'y'
//    coordinates are the 'X' and 'Y' affine coordinates.
// The coordinates are guaranteed to be lower than the modulus.
fn p256_to_affine(p: *p256_jacobian) void = {
	let t1: [9]u32 = [0...];
	let t2: [9]u32 = [0...];

	// Invert z with a modular exponentiation: the modulus is
	// p = 2^256 - 2^224 + 2^192 + 2^96 - 1, and the exponent is
	// p-2. Exponent bit pattern (from high to low) is:
	//  - 32 bits of value 1
	//  - 31 bits of value 0
	//  - 1 bit of value 1
	//  - 96 bits of value 0
	//  - 94 bits of value 1
	//  - 1 bit of value 0
	//  - 1 bit of value 1
	// Thus, we precompute z^(2^31-1) to speed things up.
	//
	// If z = 0 (point at infinity) then the modular exponentiation
	// will yield 0, which leads to the expected result (all three
	// coordinates set to 0).

	// A simple square-and-multiply for z^(2^31-1). We could save about
	// two dozen multiplications here with an addition chain, but
	// this would require a bit more code, and extra stack buffers.
	t1[..] = p.z[..];
	for (let i = 0; i < 30; i += 1) {
		square_f256(t1, t1);
		mul_f256(t1, t1, p.z);
	};

	// Square-and-multiply. Apart from the squarings, we have a few
	// multiplications to set bits to 1; we multiply by the original z
	// for setting 1 bit, and by t1 for setting 31 bits.
	t2[..] = p.z[..];
	for (let i = 1; i < 256; i += 1) {
		square_f256(t2, t2);
		switch (i) {
		case 31, 190, 221, 252 =>
			mul_f256(t2, t2, t1);
		case 63, 253, 255 =>
			mul_f256(t2, t2, p.z);
		case => void;
		};
	};

	// Now that we have 1/z, multiply x by 1/z^2 and y by 1/z^3.
	mul_f256(t1, t2, t2);
	mul_f256(p.x, t1, p.x);
	mul_f256(t1, t1, t2);
	mul_f256(p.y, t1, p.y);
	reduce_final_f256(p.x);
	reduce_final_f256(p.y);

	// Multiply z by 1/z. If z = 0, then this will yield 0, otherwise
	// this will set z to 1.
	mul_f256(p.z, p.z, t2);
	reduce_final_f256(p.z);
};

// Double a point in P-256. This function works for all valid points,
// including the point at infinity.
fn p256_double(q: *p256_jacobian) void = {
	// Doubling formulas are:
	//
	//   s = 4*x*y^2
	//   m = 3*(x + z^2)*(x - z^2)
	//   x' = m^2 - 2*s
	//   y' = m*(s - x') - 8*y^4
	//   z' = 2*y*z
	//
	// These formulas work for all points, including points of order 2
	// and points at infinity:
	//   - If y = 0 then z' = 0. But there is no such point in P-256
	//     anyway.
	//   - If z = 0 then z' = 0.
	let t1: [9]u32 = [0...];
	let t2: [9]u32 = [0...];
	let t3: [9]u32 = [0...];
	let t4: [9]u32 = [0...];

	// Compute z^2 in t1.
	square_f256(t1, q.z);

	// Compute x-z^2 in t2 and x+z^2 in t1.
	add_f256(t2, q.x, t1);
	sub_f256(t1, q.x, t1);

	// Compute 3*(x+z^2)*(x-z^2) in t1.
	mul_f256(t3, t1, t2);
	add_f256(t1, t3, t3);
	add_f256(t1, t3, t1);

	// Compute 4*x*y^2 (in t2) and 2*y^2 (in t3).
	square_f256(t3, q.y);
	add_f256(t3, t3, t3);
	mul_f256(t2, q.x, t3);
	add_f256(t2, t2, t2);


	// Compute x' = m^2 - 2*s.
	square_f256(q.x, t1);
	sub_f256(q.x, q.x, t2);
	sub_f256(q.x, q.x, t2);

	// Compute z' = 2*y*z.
	mul_f256(t4, q.y, q.z);
	add_f256(q.z, t4, t4);

	// Compute y' = m*(s - x') - 8*y^4. Note that we already have
	// 2*y^2 in t3.
	sub_f256(t2, t2, q.x);
	mul_f256(q.y, t1, t2);
	square_f256(t4, t3);
	add_f256(t4, t4, t4);
	sub_f256(q.y, q.y, t4);
};

// Add point P2 to point P1.
//
// This function computes the wrong result in the following cases:
//
//   - If P1 == 0 but P2 != 0
//   - If P1 != 0 but P2 == 0
//   - If P1 == P2
//
// In all three cases, P1 is set to the point at infinity.
//
// Returned value is 0 if one of the following occurs:
//
//   - P1 and P2 have the same Y coordinate
//   - P1 == 0 and P2 == 0
//   - The Y coordinate of one of the points is 0 and the other point is
//     the point at infinity.
//
// The third case cannot actually happen with valid points, since a point
// with Y == 0 is a point of order 2, and there is no point of order 2 on
// curve P-256.
//
// Therefore, assuming that P1 != 0 and P2 != 0 on input, then the caller
// can apply the following:
//
//   - If the result is not the point at infinity, then it is correct.
//   - Otherwise, if the returned value is 1, then this is a case of
//     P1+P2 == 0, so the result is indeed the point at infinity.
//   - Otherwise, P1 == P2, so a "double" operation should have been
//     performed.
fn p256_add(p1: *p256_jacobian, p2: *p256_jacobian) u32 = {
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
	let t1: [9]u32 = [0...];
	let t2: [9]u32 = [0...];
	let t3: [9]u32 = [0...];
	let t4: [9]u32 = [0...];
	let t5: [9]u32 = [0...];
	let t6: [9]u32 = [0...];
	let t7: [9]u32 = [0...];
	let ret: u32 = 0;

	// Compute u1 = x1*z2^2 (in t1) and s1 = y1*z2^3 (in t3).
	square_f256(t3, p2.z);
	mul_f256(t1, p1.x, t3);
	mul_f256(t4, p2.z, t3);
	mul_f256(t3, p1.y, t4);

	// Compute u2 = x2*z1^2 (in t2) and s2 = y2*z1^3 (in t4).
	square_f256(t4, p1.z);
	mul_f256(t2, p2.x, t4);
	mul_f256(t5, p1.z, t4);
	mul_f256(t4, p2.y, t5);

	// Compute h = h2 - u1 (in t2) and r = s2 - s1 (in t4).
	// We need to test whether r is zero, so we will do some extra
	// reduce.
	sub_f256(t2, t2, t1);
	sub_f256(t4, t4, t3);
	reduce_final_f256(t4);
	ret = 0;
	for (let i = 0; i < 9; i += 1) {
		ret |= t4[i];
	};
	ret = (ret | -ret) >> 31;

	// Compute u1*h^2 (in t6) and h^3 (in t5);
	square_f256(t7, t2);
	mul_f256(t6, t1, t7);
	mul_f256(t5, t7, t2);

	// Compute x3 = r^2 - h^3 - 2*u1*h^2.
	square_f256(p1.x, t4);
	sub_f256(p1.x, p1.x, t5);
	sub_f256(p1.x, p1.x, t6);
	sub_f256(p1.x, p1.x, t6);

	// Compute y3 = r*(u1*h^2 - x3) - s1*h^3.
	sub_f256(t6, t6, p1.x);
	mul_f256(p1.y, t4, t6);
	mul_f256(t1, t5, t3);
	sub_f256(p1.y, p1.y, t1);

	// Compute z3 = h*z1*z2.
	mul_f256(t1, p1.z, p2.z);
	mul_f256(p1.z, t1, t2);

	return ret;
};

// Add point P2 to point P1. This is a specialised function for the
// case when P2 is a non-zero point in affine coordinate.
//
// This function computes the wrong result in the following cases:
//
//   - If P1 == 0
//   - If P1 == P2
//
// In both cases, P1 is set to the point at infinity.
//
// Returned value is 0 if one of the following occurs:
//
//   - P1 and P2 have the same Y coordinate
//   - The Y coordinate of P2 is 0 and P1 is the point at infinity.
//
// The second case cannot actually happen with valid points, since a point
// with Y == 0 is a point of order 2, and there is no point of order 2 on
// curve P-256.
//
// Therefore, assuming that P1 != 0 on input, then the caller
// can apply the following:
//
//   - If the result is not the point at infinity, then it is correct.
//   - Otherwise, if the returned value is 1, then this is a case of
//     P1+P2 == 0, so the result is indeed the point at infinity.
//   - Otherwise, P1 == P2, so a "double" operation should have been
//     performed.
fn p256_add_mixed(p1: *p256_jacobian, p2: *p256_jacobian) u32 = {
	// Addtions formulas are:
	//
	//   u1 = x1
	//   u2 = x2 * z1^2
	//   s1 = y1
	//   s2 = y2 * z1^3
	//   h = u2 - u1
	//   r = s2 - s1
	//   x3 = r^2 - h^3 - 2 * u1 * h^2
	//   y3 = r * (u1 * h^2 - x3) - s1 * h^3
	//   z3 = h * z1
	let t1: [9]u32 = [0...];
	let t2: [9]u32 = [0...];
	let t3: [9]u32 = [0...];
	let t4: [9]u32 = [0...];
	let t5: [9]u32 = [0...];
	let t6: [9]u32 = [0...];
	let t7: [9]u32 = [0...];
	let ret: u32 = 0;

	// Compute u1 = x1 (in t1) and s1 = y1 (in t3).
	t1[..] = p1.x[..];
	t3[..] = p1.y[..];

	// Compute u2 = x2*z1^2 (in t2) and s2 = y2*z1^3 (in t4).
	square_f256(t4, p1.z);
	mul_f256(t2, p2.x, t4);
	mul_f256(t5, p1.z, t4);
	mul_f256(t4, p2.y, t5);

	// Compute h = h2 - u1 (in t2) and r = s2 - s1 (in t4).
	// We need to test whether r is zero, so we will do some extra
	// reduce.
	sub_f256(t2, t2, t1);
	sub_f256(t4, t4, t3);
	reduce_final_f256(t4);
	ret = 0;
	for (let i = 0; i < 9; i += 1) {
		ret |= t4[i];
	};
	ret = (ret | -ret) >> 31;

	// Compute u1*h^2 (in t6) and h^3 (in t5);
	square_f256(t7, t2);
	mul_f256(t6, t1, t7);
	mul_f256(t5, t7, t2);

	// Compute x3 = r^2 - h^3 - 2*u1*h^2.
	square_f256(p1.x, t4);
	sub_f256(p1.x, p1.x, t5);
	sub_f256(p1.x, p1.x, t6);
	sub_f256(p1.x, p1.x, t6);

	// Compute y3 = r*(u1*h^2 - x3) - s1*h^3.
	sub_f256(t6, t6, p1.x);
	mul_f256(p1.y, t4, t6);
	mul_f256(t1, t5, t3);
	sub_f256(p1.y, p1.y, t1);

	// Compute z3 = h*z1*z2.
	mul_f256(p1.z, p1.z, t2);

	return ret;
};

// Decode a P-256 point. This function does not support the point at
// infinity. Returned value is 0 if the point is invalid, 1 otherwise.
fn p256_decode(p: *p256_jacobian, src: const []u8) u32 = {
	let tx: [9]u32 = [0...];
	let ty: [9]u32 = [0...];
	let t1: [9]u32 = [0...];
	let t2: [9]u32 = [0...];
	let bad: u32 = 0;

	if (len(src) != 65) {
		return 0;
	};
	let buf = src;

	// First byte must be 0x04 (uncompressed format). We could support
	// "hybrid format" (first byte is 0x06 or 0x07, and encodes the
	// least significant bit of the Y coordinate), but it is explicitly
	// forbidden by RFC 5480 (section 2.2).
	bad = nequ32(buf[0], 0x04);

	// Decode the coordinates, and check that they are both lower
	// than the modulus.
	tx[8] = be8tole30(tx, buf[1..33]);
	ty[8] = be8tole30(ty, buf[33..]);
	bad |= reduce_final_f256(tx);
	bad |= reduce_final_f256(ty);

	// Check curve equation.
	square_f256(t1, tx);
	mul_f256(t1, tx, t1);
	square_f256(t2, ty);
	sub_f256(t1, t1, tx);
	sub_f256(t1, t1, tx);
	sub_f256(t1, t1, tx);
	add_f256(t1, t1, P256_B);
	sub_f256(t1, t1, t2);
	reduce_final_f256(t1);
	for (let i = 0; i < 9; i += 1) {
		bad |= t1[i];
	};

	// Copy coordinates to the point structure.
	p.x[..] = tx[..];
	p.y[..] = ty[..];
	p.z[..] = [0...];
	p.z[0] = 1;
	return equ32(bad, 0);
};

// Encode a point into a buffer. This function assumes that the point is
// valid, in affine coordinates, and not the point at infinity.
fn p256_encode(dest: []u8, p: *p256_jacobian) void = {
	dest[0] = 0x04;
	le30tobe8(dest[1..33], p.x);
	le30tobe8(dest[33..], p.y);
};

// Multiply a curve point by an integer. The integer is assumed to be
// lower than the curve order, and the base point must not be the point
// at infinity.
fn p256_mul(p: *p256_jacobian, x: []u8) void = {
	// qz is a flag that is initially 1, and remains equal to 1
	// as long as the point is the point at infinity.
	//
	// We use a 2-bit window to handle multiplier bits by pairs.
	// The precomputed window really is the points P2 and P3.
	let qz: u32 = 1;
	let p2 = p256_jacobian { ... };
	let p3 = p256_jacobian { ... };
	let q = p256_jacobian { ... };
	let t = p256_jacobian { ... };
	let u = p256_jacobian { ... };
	let xpos: size = 0;

	// Compute window values.
	p2 = *p;
	p256_double(&p2);
	p3 = *p;
	p256_add(&p3, &p2);

	// We start with Q = 0. We process multiplier bits 2 by 2.
	for (let i = len(x); i > 0; i -= 1) {
		for (let k = 6i8; k >= 0; k -= 2) {
			let bits: u32 = 0;
			let bnz: u32 = 0;

			p256_double(&q);
			p256_double(&q);
			t = *p;
			u = q;
			bits = (x[xpos] >> k: u8) & 3u32;
			bnz = nequ32(bits, 0);
			jaccopy(equ32(bits, 2), &t, &p2);
			jaccopy(equ32(bits, 3), &t, &p3);
			p256_add(&u, &t);
			jaccopy(bnz & qz, &q, &t);
			jaccopy(bnz & ~qz, &q, &u);
			qz &= ~bnz;
		};
		xpos += 1;
	};
	*p = q;
};

fn jaccopy(ctl: u32, dest: *p256_jacobian, src: *p256_jacobian) void = {
	ccopyu32(ctl, dest.x, src.x);
	ccopyu32(ctl, dest.y, src.y);
	ccopyu32(ctl, dest.z, src.z);
};

// Precomputed window: k*G points, where G is the curve generator, and k
// is an integer from 1 to 15 (inclusive). The X and Y coordinates of
// the point are encoded as 9 words of 30 bits each (little-endian
// order).
const gwin: [15][18]u32 = [
	[
		0x1898c296, 0x1284e517, 0x1eb33a0f, 0x00df604b, 0x2440f277,
		0x339b958e, 0x04247f8b, 0x347cb84b, 0x00006b17, 0x37bf51f5,
		0x2ed901a0, 0x3315ecec, 0x338cd5da, 0x0f9e162b, 0x1fad29f0,
		0x27f9b8ee, 0x10b8bf86, 0x00004fe3,
	],
	[
		0x07669978, 0x182d23f1, 0x3f21b35a, 0x225a789d, 0x351ac3c0,
		0x08e00c12, 0x34f7e8a5, 0x1ec62340, 0x00007cf2, 0x227873d1,
		0x3812de74, 0x0e982299, 0x1f6b798f, 0x3430dbba, 0x366b1a7d,
		0x2d040293, 0x154436e3, 0x00000777,
	],
	[
		0x06e7fd6c, 0x2d05986f, 0x3ada985f, 0x31adc87b, 0x0bf165e6,
		0x1fbe5475, 0x30a44c8f, 0x3934698c, 0x00005ecb, 0x227d5032,
		0x29e6c49e, 0x04fb83d9, 0x0aac0d8e, 0x24a2ecd8, 0x2c1b3869,
		0x0ff7e374, 0x19031266, 0x00008734,
	],
	[
		0x2b030852, 0x024c0911, 0x05596ef5, 0x07f8b6de, 0x262bd003,
		0x3779967b, 0x08fbba02, 0x128d4cb4, 0x0000e253, 0x184ed8c6,
		0x310b08fc, 0x30ee0055, 0x3f25b0fc, 0x062d764e, 0x3fb97f6a,
		0x33cc719d, 0x15d69318, 0x0000e0f1,
	],
	[
		0x03d033ed, 0x05552837, 0x35be5242, 0x2320bf47, 0x268fdfef,
		0x13215821, 0x140d2d78, 0x02de9454, 0x00005159, 0x3da16da4,
		0x0742ed13, 0x0d80888d, 0x004bc035, 0x0a79260d, 0x06fcdafe,
		0x2727d8ae, 0x1f6a2412, 0x0000e0c1,
	],
	[
		0x3c2291a9, 0x1ac2aba4, 0x3b215b4c, 0x131d037a, 0x17dde302,
		0x0c90b2e2, 0x0602c92d, 0x05ca9da9, 0x0000b01a, 0x0fc77fe2,
		0x35f1214e, 0x07e16bdf, 0x003ddc07, 0x2703791c, 0x3038b7ee,
		0x3dad56fe, 0x041d0c8d, 0x0000e85c,
	],
	[
		0x3187b2a3, 0x0018a1c0, 0x00fef5b3, 0x3e7e2e2a, 0x01fb607e,
		0x2cc199f0, 0x37b4625b, 0x0edbe82f, 0x00008e53, 0x01f400b4,
		0x15786a1b, 0x3041b21c, 0x31cd8cf2, 0x35900053, 0x1a7e0e9b,
		0x318366d0, 0x076f780c, 0x000073eb,
	],
	[
		0x1b6fb393, 0x13767707, 0x3ce97dbb, 0x348e2603, 0x354cadc1,
		0x09d0b4ea, 0x1b053404, 0x1de76fba, 0x000062d9, 0x0f09957e,
		0x295029a8, 0x3e76a78d, 0x3b547dae, 0x27cee0a2, 0x0575dc45,
		0x1d8244ff, 0x332f647a, 0x0000ad5a,
	],
	[
		0x10949ee0, 0x1e7a292e, 0x06df8b3d, 0x02b2e30b, 0x31f8729e,
		0x24e35475, 0x30b71878, 0x35edbfb7, 0x0000ea68, 0x0dd048fa,
		0x21688929, 0x0de823fe, 0x1c53faa9, 0x0ea0c84d, 0x052a592a,
		0x1fce7870, 0x11325cb2, 0x00002a27,
	],
	[
		0x04c5723f, 0x30d81a50, 0x048306e4, 0x329b11c7, 0x223fb545,
		0x085347a8, 0x2993e591, 0x1b5aca8e, 0x0000cef6, 0x04af0773,
		0x28d2eea9, 0x2751eeec, 0x037b4a7f, 0x3b4c1059, 0x08f37674,
		0x2ae906e1, 0x18a88a6a, 0x00008786,
	],
	[
		0x34bc21d1, 0x0cce474d, 0x15048bf4, 0x1d0bb409, 0x021cda16,
		0x20de76c3, 0x34c59063, 0x04ede20e, 0x00003ed1, 0x282a3740,
		0x0be3bbf3, 0x29889dae, 0x03413697, 0x34c68a09, 0x210ebe93,
		0x0c8a224c, 0x0826b331, 0x00009099,
	],
	[
		0x0624e3c4, 0x140317ba, 0x2f82c99d, 0x260c0a2c, 0x25d55179,
		0x194dcc83, 0x3d95e462, 0x356f6a05, 0x0000741d, 0x0d4481d3,
		0x2657fc8b, 0x1ba5ca71, 0x3ae44b0d, 0x07b1548e, 0x0e0d5522,
		0x05fdc567, 0x2d1aa70e, 0x00000770,
	],
	[
		0x06072c01, 0x23857675, 0x1ead58a9, 0x0b8a12d9, 0x1ee2fc79,
		0x0177cb61, 0x0495a618, 0x20deb82b, 0x0000177c, 0x2fc7bfd8,
		0x310eef8b, 0x1fb4df39, 0x3b8530e8, 0x0f4e7226, 0x0246b6d0,
		0x2a558a24, 0x163353af, 0x000063bb,
	],
	[
		0x24d2920b, 0x1c249dcc, 0x2069c5e5, 0x09ab2f9e, 0x36df3cf1,
		0x1991fd0c, 0x062b97a7, 0x1e80070e, 0x000054e7, 0x20d0b375,
		0x2e9f20bd, 0x35090081, 0x1c7a9ddc, 0x22e7c371, 0x087e3016,
		0x03175421, 0x3c6eca7d, 0x0000f599,
	],
	[
		0x259b9d5f, 0x0d9a318f, 0x23a0ef16, 0x00ebe4b7, 0x088265ae,
		0x2cde2666, 0x2bae7adf, 0x1371a5c6, 0x0000f045, 0x0d034f36,
		0x1f967378, 0x1b5fa3f4, 0x0ec8739d, 0x1643e62a, 0x1653947e,
		0x22d1f4e6, 0x0fb8d64b, 0x0000b5b9,
	],
];

// Lookup one of the Gwin[] values, by index. This is constant-time.
fn lookup_gwin(t: *p256_jacobian, idx: u32) void = {
	let xy: [18]u32 = [0...];
	let k: u32 = 0;
	let u: size = 0;

	for (let k = 0u32; k < 15; k += 1) {
		let m = -equ32(idx, k + 1);
		for (let u = 0z; u < 18; u += 1) {
			xy[u] |= m & gwin[k][u];
		};
	};
	t.x[..] = xy[..9];
	t.y[..] = xy[9..];
	t.z[..] = [0...];
	t.z[0] = 1;
};

// Multiply the generator by an integer. The integer is assumed non-zero
// and lower than the curve order.
fn p256_mulgen(p :*p256_jacobian, x: []u8) void = {
	// qz is a flag that is initially 1, and remains equal to 1
	// as long as the point is the point at infinity.
	//
	// We use a 4-bit window to handle multiplier bits by groups
	// of 4. The precomputed window is constant static data, with
	// points in affine coordinates; we use a constant-time lookup.
	let q = p256_jacobian { ... };
	let qz: u32 = 1;
	let xpos: size = 0;

	for (let i = len(x); i > 0; i -= 1) {
		let bx = x[xpos]: u32;
		xpos += 1;

		for (let k = 0z; k < 2; k += 1) {
			let bits: u32 = 0;
			let bnz: u32 = 0;
			let t = p256_jacobian { ... };
			let u = p256_jacobian { ... };

			p256_double(&q);
			p256_double(&q);
			p256_double(&q);
			p256_double(&q);
			bits = (bx >> 4) & 0x0f;
			bnz = nequ32(bits, 0);
			lookup_gwin(&t, bits);
			u = q;
			p256_add_mixed(&u, &t);
			jaccopy(bnz & qz, &q, &t);
			jaccopy(bnz & ~qz, &q, &u);
			qz &= ~bnz;
			bx <<= 4;
		};
	};
	*p = q;
};

const P256_G: [_]u8 = [
	0x04, 0x6b, 0x17, 0xd1, 0xf2, 0xe1, 0x2c, 0x42, 0x47, 0xf8, 0xbc, 0xe6,
	0xe5, 0x63, 0xa4, 0x40, 0xf2, 0x77, 0x03, 0x7d, 0x81, 0x2d, 0xeb, 0x33,
	0xa0, 0xf4, 0xa1, 0x39, 0x45, 0xd8, 0x98, 0xc2, 0x96, 0x4f, 0xe3, 0x42,
	0xe2, 0xfe, 0x1a, 0x7f, 0x9b, 0x8e, 0xe7, 0xeb, 0x4a, 0x7c, 0x0f, 0x9e,
	0x16, 0x2b, 0xce, 0x33, 0x57, 0x6b, 0x31, 0x5e, 0xce, 0xcb, 0xb6, 0x40,
	0x68, 0x37, 0xbf, 0x51, 0xf5
];

const P256_N: [_]u8 = [
	0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xbc, 0xe6, 0xfa, 0xad, 0xa7, 0x17, 0x9e, 0x84,
	0xf3, 0xb9, 0xca, 0xc2, 0xfc, 0x63, 0x25, 0x51
];

fn api256_mul(g: []u8, x: []u8) u32 = {
	if (len(g) != 65) {
		return 0;
	};

	let p = p256_jacobian { ... };
	let r = p256_decode(&p, g);

	p256_mul(&p, x);
	p256_to_affine(&p);
	p256_encode(g, &p);
	return r;
};

fn api256_mulgen(r: []u8, x: []u8) size = {
	let p = p256_jacobian { ... };

	p256_mulgen(&p, x);
	p256_to_affine(&p);
	p256_encode(r[..65], &p);
	return 65;
};

fn api256_muladd(a: []u8, b: []u8, x: []u8, y: []u8) u32 ={
	let p = p256_jacobian { ... };
	let q = p256_jacobian { ... };

	if (len(a) != 65) {
		return 0;
	};

	let r = p256_decode(&p, a);
	p256_mul(&p, x);
	if (len(b) == 0) {
		p256_mulgen(&q, y);
	} else {
		r &= p256_decode(&q, b);
		p256_mul(&q, y);
	};

	// The final addition may fail in case both points are equal.
	let t = p256_add(&p, &q);
	reduce_final_f256(p.z);
	let z: u32 = 0;
	for (let i = 0z; i < 9; i += 1) {
		z |= p.z[i];
	};
	z = equ32(z, 0);
	p256_double(&q);

	// If z is 1 then either P+Q = 0 (t = 1) or P = Q (t = 0). So we
	// have the following:
	//
	//   z = 0, t = 0   return P (normal addition)
	//   z = 0, t = 1   return P (normal addition)
	//   z = 1, t = 0   return Q (a 'double' case)
	//   z = 1, t = 1   report an error (P+Q = 0)
	jaccopy(z & ~t, &p, &q);
	p256_to_affine(&p);
	p256_encode(a, &p);
	r &= ~(z & t);
	return r;
};

fn api256_order() const []u8 = P256_N;
fn api256_generator() const []u8 = P256_G;

const _p256: curve = curve {
	pointsz = P256_POINTSZ,
	order = &api256_order,
	generator = &api256_generator,
	mul = &api256_mul,
	mulgen = &api256_mulgen,
	muladd = &api256_muladd,
	keygen = &mask_keygen,
};

// Size of a [[p256]] point in bytes.
export def P256_POINTSZ = len(P256_G);

// Size of a [[p256]] scalar in bytes.
export def P256_SCALARSZ = len(P256_N);

// A [[curve]] implementation of P-256, also known as secp256r1 or prime256v1.
export const p256: *curve = &_p256;
