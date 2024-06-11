// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Ported from BearSSL
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

use crypto::ec;
use crypto::bigint;
use hash;
use crypto::bigint::{word};

def POINTSZ = 1 + ((ec::MAX_COORDBITSZ + bigint::WORD_BITSZ - 1)
	/ bigint::WORD_BITSZ);

// Maximum signature size of curves supported by [[crypto::ec]].
export def MAX_SIGSZ = ec::MAX_POINTSZ - 1;

// Returns the size of a signature created/verifiable with given key. It is
// [[crypto::ec::pointsz]] - 1 for the NIST curves.
export fn sigsz(key: (*pubkey | *privkey)) size = {
	let c = match (key) {
	case let k: *pubkey =>
		yield k.curve;
	case let k: *privkey =>
		yield k.curve;
	};
	return c.pointsz - 1;
};

// Size of signature created with a P256 key.
export def P256_SIGSZ = 64;

// Size of signature created with a P384 key.
export def P384_SIGSZ = 96;

// Size of signature created with a P521 key.
export def P521_SIGSZ = 132;

// Verifies the signature 'sig' with message 'hash' using the public key 'pub'.
// Returns [[invalidkey]] or [[invalidsig]] in case of error. An invalid key may
// not be detected and causes an [[invalidsig]] in this case. Verification is
// done in constant time, but may return earlier if the signature format is not
// valid.
export fn verify(pub: *pubkey, hash: []u8, sig: []u8) (void | error) = {
	// IMPORTANT: this code is fit only for curves with a prime
	// order. This is needed so that modular reduction of the X
	// coordinate of a point can be done with a simple subtraction.
	assert(pub.curve == ec::p256 || pub.curve == ec::p384
		|| pub.curve == ec::p521);

	let n: [POINTSZ]bigint::word = [0...];
	let r: [POINTSZ]bigint::word = [0...];
	let s: [POINTSZ]bigint::word = [0...];
	let t: [POINTSZ*2]bigint::word = [0...];
	let t1 = t[..POINTSZ];
	let t2 = t[POINTSZ..];

	let tx: [(ec::MAX_COORDBITSZ + 7) >> 3]u8 = [0...];
	let ty: [(ec::MAX_COORDBITSZ + 7) >> 3]u8 = [0...];
	let eu: [ec::MAX_POINTSZ]u8 = [0...];

	let q = pub.get_q(pub);

	// Signature length must be even.
	if (len(sig) & 1 == 1) {
		return invalidsig;
	};
	let rlen = len(sig) >> 1;

	let generator = pub.curve.generator();
	// Public key point must have the proper size for this curve.
	if (len(q) != len(generator)) {
		return invalidkey;
	};

	// Get modulus; then decode the r and s values. They must be
	// lower than the modulus, and s must not be null.
	let order = pub.curve.order();
	const nlen = len(order);


	bigint::encode(n, order);
	let n0i = bigint::ninv(n[1]);
	if (bigint::encodemod(r, sig[..rlen], n) == 0) {
		return invalidsig;
	};
	if (bigint::encodemod(s, sig[rlen..2 * rlen], n) == 0) {
		return invalidsig;
	};
	if (bigint::iszero(s) == 1) {
		return invalidsig;
	};

	// Invert s. We do that with a modular exponentiation; we use
	// the fact that for all the curves we support, the least
	// significant byte is not 0 or 1, so we can subtract 2 without
	// any carry to process.
	// We also want 1/s in Montgomery representation, which can be
	// done by converting _from_ Montgomery representation before
	// the inversion (because (1/s)*R = 1/(s/R)).
	bigint::frommonty(s, n, n0i);
	tx[..nlen] = order[..];
	tx[nlen - 1] -= 2;
	bigint::modpow(s, tx[..nlen], n, n0i, t);


	t1[..] = [0...];
	// Truncate the hash to the modulus length (in bits) and reduce
	// it modulo the curve order. The modular reduction can be done
	// with a subtraction since the truncation already reduced the
	// value to the modulus bit length.
	bits2int(t1, hash, n[0]);
	bigint::sub(t1, n, bigint::sub(t1, n, 0) ^ 1);

	// Multiply the (truncated, reduced) hash value with 1/s, result in
	// t2, encoded in ty.
	bigint::montymul(t2, t1, s, n, n0i);
	bigint::decode(ty[..nlen], t2);

	// Multiply r with 1/s, result in t1, encoded in tx.
	bigint::montymul(t1, r, s, n, n0i);
	bigint::decode(tx[..nlen], t1);

	// Compute the point x*Q + y*G.
	let ulen = len(generator);
	eu[..ulen] = q[..ulen];
	let res = pub.curve.muladd(eu[..ulen], [], tx[..nlen], ty[..nlen]);

	// Get the X coordinate, reduce modulo the curve order, and
	// compare with the 'r' value.
	//
	// The modular reduction can be done with subtractions because
	// we work with curves of prime order, so the curve order is
	// close to the field order (Hasse's theorem).
	bigint::zero(t1, n[0]);
	bigint::encode(t1, eu[1..(ulen >> 1) + 1]);
	t1[0] = n[0];
	bigint::sub(t1, n, bigint::sub(t1, n, 0) ^ 1);
	res &= ~bigint::sub(t1, r, 1);
	res &= bigint::iszero(t1);

	if (res != 1) {
		return invalidsig;
	};
};

def ORDER_LEN = (ec::MAX_COORDBITSZ + 7) >> 3;

// Signs hashed message 'hash' with the private key and stores it into 'sig'.
// Returns the number of bytes written to sig on success or [[invalidkey]]
// otherwise.
//
// The signature is done in a deterministic way according to RFC 6979, hence
// 'hashfn' and 'hashbuf' are required. 'hashfn' can be the same as the one that
// created 'hash', though it might not be. The overall security will be limited
// by the weaker of the two hash functions, according to the RFC. 'hashbuf' must
// be of size [[hash::sz]] of 'hashfn' * 2 + [[hash::bsz]] of 'hashfn'.
//
// For the size requirenment of 'sig' see [[sigsz]].
export fn sign(
	priv: *privkey,
	hash: []u8,
	hashfn: *hash::hash,
	hashbuf: []u8,
	sig: []u8
) (u32 | invalidkey) =  {
	// IMPORTANT: this code is fit only for curves with a prime
	// order. This is needed so that modular reduction of the X
	// coordinate of a point can be done with a simple subtraction.
	// We also rely on the last byte of the curve order to be distinct
	// from 0 and 1.
	assert(priv.curve == ec::p256 || priv.curve == ec::p384
		|| priv.curve == ec::p521);

	let n: [POINTSZ]bigint::word = [0...];
	let r: [POINTSZ]bigint::word = [0...];
	let s: [POINTSZ]bigint::word = [0...];
	let x: [POINTSZ]bigint::word = [0...];
	let m: [POINTSZ]bigint::word = [0...];
	let k: [POINTSZ]bigint::word = [0...];
	let tmp: [POINTSZ * 2]bigint::word = [0...];

	let tt: [ORDER_LEN << 1]u8 = [0...];
	let eu: [ec::MAX_POINTSZ]u8 = [0...];

	// Get modulus.
	let order = priv.curve.order();
	const nlen = len(order);

	bigint::encode(n, order);
	const n0i = bigint::ninv(n[1]);

	// Get private key as an i31 integer. This also checks that the
	// private key is well-defined (not zero, and less than the
	// curve order).
	if (bigint::encodemod(x, priv.get_x(priv), n) == 0) {
		return invalidkey;
	};
	if (bigint::iszero(x) == 1) {
		return invalidkey;
	};

	// Truncate and reduce the hash value modulo the curve order.
	bits2int(m, hash, n[0]);
	bigint::sub(m, n, bigint::sub(m, n, 0) ^ 1);

	bigint::decode(tt[..nlen], x);
	bigint::decode(tt[nlen..nlen * 2], m);

	// RFC 6979 generation of the "k" value.
	//
	// The process uses HMAC_DRBG (with the hash function used to
	// process the message that is to be signed). The seed is the
	// concatenation of the encodings of the private key and
	// the hash value (after truncation and modular reduction).
	hash::reset(hashfn);
	let drbg = hmac_drbg(hashfn, tt[..nlen*2], hashbuf);

	for (true) {
		hmac_drbg_generate(&drbg, eu[..nlen]);
		bits2int(k, eu[..nlen], n[0]);

		if (bigint::iszero(k) == 1) continue;
		if (bigint::sub(k, n, 0) > 0) {
			break;
		};
	};

	// Compute k*G and extract the X coordinate, then reduce it
	// modulo the curve order. Since we support only curves with
	// prime order, that reduction is only a matter of computing
	// a subtraction.
	bigint::decode(tt[..nlen], k[..]);

	let ulen = priv.curve.mulgen(eu, tt[..nlen]);

	bigint::zero(r, n[0]);
	bigint::encode(r, eu[1..(ulen >> 1) + 1]);
	r[0] = n[0];
	bigint::sub(r, n, bigint::sub(r, n, 0) ^ 1);

	// Compute 1/k in double-Montgomery representation. We do so by
	// first converting _from_ Montgomery representation (twice),
	// then using a modular exponentiation.
	bigint::frommonty(k, n, n0i);
	bigint::frommonty(k, n, n0i);
	tt[..nlen] = order[..nlen];
	tt[nlen - 1] -= 2;

	bigint::modpow(k, tt[..nlen], n, n0i, tmp);

	// Compute s = (m+xr)/k (mod n).
	// The k[] array contains R^2/k (double-Montgomery representation);
	// we thus can use direct Montgomery multiplications and conversions
	// from Montgomery, avoiding any call to br_i31_to_monty() (which
	// is slower).
	let t1 = tmp[..POINTSZ];
	let t2 = tmp[POINTSZ..];
	bigint::frommonty(m, n, n0i);
	bigint::montymul(t1, x, r, n, n0i);
	let ctl = bigint::add(t1, m, 1);
	ctl |= bigint::sub(t1, n, 0) ^ 1;
	bigint::sub(t1, n, ctl);
	bigint::montymul(s, t1, k, n, n0i);

	// Encode r and s in the signature.
	bigint::decode(sig[..nlen], r);
	bigint::decode(sig[nlen..nlen*2], s);
	return (nlen << 1): u32;
};

// Decode some bytes as an i31 integer, with truncation (corresponding
// to the 'bits2int' operation in RFC 6979). The target ENCODED bit
// length is provided as last parameter. The resulting value will have
// this declared bit length, and consists the big-endian unsigned decoding
// of exactly that many bits in the source (capped at the source length).
fn bits2int(x: []bigint::word, src: []u8, ebitlen: bigint::word) void = {
	let sc: i32 = 0;
	let l: size = len(src);

	let bitlen: u32 = ebitlen - (ebitlen >> 5);
	let hbitlen = len(src): u32 << 3;
	if (hbitlen > bitlen) {
		l = (bitlen + 7) >> 3;
		sc = ((hbitlen - bitlen) & 7): i32;
	};

	bigint::zero(x, ebitlen);
	bigint::encode(x, src[..l]);
	bigint::rshift(x, sc: bigint::word);
	x[0] = ebitlen;
};
