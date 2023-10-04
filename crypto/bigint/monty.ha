// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The following code was initially ported from BearSSL.
//
// Copyright (c) 2017 Thomas Pornin <pornin@bolet.org>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
use crypto::math::*;

// Convert a modular integer to Montgomery representation. The integer 'x' must
// be lower than 'm', but with the same announced bit length.
export fn tomonty(x: []word, m: const []word) void = {
	assert(equ32(x[0], m[0]) == 1);
	for (let k: u32 = ewordlen(m); k > 0; k -= 1) {
		muladd_small(x, 0, m);
	};
};

// Convert a modular integer back from Montgomery representation. The integer
// 'x' must be less than 'm', but with the same announced bit length. The 'm0i'
// parameter is equal to -(1/m0) mod 2^32, where m0 is the least significant
// value word of 'm' (this works only if 'm' is an odd integer). See [[ninv]]
// for how to get this value.
export fn frommonty(x: []word, m: const []word, m0i: word) void = {
	assert(equ32(x[0], m[0]) == 1);
	const mlen = ewordlen(m);
	for (let u = 0z; u < mlen; u += 1) {
		const f: u32 = mul31_lo(x[1], m0i);
		let cc: u64 = 0;
		for (let v = 0z; v < mlen; v += 1) {
			const z: u64 = x[v + 1]: u64 + mul31(f, m[v + 1]) + cc;
			cc = z >> 31;
			if (v != 0) {
				x[v] = z: word & WORD_BITMASK;
			};
		};
		x[mlen] = cc: u32;
	};

	// We may have to do an extra subtraction, but only if the
	// value in x[] is indeed greater than or equal to that of m[],
	// which is why we must do two calls (first call computes the
	// carry, second call performs the subtraction only if the carry
	// is 0).
	sub(x, m, notu32(sub(x, m, 0)));
};

// Compute a modular Montgomery multiplication. 'd' is filled with the value of
// 'x'*'y'/R modulo 'm' (where R is the Montgomery factor). The array 'd' must
// be distinct from 'x', 'y' and 'm'. 'x' and 'y' must be numerically lower than
// 'm'. 'x' and 'y' may be the same array. The 'm0i' parameter is equal to
// -(1/m0) mod 2^32, where m0 is the least significant value word of 'm' (this
// works only if 'm' is an odd integer). See [[ninv]] for how to get this value.
export fn montymul(
	d: []word,
	x: const []word,
	y: const []word,
	m: const []word,
	m0i: u32
) void = {
	// Each outer loop iteration computes:
	//   d <- (d + xu*y + f*m) / 2^31
	// We have xu <= 2^31-1 and f <= 2^31-1.
	// Thus, if d <= 2*m-1 on input, then:
	//   2*m-1 + 2*(2^31-1)*m <= (2^32)*m-1
	// and the new d value is less than 2*m.
	//
	// We represent d over 31-bit words, with an extra word 'dh'
	// which can thus be only 0 or 1.
	let v: size = 0;

	const mlen = ewordlen(m);
	const len4 = mlen & ~3: size;
	zero(d, m[0]);
	let dh: u32 = 0;
	for (let u = 0z; u < mlen; u += 1) {
		// The carry for each operation fits on 32 bits:
		//   d[v+1] <= 2^31-1
		//   xu*y[v+1] <= (2^31-1)*(2^31-1)
		//   f*m[v+1] <= (2^31-1)*(2^31-1)
		//   r <= 2^32-1
		//   (2^31-1) + 2*(2^31-1)*(2^31-1) + (2^32-1) = 2^63 - 2^31
		// After division by 2^31, the new r is then at most 2^32-1
		//
		// Using a 32-bit carry has performance benefits on 32-bit
		// systems; however, on 64-bit architectures, we prefer to
		// keep the carry (r) in a 64-bit register, thus avoiding some
		// "clear high bits" operations.

		const xu: u32 = x[u + 1];
		const f: u32 = mul31_lo((d[1] + mul31_lo(x[u + 1], y[1])), m0i);

		let r: u64 = 0; // TODO if !BR_64 u32
		v = 0;
		for (v < len4; v += 4) {
			let z: u64 = d[v + 1]: u64 + mul31(xu, y[v + 1])
				+ mul31(f, m[v + 1]) + r;
			r = z >> 31;
			d[v + 0] = z: u32 & 0x7FFFFFFF;
			z = d[v + 2]: u64 + mul31(xu, y[v + 2])
				+ mul31(f, m[v + 2]) + r;
			r = z >> 31;
			d[v + 1] = z: u32 & 0x7FFFFFFF;
			z = d[v + 3]: u64 + mul31(xu, y[v + 3])
				+ mul31(f, m[v + 3]) + r;
			r = z >> 31;
			d[v + 2] = z: u32 & 0x7FFFFFFF;
			z = d[v + 4]: u64 + mul31(xu, y[v + 4])
				+ mul31(f, m[v + 4]) + r;
			r = z >> 31;
			d[v + 3] = z: u32 & 0x7FFFFFFF;
		};
		for (v < mlen; v += 1) {
			const z: u64 = d[v + 1]: u64 + mul31(xu, y[v + 1])
				+ mul31(f, m[v + 1]) + r;
			r = z >> 31;
			d[v] = z: u32 & 0x7FFFFFFF;
		};

		// Since the new dh can only be 0 or 1, the addition of
		// the old dh with the carry MUST fit on 32 bits, and
		// thus can be done into dh itself.
		dh += r: u32;
		d[mlen] = dh & 0x7FFFFFFF;
		dh >>= 31;
	};

	// We must write back the bit length because it was overwritten in
	// the loop (not overwriting it would require a test in the loop,
	// which would yield bigger and slower code).
	d[0] = m[0];

	// d[] may still be greater than m[] at that point; notably, the
	// 'dh' word may be non-zero.
	sub(d, m, nequ32(dh, 0) | notu32(sub(d, m, 0)));
};
