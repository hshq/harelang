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

// Minimal required words to encode 'x' into an []word. To statically allocate
// resources, following expression may be used:
//
//     ((number_of_bits + WORD_BITSZ - 1) / WORD_BITSZ) + 1
export fn encodelen(x: []u8) size = {
	return (((len(x) * 8) + WORD_BITSZ - 1) / WORD_BITSZ) + 1;
};

// Encode 'src' from its big-endian unsigned encoding into the internal
// representation. The caller must make sure that 'dest' has enough space to
// store 'src'. See [[encodelen]] for how to calculate the required size.
//
// This function runs in constant time for given 'src' length.
export fn encode(dest: []word, src: const []u8) void = {
	let acc: u32 = 0;
	let accbits: u32 = 0;
	let didx: size = 1;

	for (let i = len(src) - 1; i < len(src); i -= 1) {
		acc |= (src[i] << accbits);
		accbits += 8;

		if (accbits >= WORD_BITSZ) {
			dest[didx] = (acc & WORD_BITMASK): word;
			accbits -= WORD_BITSZ;
			acc = src[i] >> (8 - accbits);
			didx += 1;
		};
	};

	dest[didx] = acc: word;

	dest[0] = countbits(dest[1..didx + 1]): word;
};

// Get the announced bit length of 'n' in encoded form.
fn countbits(n: const []word) u32 = {
	let tw: u32 = 0;
	let twk: u32 = 0;

	for (let i = len(n) - 1; i < len(n); i -= 1) {
		const c = equ32(tw, 0);
		const w = n[i];
		tw = muxu32(c, w, tw);
		twk = muxu32(c, i: u32, twk);
	};

	return (twk << WORD_SHIFT) + word_countbits(tw);
};

// Counts the number of bits until including the highest bit set to 1.
fn word_countbits(x: u32) u32 = {
	let k: u32 = nequ32(x, 0);
	let c: u32 = 0;

	c = gtu32(x, 0xffff);
	x = muxu32(c, x >> 16, x);
	k += c << 4;

	c = gtu32(x, 0x00ff);
	x = muxu32(c, x >>  8, x);
	k += c << 3;

	c = gtu32(x, 0x000f);
	x = muxu32(c, x >>  4, x);
	k += c << 2;

	c = gtu32(x, 0x0003);
	x = muxu32(c, x >>  2, x);
	k += c << 1;

	k += gtu32(x, 0x0001);

	return k;
};

// Get the encoded bit length of a word.
fn ebitlen(x: const []word) u32 = {
	return x[0];
};

// Get the effective word lenght of 'x'. The effective wordlen is the number of
// words that are used to represent the actual value. Eg. the number 7 will have
// an effective word length of 1, no matter of len(x). The first element
// containing the encoded word len is not added to the result.
export fn ewordlen(x: const []word) u32 = {
	return (x[0] + WORD_BITSZ) >> WORD_SHIFT;
};

// Decode 'src' into a big-endian unsigned byte array. The caller must ensure
// that 'dest' has enough space to store the decoded value. See [[decodelen]] on
// how to determine the required length.
export fn decode(dest: []u8, src: const []word) void = {
	let acc: u64 = 0;
	let accbits: u64 = 0;
	let sidx: size = 1;
	let sz = ewordlen(src);
	for (let i = len(dest) - 1; i < len(dest); i -= 1) {
		if (accbits < 8) {
			if (sidx <= sz) {
				acc |= ((src[sidx]: u64) << accbits: u64): u64;
				sidx += 1;
			};
			accbits += WORD_BITSZ;
		};
		dest[i] = acc: u8;
		acc >>= 8;
		accbits -= 8;
	};
};

// Returns the number of bytes required to store a big integer given by 'src'.
//
// For static allocation following expression may be used:
//
//     ((len(src) - 1) * WORD_BITSZ + 7) / 8
export fn decodelen(src: const []word) size = {
	return ((len(src) - 1) * WORD_BITSZ + 7) / 8;
};

// Encodes an integer from its big-endian unsigned encoding. 'src' must be lower
// than 'm'. If not 'dest' will be set to 0. 'dest' will have the announced bit
// length of 'm' after decoding.
//
// The return value is 1 if the decoded value fits within 'm' or 0 otherwise.
//
// This function runs in constant time for a given 'src' length and announced
// bit length of m, independent of whether the value fits within 'm' or not.
export fn encodemod(dest: []word, src: const []u8, m: const []word) u32 = {
	// Two-pass algorithm: in the first pass, we determine whether the
	// value fits; in the second pass, we do the actual write.
	//
	// During the first pass, 'r' contains the comparison result so
	// far:
	//  0x00000000   value is equal to the modulus
	//  0x00000001   value is greater than the modulus
	//  0xFFFFFFFF   value is lower than the modulus
	//
	// Since we iterate starting with the least significant bytes (at
	// the end of src[]), each new comparison overrides the previous
	// except when the comparison yields 0 (equal).
	//
	// During the second pass, 'r' is either 0xFFFFFFFF (value fits)
	// or 0x00000000 (value does not fit).
	//
	// We must iterate over all bytes of the source, _and_ possibly
	// some extra virtual bytes (with value 0) so as to cover the
	// complete modulus as well. We also add 4 such extra bytes beyond
	// the modulus length because it then guarantees that no accumulated
	// partial word remains to be processed.

	let mlen = 0z, tlen = 0z;

	mlen = ewordlen(m);
	tlen = mlen << (WORD_SHIFT - 3); // mlen in bytes
	if (tlen < len(src)) {
		tlen = len(src);
	};
	tlen += 4;
	let r: u32 = 0;
	for (let pass = 0z; pass < 2; pass += 1) {
		let v: size = 1;
		let acc: u32 = 0, acc_len: u32 = 0;

		for (let u = 0z; u < tlen; u += 1) {
			// inner loop is similar to encode until the mlen check
			let b: u32 = 0;

			if (u < len(src)) {
				b = src[len(src) - 1 - u];
			};
			acc |= (b << acc_len);
			acc_len += 8;
			if (acc_len >= WORD_BITSZ) {
				const xw: u32 = acc & WORD_BITMASK;
				acc_len -= WORD_BITSZ;
				acc = b >> (8 - acc_len);
				if (v <= mlen) {
					if (pass == 1) {
						dest[v] = (r & xw): word;
					} else {
						let cc = cmpu32(xw, m[v]: u32): u32;
						r = muxu32(equ32(cc, 0), r, cc);
					};
				} else {
					if (pass == 0) {
						r = muxu32(equ32(xw, 0), r, 1);
					};
				};
				v += 1;
			};
		};

		// When we reach this point at the end of the first pass:
		// r is either 0, 1 or -1; we want to set r to 0 if it
		// is equal to 0 or 1, and leave it to -1 otherwise.
		//
		// When we reach this point at the end of the second pass:
		// r is either 0 or -1; we want to leave that value
		// untouched. This is a subcase of the previous.
		r >>= 1;
		r |= (r << 1);
	};

	dest[0] = m[0];
	return r & 1;
};

// Encode an integer from its big-endian unsigned representation, and reduce it
// modulo the provided modulus 'm'. The announced bit length of the result is
// set to be equal to that of the modulus.
//
// 'dest' must be distinct from 'm'.
export fn encodereduce(dest: []word, src: const []u8, m: const []word) void = {
	assert(&dest[0] != &m[0], "'dest' and 'm' must be distinct");

	// Get the encoded bit length.
	const m_ebitlen = m[0];

	// Special case for an invalid (null) modulus.
	if (m_ebitlen == 0) {
		dest[0] = 0;
		return;
	};

	zero(dest, m_ebitlen);

	// First decode directly as many bytes as possible. This requires
	// computing the actual bit length.
	let m_rbitlen = m_ebitlen >> WORD_SHIFT;
	m_rbitlen = (m_ebitlen & WORD_BITSZ)
		+ (m_rbitlen << WORD_SHIFT) - m_rbitlen;
	const mblen: size = (m_rbitlen + 7) >> 3;
	let k: size = mblen - 1;
	if (k >= len(src)) {
		encode(dest, src);
		dest[0] = m_ebitlen;
		return;
	};
	encode(dest, src[..k]);
	dest[0] = m_ebitlen;

	// Input remaining bytes, using 31-bit words.
	let acc: word = 0;
	let acc_len: word = 0;
	for (k < len(src)) {
		const v = src[k];
		k += 1;
		if (acc_len >= 23) {
			acc_len -= 23;
			acc <<= (8 - acc_len);
			acc |= v >> acc_len;
			muladd_small(dest, acc, m);
			acc = v & (0xFF >> (8 - acc_len));
		} else {
			acc = (acc << 8) | v;
			acc_len += 8;
		};
	};

	// We may have some bits accumulated. We then perform a shift to
	// be able to inject these bits as a full 31-bit word.
	if (acc_len != 0) {
		acc = (acc | (dest[1] << acc_len)) & WORD_BITMASK;
		rshift(dest, WORD_BITSZ - acc_len);
		muladd_small(dest, acc, m);
	};
};
