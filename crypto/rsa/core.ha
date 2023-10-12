// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The following code was initially ported from BearSSL.
//
// Copyright (c) 2016 Thomas Pornin <pornin@bolet.org>
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
use crypto::bigint::*;
use crypto::math::{divu32};
use errors;
use types;

// Maximum factor size of a key of [[BITSZ]].
def MAXFACTOR: size = ((BITSZ + 64) >> 1);

// Required buf size for the [[pubexp]] operation.
def PUBEXP_BUFSZ: size = size(word) * (1 + (4 * (2
		+ ((BITSZ + WORD_BITSZ - 1) / WORD_BITSZ))));

// Requried buf size for the [[privexp]] operation.
def PRIVEXP_BUFSZ: size = size(word) * (1 + (8 * (2
		+ ((MAXFACTOR + WORD_BITSZ - 1) / WORD_BITSZ))));

// Performs the modular exponentiation of 'x' with the public exponent of 'pub'.
// 'x' is modified in place. 'x' must be the same length as the actual length
// of 'pub.n'.
//
// For the size of 'buf' see [[PUBEXP_BUFSZ]]. If the buffer is not large
// enough, [[errors::overflow]] will be returned. In case of 'x' being not of
// required length or if 'x' is not modulo 'pub.n' [[errors::invalid]] is
// returned and 'x' will be zeroed.
fn pubexp(pub: *pubparams, x: []u8, buf: []u8) (void | error) = {
	// supported key length leaks. But that is not a problem.
	const wbuflen = len(buf) / size(word);
	let wbuf: []word = (buf: *[*]word)[..wbuflen];
	let n = pub.n;

	// get the maximal allowed key size for given buffer. Reverse of the
	// [[PUBEXP_BUFSZ]] equation.
	const maxkeybits = (((wbuflen - 1) / 4) - 2) * WORD_BITSZ;

	if (len(n) == 0 || len(n) > (maxkeybits >> 3)) {
		return errors::overflow;
	};

	if (len(x) != len(n)) {
		bytes::zero(x);
		return errors::invalid;
	};

	// add word size - 1 to ceil required words in the division that follows
	const maxnbitlen = (len(n) << 3) + WORD_BITSZ: size - 1;
	assert(maxnbitlen <= types::U32_MAX);
	let bwordlen = 1 + divu32(0, maxnbitlen: u32, WORD_BITSZ).0;

	// make it even
	bwordlen += bwordlen & 1;

	let nenc = wbuf[..bwordlen];
	let xenc = wbuf[bwordlen..2 * bwordlen];
	let t = wbuf[2 * bwordlen..];

	// From now on, buf will be indirectly used via slices borrowed from
	// wbuf. Therefore make sure it gets cleared in the end.
	defer bytes::zero(buf);

	encode(nenc, n);
	const n0i = ninv(nenc[1]);

	// if m is odd, n0i is also.
	let result: word = n0i & 1;
	result &= encodemod(xenc, x, nenc);

	modpow(xenc, pub.e, nenc, n0i, t);

	decode(x, xenc);

	if (result == 0: word) {
		bytes::zero(x);
		return errors::invalid;
	};
};

// Performs modular exponentiation of 'x' with the private exponent of 'priv'.
// 'x' is modified in place. 'x' must be the same length as the actual length
// of the modulus n (see [[privkey_nsize]]).
//
// For size of 'buf' see [[PRIVEXP_BUFSZ]]. If the buffer is not large enough
// [[errors::overflow]] will be returned. In case of an invalid size of 'x' or
// an invalid key, [[errors::invalid]] will be returned and 'x' will be zeroed.
fn privexp(priv: *privparams, x: []u8, buf: []u8) (void | error) = {
	// supported key length leaks. But that is not a problem.
	const wbuflen = len(buf) / size(word);
	let wbuf: []word = (buf: *[*]word)[..wbuflen];

	let p = priv.p;
	let q = priv.q;

	const maxflen = if (len(p) > len(q)) len(p) else len(q);

	// add word size - 1 to ceil required words in the division that follows
	const maxfbitlen = (maxflen << 3) + WORD_BITSZ: size - 1;
	assert(maxfbitlen <= types::U32_MAX);
	let bwordlen = 1 + divu32(0, maxfbitlen: u32, WORD_BITSZ).0;

	// make it even
	bwordlen += bwordlen & 1;

	// We need at least 6 big integers for the following calculations
	if (6 * bwordlen > len(wbuf)) {
		return errors::overflow;
	};

	// From now on, buf will be indirectly used via wbuf. Therefore make
	// sure it gets cleared in the end.
	defer bytes::zero(buf);

	let mq = wbuf[..bwordlen];
	encode(mq, q);

	let t1 = wbuf[bwordlen..2 * bwordlen];
	encode(t1, p);

	// compute modulus n
	let t2 = wbuf[2 * bwordlen..4 * bwordlen];
	zero(t2, mq[0]);
	mulacc(t2, mq, t1);

	// ceiled modulus length in bytes
	const nlen = (priv.nbitlen + 7) >> 3;
	if(len(x) != nlen) {
		bytes::zero(x);
		return errors::invalid;
	};

	let t3 = wbuf[4 * bwordlen..6 * bwordlen];
	let t3 = (t3: *[*]u8)[..nlen];
	decode(t3, t2);
	let r: u32 = 0;

	// Check if x is mod n.
	//
	// We encode the modulus into bytes, to perform the comparison with
	// bytes. We know that the product length, in bytes, is exactly nlen.
	//
	// The comparison actually computes the carry when subtracting the
	// modulus from the source value; that carry must be 1 for a value in
	// the correct range. We keep it in r, which is our accumulator for the
	// error code.
	for (let u = nlen; u > 0) {
		u -= 1;
		r = ((x[u] - (t3[u] + r)) >> 8) & 1;
	};

	// Move the decoded p to another temporary buffer.
	let mp = wbuf[2 * bwordlen..3 * bwordlen];
	mp[..] = t1[..];

	// Compute s2 = x^dq mod q.
	const q0i = ninv(mq[1]);
	let s2 = wbuf[bwordlen..bwordlen * 3];
	encodereduce(s2, x, mq);
	r &= modpow(s2, priv.dq, mq, q0i, wbuf[3 * bwordlen..]);

	// Compute s1 = x^dp mod p.
	const p0i = ninv(mp[1]);
	let s1 = wbuf[bwordlen * 3..];
	encodereduce(s1, x, mp);
	r &= modpow(s1, priv.dp, mp, p0i, wbuf[4 * bwordlen..]);

	// Compute:
	//   h = (s1 - s2)*(1/q) mod p
	// s1 is an integer modulo p, but s2 is modulo q. PKCS#1 is
	// unclear about whether p may be lower than q (some existing,
	// widely deployed implementations of RSA don't tolerate p < q),
	// but we want to support that occurrence, so we need to use the
	// reduction function.
	//
	// Since we use br_i31_decode_reduce() for iq (purportedly, the
	// inverse of q modulo p), we also tolerate improperly large
	// values for this parameter.
	let t1 = wbuf[4 * bwordlen..5 * bwordlen];
	let t2 = wbuf[5 * bwordlen..];

	reduce(t2, s2, mp);
	add(s1, mp, sub(s1, t2, 1));
	tomonty(s1, mp);
	encodereduce(t1, priv.iq, mp);
	montymul(t2, s1, t1, mp, p0i);

	// h is now in t2. We compute the final result:
	//   s = s2 + q*h
	// All these operations are non-modular.
	//
	// We need mq, s2 and t2. We use the t3 buffer as destination.
	// The buffers mp, s1 and t1 are no longer needed, so we can
	// reuse them for t3. Moreover, the first step of the computation
	// is to copy s2 into t3, after which s2 is not needed. Right
	// now, mq is in slot 0, s2 is in slot 1, and t2 is in slot 5.
	// Therefore, we have ample room for t3 by simply using s2.
	let t3 = s2;
	mulacc(t3, mq, t2);

	// Encode the result. Since we already checked the value of xlen,
	// we can just use it right away.
	decode(x, t3);

	if ((p0i & q0i & r) != 1) {
		bytes::zero(x);
		return errors::invalid;
	};
};
