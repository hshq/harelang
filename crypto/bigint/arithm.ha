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

// Adds 'b' to 'a', if 'ctl' is 1. If 'ctl' is 0, the result will be discarded.
// Returns the carry, if the addition overflows.
//
// 'a' and 'b' must have the same effective word length.
export fn add(a: []word, b: const []word, ctl: u32) u32 = {
	const l = ewordlen(a);
	assert(equ32(l, ewordlen(b)) == 1);

	let carry: u32 = 0;
	for (let i = 1z; i <= l; i += 1) {
		const n: u32 = a[i] + b[i] + carry;
		carry = n >> WORD_BITSZ;
		a[i] = muxu32(ctl, n & WORD_BITMASK, a[i]): word;
	};
	return carry;
};

// Subtracts 'b' from 'a', if 'ctl' is 1. If 'ctl' is 0, the result will be
// discared. Returns the carry, if the subtraction overflows.
//
// 'a' and 'b' must be of the same effective word length.
export fn sub(a: []word, b: const []word, do: u32) u32 = {
	const l = ewordlen(a);
	assert(equ32(l, ewordlen(b)) == 1);

	let carry: u32 = 0;
	for (let i = 1z; i <= l; i += 1) {
		let n: u32 = a[i] - b[i] - carry;
		carry = n >> WORD_BITSZ;
		a[i] = muxu32(do, n & WORD_BITMASK, a[i]): word;
	};
	return carry;
};

// Decrements 1 from an odd integer 'x'.
export fn decrodd(x: []word) void = {
	assert(isodd(x));
	x[1] ^= 1;
};

// Right-shift an integer 'x' by 'count'. The shift amount must be less than
// [[WORD_BITSZ]].
export fn rshift(x: []word, count: word) void = {
	assert(ltu32(count, WORD_BITSZ) == 1);

	const l = ewordlen(x);
	if (l == 0) {
		return;
	};

	let r = x[1] >> count;
	for (let i = 2z; i <= l; i += 1) {
		const w = x[i];
		x[i - 1] = (w << (WORD_BITSZ - count) | r) & WORD_BITMASK;
		r = w >> count;
	};
	x[l] = r;
};

// Multiply 'x' by 2^WORD_BITSZ and then add integer 'z', modulo 'm'. This
// function assumes that 'x' and 'm' have the same announced bit length, and the
// announced bit length of 'm' matches its true bit length.
//
// 'x' and 'm' may not refer to the same array.
//
// This function runs in constant time for a given announced bit length of 'x'
// and 'm'.
fn muladd_small(x: []word, z: word, m: const []word) void = {
	assert(&x[0] != &m[0], "'x' and 'm' may not refer to the same array");

	let hi: u32 = 0;

	// We can test on the modulus bit length since we accept to leak that
	// length.
	const m_bitlen = m[0];
	if (m_bitlen == 0) {
		return;
	};

	if (m_bitlen <= WORD_BITSZ) {
		hi = x[1] >> 1;
		const lo = (x[1] << WORD_BITSZ) | z;
		x[1] = divu32(hi, lo, m[1]).1: word;
		return;
	};

	let mlen = ewordlen(m);
	let mblr = m_bitlen & WORD_BITSZ: word;

	// Principle: we estimate the quotient (x*2^31+z)/m by
	// doing a 64/32 division with the high words.
	//
	// Let:
	//   w = 2^31
	//   a = (w*a0 + a1) * w^N + a2
	//   b = b0 * w^N + b2
	// such that:
	//   0 <= a0 < w
	//   0 <= a1 < w
	//   0 <= a2 < w^N
	//   w/2 <= b0 < w
	//   0 <= b2 < w^N
	//   a < w*b
	// I.e. the two top words of a are a0:a1, the top word of b is
	// b0, we ensured that b0 is "full" (high bit set), and a is
	// such that the quotient q = a/b fits on one word (0 <= q < w).
	//
	// If a = b*q + r (with 0 <= r < q), we can estimate q by
	// doing an Euclidean division on the top words:
	//   a0*w+a1 = b0*u + v  (with 0 <= v < b0)
	// Then the following holds:
	//   0 <= u <= w
	//   u-2 <= q <= u

	let a0: u32 = 0, a1: u32 = 0, b0: u32 = 0;
	hi = x[mlen];
	if (mblr == 0) {
		a0 = x[mlen];
		x[2..mlen+1] = x[1..mlen];
		x[1] = z;
		a1 = x[mlen];
		b0 = m[mlen];
	} else {
		a0 = ((x[mlen] << (WORD_BITSZ: word - mblr))
			| (x[mlen - 1] >> mblr)) & WORD_BITMASK;
		x[2..mlen+1] = x[1..mlen];
		x[1] = z;
		a1 = ((x[mlen] << (WORD_BITSZ: word - mblr))
			| (x[mlen - 1] >> mblr)) & WORD_BITMASK;
		b0 = ((m[mlen] << (WORD_BITSZ: word - mblr))
			| (m[mlen - 1] >> mblr)) & WORD_BITMASK;
	};

	// We estimate a divisor q. If the quotient returned by br_div()
	// is g:
	// -- If a0 == b0 then g == 0; we want q = 0x7FFFFFFF.
	// -- Otherwise:
	//    -- if g == 0 then we set q = 0;
	//    -- otherwise, we set q = g - 1.
	// The properties described above then ensure that the true
	// quotient is q-1, q or q+1.
	//
	// Take care that a0, a1 and b0 are 31-bit words, not 32-bit. We
	// must adjust the parameters to br_div() accordingly.
	//
	const (g, _) = divu32(a0 >> 1, a1 | (a0 << 31), b0);
	const q = muxu32(equ32(a0, b0), WORD_BITMASK,
		muxu32(equ32(g, 0), 0, g - 1));

	// We subtract q*m from x (with the extra high word of value 'hi').
	// Since q may be off by 1 (in either direction), we may have to
	// add or subtract m afterwards.
	//
	// The 'tb' flag will be true (1) at the end of the loop if the
	// result is greater than or equal to the modulus (not counting
	// 'hi' or the carry).
	let cc: u32 = 0;
	let tb: u32 = 1;
	for (let u = 1z; u <= mlen; u += 1) {
		const mw = m[u];
		const zl = mul31(mw, q) + cc;
		cc = (zl >> WORD_BITSZ): word;
		const zw = zl: word & WORD_BITMASK;
		const xw = x[u];
		let nxw = xw - zw;
		cc += nxw >> WORD_BITSZ;
		nxw &= WORD_BITMASK;
		x[u] = nxw;
		tb = muxu32(equ32(nxw, mw), tb, gtu32(nxw, mw));
	};

	// If we underestimated q, then either cc < hi (one extra bit
	// beyond the top array word), or cc == hi and tb is true (no
	// extra bit, but the result is not lower than the modulus). In
	// these cases we must subtract m once.
	//
	// Otherwise, we may have overestimated, which will show as
	// cc > hi (thus a negative result). Correction is adding m once.
	const over = gtu32(cc, hi);
	const under = ~over & (tb | ltu32(cc, hi));
	add(x, m, over);
	sub(x, m, under);
};


// Multiply two 31-bit integers, with a 62-bit result. This default
// implementation assumes that the basic multiplication operator
// yields constant-time code.
fn mul31(x: u32, y: u32) u64 = x: u64 * y: u64;
fn mul31_lo(x: u32, y: u32) u32 = (x: u32 * y: u32) & 0x7FFFFFFF;

// Calculate "m0i" which is equal to -(1/m0) mod 2^WORD_BITSZ, where m0 is the
// least significant value word of m: []word.
fn ninv31(m0: u32) u32 = {
	let y: u32 = 2 - m0;
	y *= 2 - y * m0;
	y *= 2 - y * m0;
	y *= 2 - y * m0;
	y *= 2 - y * m0;
	return muxu32(m0 & 1, -y, 0) & 0x7FFFFFFF;
};

// Calculates "m0i" which is equal to -(1/'m0') mod 2^WORD_BITSZ. 'm0' is the
// the first significant word of a big integer, which is the word at index 1.
export fn ninv(m0: word) word = ninv31(m0);


// Compute 'd' + 'a' * 'b', result in 'd'. The initial announced bit length of
// 'd' MUST match that of 'a'. The 'd' array MUST be large enough to accommodate
// the full result, plus (possibly) an extra word. The resulting announced bit
// length of 'd' will be the sum of the announced bit lengths of 'a' and 'b'
// (therefore, it may be larger than the actual bit length of the numerical
// result).
//
// 'a' and 'b' may be the same array. 'd' must be disjoint from both 'a' and
// 'b'.
export fn mulacc(d: []word, a: const []word, b: const []word) void = {
	assert(&a[0] != &d[0] && &b[0] != &d[0]);

	const alen = ewordlen(a);
	const blen = ewordlen(b);

	// We want to add the two bit lengths, but these are encoded,
	// which requires some extra care.
	const dl: u32 = (a[0] & WORD_BITSZ) + (b[0] & WORD_BITSZ);
	const dh: u32 = (a[0] >> WORD_SHIFT) + (b[0] >> WORD_SHIFT);
	d[0] = (dh << WORD_SHIFT) + dl
		+ (~(dl - WORD_BITSZ): u32 >> 31);

	for (let u = 0z; u < blen; u += 1) {
		// Carry always fits on 31 bits; we want to keep it in a
		// 32-bit register on 32-bit architectures (on a 64-bit
		// architecture, cast down from 64 to 32 bits means
		// clearing the high bits, which is not free; on a 32-bit
		// architecture, the same operation really means ignoring
		// the top register, which has negative or zero cost).
		const f: u32 = b[1 + u];
		let cc: u64 = 0; // TODO #if BR_64 u32

		for (let v = 0z; v < alen; v += 1) {

			let z: u64 = d[1 + u + v]: u64 + mul31(f, a[1 + v]) + cc;
			cc = z >> WORD_BITSZ;
			d[1 + u + v] = z: word & WORD_BITMASK;
		};
		d[1 + u + alen] = cc: word;
	};
};

// Reduce an integer 'a' modulo another 'm'. The result is written in 'x' and
// its announced bit length is set to be equal to that of 'm'.
//
// 'x' must be distinct from 'a' and 'm'.
//
// This function runs in constant time for given announced bit lengths of 'a'
// and 'm'.
export fn reduce(x: []word, a: const []word, m: const []word) void = {
	assert(&x[0] != &a[0] && &x[0] != &m[0]);

	const m_bitlen = m[0];
	const mlen = ewordlen(m);

	x[0] = m_bitlen;
	if (m_bitlen == 0) {
		return;
	};

	// If the source is shorter, then simply copy all words from a[]
	// and zero out the upper words.
	const a_bitlen = a[0];
	const alen = ewordlen(a);
	if (a_bitlen < m_bitlen) {
		x[1..1 + alen] = a[1..1 + alen];
		for (let u = alen; u < mlen; u += 1) {
			x[u + 1] = 0;
		};
		return;
	};

	// The source length is at least equal to that of the modulus.
	// We must thus copy N-1 words, and input the remaining words
	// one by one.
	x[1..mlen] = a[2 + (alen - mlen).. 1 + mlen];
	x[mlen] = 0;
	for (let u = 1 + alen - mlen; u > 0; u -= 1) {
		muladd_small(x, a[u], m);
	};
};

// Copies 'src' to 'dest' if ctl is 1. The length of 'src' must match the length
// of 'dest'.
fn ccopyword(ctl: u32, dest: []word, src: const []word) void = {
	for (let i = 0z; i < len(dest); i += 1) {
		const x = src[i];
		const y = dest[i];

		dest[i] = muxu32(ctl, x, y);
	};
};

// Compute a modular exponentiation. 'x' must be an integer modulo 'm' (same
// announced bit length, lower value). 'm' must be odd. The exponent is in
// big-endian unsigned notation, over len(e) bytes. The 'm0i' parameter is equal
// to -(1/m0) mod 2^31, where m0 is the least significant value word of 'm'
// (this works only if 'm' is an odd integer). See [[ninv]] on how to get this
// value. The 'tmp' array is used for temporaries and MUST be large enough to
// accommodate at least two temporary values with the same size as 'm'
// (including the leading 'bit length' word). If there is room for more
// temporaries, then this function may use the extra room for window-based
// optimisation, resulting in faster computations.
//
// Returned value is 1 on success, 0 on error. An error is reported if the
// provided 'tmp' array is too short.
export fn modpow(
	x: []word,
	e: const []u8,
	m: const []word,
	m0i: u32,
	tmp: []word,
) u32 = {
	assert(m[1] & 1 == 1, "'m' must be odd");
	assert(equ32(x[0], m[0]) == 1);

	// Get modulus size.
	let mwlen = ewordlen(m) + 1;
	const tmplen = (mwlen & 1) + mwlen;
	let t1 = tmp[..tmplen];
	let t2 = tmp[tmplen..];

	const twlen = len(tmp);
	if (twlen < (mwlen << 1)) {
		return 0;
	};

	// Compute possible window size, with a maximum of 5 bits.
	// When the window has size 1 bit, we use a specific code
	// that requires only two temporaries. Otherwise, for a
	// window of k bits, we need 2^k+1 temporaries.
	let win_len: word = 5;
	for (win_len > 1; win_len -= 1) {
		if (((1u32 << win_len: u32) + 1) * mwlen <= twlen) {
			break;
		};
	};

	// Everything is done in Montgomery representation.
	tomonty(x, m);

	// Compute window contents. If the window has size one bit only,
	// then t2 is set to x; otherwise, t2[0] is left untouched, and
	// t2[k] is set to x^k (for k >= 1).
	if (win_len == 1) {
		t2[..mwlen] = x[..mwlen];
	} else {
		let base = t2[mwlen..];
		base[..mwlen] = x[..mwlen];
		for (let u = 2z; u < (1u << win_len: uint); u += 1) {
			montymul(base[mwlen..2 * mwlen],
				base[..mwlen], x, m, m0i);
			base = base[mwlen..];
		};
	};

	// We need to set x to 1, in Montgomery representation. This can
	// be done efficiently by setting the high word to 1, then doing
	// one word-sized shift.
	zero(x, m[0]);
	x[ewordlen(m)] = 1;
	muladd_small(x, 0, m);

	let elen = len(e);
	let e = e[..];

	// We process bits from most to least significant. At each
	// loop iteration, we have acc_len bits in acc.
	let acc: word = 0;
	let acc_len = 0i;
	for (acc_len > 0 || elen > 0) {
		// Get the next bits.
		let k = win_len;
		if (acc_len: u32 < win_len) {
			if (elen > 0) {
				acc = (acc << 8) | e[0];
				e = e[1..];
				elen -= 1;
				acc_len += 8;
			} else {
				k = acc_len: u32;
			};
		};

		let bits: u32 = (acc >> (acc_len: u32 - k: u32))
			& ((1u32 << k: u32) - 1u32);
		acc_len -= k: int;

		// We could get exactly k bits. Compute k squarings.
		for (let i = 0z; i < k: size; i += 1) {
			montymul(t1, x, x, m, m0i);
			// memcpy(x, t1, mlen);
			x[..mwlen] = t1[..mwlen];
		};

		// Window lookup: we want to set t2 to the window
		// lookup value, assuming the bits are non-zero. If
		// the window length is 1 bit only, then t2 is
		// already set; otherwise, we do a constant-time lookup.
		if (win_len > 1) {
			zero(t2, m[0]);
			let base = t2[mwlen..];
			for (let u = 1u32; u < (1 << k): size; u += 1) {
				let mask: u32 = -equ32(u, bits);
				for (let v = 1z; v < mwlen; v += 1) {
					t2[v] |= mask & base[v];
				};
				base = base[mwlen..];
			};
		};

		// Multiply with the looked-up value. We keep the
		// product only if the exponent bits are not all-zero.
		montymul(t1, x, t2, m, m0i);

		ccopyword(nequ32(bits, 0), x[..mwlen], t1[..mwlen]);
	};

	// Convert back from Montgomery representation, and exit.
	frommonty(x, m, m0i);
	return 1;
};
