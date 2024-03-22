// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Constant time aes implementation optimized for 64bit CPUs.
// The code was ported from BearSSL, which contained the following notice:
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
use crypto::cipher;
use crypto::cipher::{blocksz,nparallel};
use crypto::math;
use endian;

def CT64_EXPKEYSZ: size = 960;
def CT64_NPARALLEL: size = 4;

// Returns an AES [[crypto::cipher::block]] cipher implementation optimized for
// constant time operation on 64-bit systems.
//
// The caller must call [[ct64_init]] to add a key to the cipher before using
// the cipher, and must call [[crypto::cipher::finish]] when they are finished
// using the cipher to securely erase any secret data stored in the cipher
// state.
fn ct64() block = block {
	vtable = &ct64_vtable,
	...
};

const ct64_vtable: cipher::blockvtable = cipher::blockvtable {
	blocksz = BLOCKSZ,
	nparallel = CT64_NPARALLEL,
	encrypt = &aes_ct64_encrypt,
	decrypt = &aes_ct64_decrypt,
	finish = &block_finish,
};

// Initializes the ct64 AES implementation with an encryption key.
fn ct64_init(cipher: *block, key: []u8) void = {
	let comp_skey: [30]u64 = [0...];
	cipher.rounds = br_aes_ct64_keysched(comp_skey[..], key, len(key));
	br_aes_ct64_skey_expand(ct64_expkey(cipher), cipher.rounds, comp_skey[..]);
};

fn ct64_expkey(b: *block) []u64 = {
	return (b.expkey[..]: *[*]u64)[..len(b.expkey)/size(u64)];
};

// Combines up to 4 blocks and encrypts them in one run
fn aes_ct64_encrypt(b: *cipher::block, dest: []u8, src: []u8) void = {
	let b = b: *block;

	assert(len(src) % blocksz(b) == 0
		&& (len(src) / blocksz(b)) <= nparallel(b),
		"invalid block size");

	let nblocks = len(src) / blocksz(b);

	let q: [8]u64 = [0...];
	let w: [16]u32 = [0...];

	br_range_dec32le(w, src);
	for (let i = 0z; i < nblocks; i += 1) {
		br_aes_ct64_interleave_in(q[i..], q[(i + 4)..], w[(i << 2)..]);
	};

	br_aes_ct64_ortho(q);
	br_aes_ct64_bitslice_encrypt(b.rounds, ct64_expkey(b), q);
	br_aes_ct64_ortho(q);

	for (let i = 0z; i < nblocks; i += 1) {
		br_aes_ct64_interleave_out(w[(i << 2)..], q[i], q[i + 4]);
	};

	br_range_enc32le(dest, w);
};

// Combines up to 4 blocks and decrypts them in one run
fn aes_ct64_decrypt(b: *cipher::block, dest: []u8, src: []u8) void = {
	let b = b: *block;

	assert(len(src) % blocksz(b) == 0
		&& (len(src) / blocksz(b)) <= nparallel(b),
		"invalid block size");

	const nblocks = len(src) / blocksz(b);
	let q: [8]u64 = [0...];
	let w: [16]u32 = [0...];

	br_range_dec32le(w, src);
	for (let i = 0z; i < nblocks; i += 1) {
		br_aes_ct64_interleave_in(q[i..], q[(i + 4)..], w[(i << 2)..]);
	};

	br_aes_ct64_ortho(q);
	br_aes_ct64_bitslice_decrypt(b.rounds, ct64_expkey(b), q);
	br_aes_ct64_ortho(q);

	for (let i = 0z; i < nblocks; i += 1) {
		br_aes_ct64_interleave_out(w[(i << 2)..], q[i], q[i + 4]);
	};

	br_range_enc32le(dest, w);
};

// see br_aes_ct64_ortho in src/inner.h of BearSSL
fn br_aes_ct64_ortho(q: []u64) void = {
	swapn(0x5555555555555555, 0xAAAAAAAAAAAAAAAA, 1, &q[0], &q[1]);
	swapn(0x5555555555555555, 0xAAAAAAAAAAAAAAAA, 1, &q[2], &q[3]);
	swapn(0x5555555555555555, 0xAAAAAAAAAAAAAAAA, 1, &q[4], &q[5]);
	swapn(0x5555555555555555, 0xAAAAAAAAAAAAAAAA, 1, &q[6], &q[7]);

	swapn(0x3333333333333333, 0xCCCCCCCCCCCCCCCC, 2, &q[0], &q[2]);
	swapn(0x3333333333333333, 0xCCCCCCCCCCCCCCCC, 2, &q[1], &q[3]);
	swapn(0x3333333333333333, 0xCCCCCCCCCCCCCCCC, 2, &q[4], &q[6]);
	swapn(0x3333333333333333, 0xCCCCCCCCCCCCCCCC, 2, &q[5], &q[7]);

	swapn(0x0F0F0F0F0F0F0F0F, 0xF0F0F0F0F0F0F0F0, 4, &q[0], &q[4]);
	swapn(0x0F0F0F0F0F0F0F0F, 0xF0F0F0F0F0F0F0F0, 4, &q[1], &q[5]);
	swapn(0x0F0F0F0F0F0F0F0F, 0xF0F0F0F0F0F0F0F0, 4, &q[2], &q[6]);
	swapn(0x0F0F0F0F0F0F0F0F, 0xF0F0F0F0F0F0F0F0, 4, &q[3], &q[7]);
};

// This is a macro in the C version.
fn swapn(cl: u64, ch: u64, s: u32, x: *u64, y: *u64) void = {
	let a: u64 = *x, b: u64 = *y;

	*x = (a & cl) | ((b & cl) << s);
	*y = ((a & ch) >> s) | (b & ch);
};


// see br_aes_ct64_interleave_in in src/inner.h of BearSSL
fn br_aes_ct64_interleave_in(q0: []u64, q1: []u64, w: const []u32) void = {
	let x0 = 0u64, x1 = 0u64, x2 = 0u64, x3 = 0u64;

	x0 = w[0];
	x1 = w[1];
	x2 = w[2];
	x3 = w[3];
	x0 |= (x0 << 16);
	x1 |= (x1 << 16);
	x2 |= (x2 << 16);
	x3 |= (x3 << 16);
	x0 &= 0x0000FFFF0000FFFF;
	x1 &= 0x0000FFFF0000FFFF;
	x2 &= 0x0000FFFF0000FFFF;
	x3 &= 0x0000FFFF0000FFFF;
	x0 |= (x0 << 8);
	x1 |= (x1 << 8);
	x2 |= (x2 << 8);
	x3 |= (x3 << 8);
	x0 &= 0x00FF00FF00FF00FF;
	x1 &= 0x00FF00FF00FF00FF;
	x2 &= 0x00FF00FF00FF00FF;
	x3 &= 0x00FF00FF00FF00FF;
	q0[0] = x0 | (x2 << 8);
	q1[0] = x1 | (x3 << 8);
};

// see br_aes_ct64_interleave_out in src/inner.h of BearSSL
fn br_aes_ct64_interleave_out(w: []u32, q0: u64, q1: u64) void = {
	let x0 = 0u64, x1 = 0u64, x2 = 0u64, x3 = 0u64;

	x0 = q0 & 0x00FF00FF00FF00FF;
	x1 = q1 & 0x00FF00FF00FF00FF;
	x2 = (q0 >> 8) & 0x00FF00FF00FF00FF;
	x3 = (q1 >> 8) & 0x00FF00FF00FF00FF;
	x0 |= (x0 >> 8);
	x1 |= (x1 >> 8);
	x2 |= (x2 >> 8);
	x3 |= (x3 >> 8);
	x0 &= 0x0000FFFF0000FFFF;
	x1 &= 0x0000FFFF0000FFFF;
	x2 &= 0x0000FFFF0000FFFF;
	x3 &= 0x0000FFFF0000FFFF;
	w[0] = (x0 | (x0 >> 16)): u32;
	w[1] = (x1 | (x1 >> 16)): u32;
	w[2] = (x2 | (x2 >> 16)): u32;
	w[3] = (x3 | (x3 >> 16)): u32;
};

// see br_aes_ct64_bitslice_Sbox in src/inner.h of BearSSL
fn br_aes_ct64_bitslice_Sbox(q: []u64) void = {
	// This S-box implementation is a straightforward translation of
	// the circuit described by Boyar and Peralta in "A new
	// combinational logic minimization technique with applications
	// to cryptology" (https://eprint.iacr.org/2009/191.pdf).
	//
	// Note that variables x* (input) and s* (output) are numbered
	// in "reverse" order (x0 is the high bit, x7 is the low bit).

	let x0 = 0u64, x1 = 0u64, x2 = 0u64, x3 = 0u64, x4 = 0u64, x5 = 0u64,
		x6 = 0u64, x7 = 0u64;

	let y1 = 0u64, y2 = 0u64, y3 = 0u64, y4 = 0u64, y5 = 0u64, y6 = 0u64,
		y7 = 0u64, y8 = 0u64, y9 = 0u64, y10 = 0u64, y11 = 0u64,
		y12 = 0u64, y13 = 0u64, y14 = 0u64, y15 = 0u64, y16 = 0u64,
		y17 = 0u64, y18 = 0u64, y19 = 0u64, y20 = 0u64, y21 = 0u64;

	let z0 = 0u64, z1 = 0u64, z2 = 0u64, z3 = 0u64, z4 = 0u64, z5 = 0u64,
		z6 = 0u64, z7 = 0u64, z8 = 0u64, z9 = 0u64, z10 = 0u64,
		z11 = 0u64, z12 = 0u64, z13 = 0u64, z14 = 0u64, z15 = 0u64,
		z16 = 0u64, z17 = 0u64;

	let t0 = 0u64, t1 = 0u64, t2 = 0u64, t3 = 0u64, t4 = 0u64,
		t5 = 0u64, t6 = 0u64, t7 = 0u64, t8 = 0u64, t9 = 0u64,
		t10 = 0u64, t11 = 0u64, t12 = 0u64, t13 = 0u64, t14 = 0u64,
		t15 = 0u64, t16 = 0u64, t17 = 0u64, t18 = 0u64, t19 = 0u64,
		t20 = 0u64, t21 = 0u64, t22 = 0u64, t23 = 0u64, t24 = 0u64,
		t25 = 0u64, t26 = 0u64, t27 = 0u64, t28 = 0u64, t29 = 0u64,
		t30 = 0u64, t31 = 0u64, t32 = 0u64, t33 = 0u64, t34 = 0u64,
		t35 = 0u64, t36 = 0u64, t37 = 0u64, t38 = 0u64, t39 = 0u64,
		t40 = 0u64, t41 = 0u64, t42 = 0u64, t43 = 0u64, t44 = 0u64,
		t45 = 0u64, t46 = 0u64, t47 = 0u64, t48 = 0u64, t49 = 0u64,
		t50 = 0u64, t51 = 0u64, t52 = 0u64, t53 = 0u64, t54 = 0u64,
		t55 = 0u64, t56 = 0u64, t57 = 0u64, t58 = 0u64, t59 = 0u64,
		t60 = 0u64, t61 = 0u64, t62 = 0u64, t63 = 0u64, t64 = 0u64,
		t65 = 0u64, t66 = 0u64, t67 = 0u64;

	let s0 = 0u64, s1 = 0u64, s2 = 0u64, s3 = 0u64, s4 = 0u64, s5 = 0u64,
		s6 = 0u64, s7 = 0u64;

	x0 = q[7];
	x1 = q[6];
	x2 = q[5];
	x3 = q[4];
	x4 = q[3];
	x5 = q[2];
	x6 = q[1];
	x7 = q[0];

	// Top linear transformation.
	y14 = x3 ^ x5;
	y13 = x0 ^ x6;
	y9 = x0 ^ x3;
	y8 = x0 ^ x5;
	t0 = x1 ^ x2;
	y1 = t0 ^ x7;
	y4 = y1 ^ x3;
	y12 = y13 ^ y14;
	y2 = y1 ^ x0;
	y5 = y1 ^ x6;
	y3 = y5 ^ y8;
	t1 = x4 ^ y12;
	y15 = t1 ^ x5;
	y20 = t1 ^ x1;
	y6 = y15 ^ x7;
	y10 = y15 ^ t0;
	y11 = y20 ^ y9;
	y7 = x7 ^ y11;
	y17 = y10 ^ y11;
	y19 = y10 ^ y8;
	y16 = t0 ^ y11;
	y21 = y13 ^ y16;
	y18 = x0 ^ y16;

	// Non-linear section.
	t2 = y12 & y15;
	t3 = y3 & y6;
	t4 = t3 ^ t2;
	t5 = y4 & x7;
	t6 = t5 ^ t2;
	t7 = y13 & y16;
	t8 = y5 & y1;
	t9 = t8 ^ t7;
	t10 = y2 & y7;
	t11 = t10 ^ t7;
	t12 = y9 & y11;
	t13 = y14 & y17;
	t14 = t13 ^ t12;
	t15 = y8 & y10;
	t16 = t15 ^ t12;
	t17 = t4 ^ t14;
	t18 = t6 ^ t16;
	t19 = t9 ^ t14;
	t20 = t11 ^ t16;
	t21 = t17 ^ y20;
	t22 = t18 ^ y19;
	t23 = t19 ^ y21;
	t24 = t20 ^ y18;

	t25 = t21 ^ t22;
	t26 = t21 & t23;
	t27 = t24 ^ t26;
	t28 = t25 & t27;
	t29 = t28 ^ t22;
	t30 = t23 ^ t24;
	t31 = t22 ^ t26;
	t32 = t31 & t30;
	t33 = t32 ^ t24;
	t34 = t23 ^ t33;
	t35 = t27 ^ t33;
	t36 = t24 & t35;
	t37 = t36 ^ t34;
	t38 = t27 ^ t36;
	t39 = t29 & t38;
	t40 = t25 ^ t39;

	t41 = t40 ^ t37;
	t42 = t29 ^ t33;
	t43 = t29 ^ t40;
	t44 = t33 ^ t37;
	t45 = t42 ^ t41;
	z0 = t44 & y15;
	z1 = t37 & y6;
	z2 = t33 & x7;
	z3 = t43 & y16;
	z4 = t40 & y1;
	z5 = t29 & y7;
	z6 = t42 & y11;
	z7 = t45 & y17;
	z8 = t41 & y10;
	z9 = t44 & y12;
	z10 = t37 & y3;
	z11 = t33 & y4;
	z12 = t43 & y13;
	z13 = t40 & y5;
	z14 = t29 & y2;
	z15 = t42 & y9;
	z16 = t45 & y14;
	z17 = t41 & y8;

	// Bottom linear transformation.
	t46 = z15 ^ z16;
	t47 = z10 ^ z11;
	t48 = z5 ^ z13;
	t49 = z9 ^ z10;
	t50 = z2 ^ z12;
	t51 = z2 ^ z5;
	t52 = z7 ^ z8;
	t53 = z0 ^ z3;
	t54 = z6 ^ z7;
	t55 = z16 ^ z17;
	t56 = z12 ^ t48;
	t57 = t50 ^ t53;
	t58 = z4 ^ t46;
	t59 = z3 ^ t54;
	t60 = t46 ^ t57;
	t61 = z14 ^ t57;
	t62 = t52 ^ t58;
	t63 = t49 ^ t58;
	t64 = z4 ^ t59;
	t65 = t61 ^ t62;
	t66 = z1 ^ t63;
	s0 = t59 ^ t63;
	s6 = t56 ^ ~t62;
	s7 = t48 ^ ~t60;
	t67 = t64 ^ t65;
	s3 = t53 ^ t66;
	s4 = t51 ^ t66;
	s5 = t47 ^ t65;
	s1 = t64 ^ ~s3;
	s2 = t55 ^ ~t67;

	q[7] = s0;
	q[6] = s1;
	q[5] = s2;
	q[4] = s3;
	q[3] = s4;
	q[2] = s5;
	q[1] = s6;
	q[0] = s7;
};

const rcon: []u8 = [
	0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36
];

fn sub_word(x: u32) u32 = {
	let q: [8]u64 = [x, 0...];
	br_aes_ct64_ortho(q);
	br_aes_ct64_bitslice_Sbox(q);
	br_aes_ct64_ortho(q);
	return q[0]: u32;
};

// see br_aes_ct64_keysched in src/inner.h of BearSSL
fn br_aes_ct64_keysched(
	comp_skey: []u64,
	key: const []u8,
	key_len: size,
) uint = {
	let num_rounds: uint = 0;
	let nk: int = 0, nkf: int = 0;
	let tmp: u32 = 0;
	let skey: [60]u32 = [0...];

	switch (key_len) {
	case 16 =>
		num_rounds = 10;
	case 24 =>
		num_rounds = 12;
	case 32 =>
		num_rounds = 14;
	case =>
		assert(false, "invalid key length");
	};

	nk = (key_len >> 2): int;
	nkf = ((num_rounds + 1) << 2): int;
	br_range_dec32le(skey, key);
	tmp = skey[(key_len >> 2) - 1];
	for (let i = nk, j = 0, k = 0; i < nkf; i += 1) {
		if (j == 0) {
			tmp = (tmp << 24) | (tmp >> 8);
			tmp = sub_word(tmp) ^ rcon[k];
		} else if (nk > 6 && j == 4) {
			tmp = sub_word(tmp);
		};
		tmp ^= skey[i - nk];
		skey[i] = tmp;
		j += 1;
		if (j == nk) {
			j = 0;
			k += 1;
		};
	};

	for (let i = 0, j = 0; i < nkf) {
		let q: [8]u64 = [0...];

		br_aes_ct64_interleave_in(q[0..], q[4..], skey[i..]);
		q[1] = q[0];
		q[2] = q[0];
		q[3] = q[0];
		q[5] = q[4];
		q[6] = q[4];
		q[7] = q[4];
		br_aes_ct64_ortho(q[..]);
		comp_skey[j + 0] = (q[0] & 0x1111111111111111)
			| (q[1] & 0x2222222222222222)
			| (q[2] & 0x4444444444444444)
			| (q[3] & 0x8888888888888888);
		comp_skey[j + 1] = (q[4] & 0x1111111111111111)
			| (q[5] & 0x2222222222222222)
			| (q[6] & 0x4444444444444444)
			| (q[7] & 0x8888888888888888);

		i += 4;
		j += 2;
	};
	return num_rounds;
};

fn br_range_dec32le(v: []u32, src: []u8) void = {
	for (let i = 0z; len(src) > 0; i += 1) {
		v[i] = endian::legetu32(src);
		src = src[4..];
	};
};

fn br_range_enc32le(dest: []u8, w: []u32) void = {
	for (let i = 0z; len(dest) > 0; i += 1) {
		endian::leputu32(dest, w[i]);
		dest = dest[4..];
	};
};

// see br_aes_ct64_skey_expand in src/inner.h of BearSSL
fn br_aes_ct64_skey_expand(
	skey: []u64,
	num_rounds: uint,
	comp_skey: const []u64,
) void = {
	let n: uint = (num_rounds + 1) << 1;
	for (let u = 0u, v = 0u; u < n) {
		let x0 = 0u64, x1 = 0u64, x2 = 0u64, x3 = 0u64;

		x0 = comp_skey[u];
		x1 = comp_skey[u];
		x2 = comp_skey[u];
		x3 = comp_skey[u];
		x0 &= 0x1111111111111111;
		x1 &= 0x2222222222222222;
		x2 &= 0x4444444444444444;
		x3 &= 0x8888888888888888;
		x1 >>= 1;
		x2 >>= 2;
		x3 >>= 3;
		skey[v + 0] = (x0 << 4) - x0;
		skey[v + 1] = (x1 << 4) - x1;
		skey[v + 2] = (x2 << 4) - x2;
		skey[v + 3] = (x3 << 4) - x3;

		u += 1;
		v += 4;
	};
};

// aes_ct64_enc.c

fn add_round_key(q: []u64, sk: const []u64) void = {
	q[0] ^= sk[0];
	q[1] ^= sk[1];
	q[2] ^= sk[2];
	q[3] ^= sk[3];
	q[4] ^= sk[4];
	q[5] ^= sk[5];
	q[6] ^= sk[6];
	q[7] ^= sk[7];
};

fn shift_rows(q: []u64) void = {
	for (let i: int = 0; i < 8; i += 1) {
		let x: u64 = q[i];
		q[i] = (x & 0x000000000000FFFF)
			| ((x & 0x00000000FFF00000) >> 4)
			| ((x & 0x00000000000F0000) << 12)
			| ((x & 0x0000FF0000000000) >> 8)
			| ((x & 0x000000FF00000000) << 8)
			| ((x & 0xF000000000000000) >> 12)
			| ((x & 0x0FFF000000000000) << 4);
	};
};

fn mix_columns(q: []u64) void = {
	let q0 = 0u64, q1 = 0u64, q2 = 0u64, q3 = 0u64, q4 = 0u64, q5 = 0u64,
		q6 = 0u64, q7 = 0u64;
	let r0 = 0u64, r1 = 0u64, r2 = 0u64, r3 = 0u64, r4 = 0u64, r5 = 0u64,
		r6 = 0u64, r7 = 0u64;

	q0 = q[0];
	q1 = q[1];
	q2 = q[2];
	q3 = q[3];
	q4 = q[4];
	q5 = q[5];
	q6 = q[6];
	q7 = q[7];
	r0 = (q0 >> 16) | (q0 << 48);
	r1 = (q1 >> 16) | (q1 << 48);
	r2 = (q2 >> 16) | (q2 << 48);
	r3 = (q3 >> 16) | (q3 << 48);
	r4 = (q4 >> 16) | (q4 << 48);
	r5 = (q5 >> 16) | (q5 << 48);
	r6 = (q6 >> 16) | (q6 << 48);
	r7 = (q7 >> 16) | (q7 << 48);

	q[0] = q7 ^ r7 ^ r0 ^ math::rotr64(q0 ^ r0, 32);
	q[1] = q0 ^ r0 ^ q7 ^ r7 ^ r1 ^ math::rotr64(q1 ^ r1, 32);
	q[2] = q1 ^ r1 ^ r2 ^ math::rotr64(q2 ^ r2, 32);
	q[3] = q2 ^ r2 ^ q7 ^ r7 ^ r3 ^ math::rotr64(q3 ^ r3, 32);
	q[4] = q3 ^ r3 ^ q7 ^ r7 ^ r4 ^ math::rotr64(q4 ^ r4, 32);
	q[5] = q4 ^ r4 ^ r5 ^ math::rotr64(q5 ^ r5, 32);
	q[6] = q5 ^ r5 ^ r6 ^ math::rotr64(q6 ^ r6, 32);
	q[7] = q6 ^ r6 ^ r7 ^ math::rotr64(q7 ^ r7, 32);
};

// see br_aes_ct64_bitslice_encrypt in src/inner.h of BearSSL
fn br_aes_ct64_bitslice_encrypt(
	num_rounds: uint,
	skey: const []u64,
	q: []u64,
) void = {
	add_round_key(q, skey);
	for (let u: uint = 1; u < num_rounds; u += 1) {
		br_aes_ct64_bitslice_Sbox(q);
		shift_rows(q);
		mix_columns(q);
		add_round_key(q, skey[(u << 3)..]);
	};
	br_aes_ct64_bitslice_Sbox(q);
	shift_rows(q);
	add_round_key(q, skey[(num_rounds << 3)..]);
};

// see br_aes_ct64_bitslice_invSbox in src/inner.h of BearSSL
fn br_aes_ct64_bitslice_invSbox(q: []u64) void = {
	// See br_aes_ct_bitslice_invSbox(). This is the natural extension
	// to 64-bit registers.
	let q0 = 0u64, q1 = 0u64, q2 = 0u64, q3 = 0u64, q4 = 0u64, q5 = 0u64,
		q6 = 0u64, q7 = 0u64;

	q0 = ~q[0];
	q1 = ~q[1];
	q2 = q[2];
	q3 = q[3];
	q4 = q[4];
	q5 = ~q[5];
	q6 = ~q[6];
	q7 = q[7];
	q[7] = q1 ^ q4 ^ q6;
	q[6] = q0 ^ q3 ^ q5;
	q[5] = q7 ^ q2 ^ q4;
	q[4] = q6 ^ q1 ^ q3;
	q[3] = q5 ^ q0 ^ q2;
	q[2] = q4 ^ q7 ^ q1;
	q[1] = q3 ^ q6 ^ q0;
	q[0] = q2 ^ q5 ^ q7;

	br_aes_ct64_bitslice_Sbox(q);

	q0 = ~q[0];
	q1 = ~q[1];
	q2 = q[2];
	q3 = q[3];
	q4 = q[4];
	q5 = ~q[5];
	q6 = ~q[6];
	q7 = q[7];
	q[7] = q1 ^ q4 ^ q6;
	q[6] = q0 ^ q3 ^ q5;
	q[5] = q7 ^ q2 ^ q4;
	q[4] = q6 ^ q1 ^ q3;
	q[3] = q5 ^ q0 ^ q2;
	q[2] = q4 ^ q7 ^ q1;
	q[1] = q3 ^ q6 ^ q0;
	q[0] = q2 ^ q5 ^ q7;
};

fn inv_shift_rows(q: []u64) void = {
	for (let i: int = 0; i < 8; i += 1) {
		let x: u64 = q[i];
		q[i] = (x & 0x000000000000FFFF)
			| ((x & 0x000000000FFF0000) << 4)
			| ((x & 0x00000000F0000000) >> 12)
			| ((x & 0x000000FF00000000) << 8)
			| ((x & 0x0000FF0000000000) >> 8)
			| ((x & 0x000F000000000000) << 12)
			| ((x & 0xFFF0000000000000) >> 4);
	};
};

fn inv_mix_columns(q: []u64) void = {
	let q0 = 0u64, q1 = 0u64, q2 = 0u64, q3 = 0u64, q4 = 0u64, q5 = 0u64,
		q6 = 0u64, q7 = 0u64;
	let r0 = 0u64, r1 = 0u64, r2 = 0u64, r3 = 0u64, r4 = 0u64, r5 = 0u64,
		r6 = 0u64, r7 = 0u64;

	q0 = q[0];
	q1 = q[1];
	q2 = q[2];
	q3 = q[3];
	q4 = q[4];
	q5 = q[5];
	q6 = q[6];
	q7 = q[7];
	r0 = (q0 >> 16) | (q0 << 48);
	r1 = (q1 >> 16) | (q1 << 48);
	r2 = (q2 >> 16) | (q2 << 48);
	r3 = (q3 >> 16) | (q3 << 48);
	r4 = (q4 >> 16) | (q4 << 48);
	r5 = (q5 >> 16) | (q5 << 48);
	r6 = (q6 >> 16) | (q6 << 48);
	r7 = (q7 >> 16) | (q7 << 48);

	q[0] = q5 ^ q6 ^ q7 ^ r0 ^ r5 ^ r7
		^ math::rotr64(q0 ^ q5 ^ q6 ^ r0 ^ r5, 32);
	q[1] = q0 ^ q5 ^ r0 ^ r1 ^ r5 ^ r6 ^ r7
		^ math::rotr64(q1 ^ q5 ^ q7 ^ r1 ^ r5 ^ r6, 32);
	q[2] = q0 ^ q1 ^ q6 ^ r1 ^ r2 ^ r6 ^ r7
		^ math::rotr64(q0 ^ q2 ^ q6 ^ r2 ^ r6 ^ r7, 32);
	q[3] = q0 ^ q1 ^ q2 ^ q5 ^ q6 ^ r0 ^ r2 ^ r3 ^ r5
		^ math::rotr64(q0 ^ q1 ^ q3 ^ q5 ^ q6 ^ q7 ^ r0 ^ r3 ^ r5 ^ r7
			, 32);
	q[4] = q1 ^ q2 ^ q3 ^ q5 ^ r1 ^ r3 ^ r4 ^ r5 ^ r6 ^ r7
		^ math::rotr64(q1 ^ q2 ^ q4 ^ q5 ^ q7 ^ r1 ^ r4 ^ r5 ^ r6, 32);
	q[5] = q2 ^ q3 ^ q4 ^ q6 ^ r2 ^ r4 ^ r5 ^ r6 ^ r7
		^ math::rotr64(q2 ^ q3 ^ q5 ^ q6 ^ r2 ^ r5 ^ r6 ^ r7, 32);
	q[6] = q3 ^ q4 ^ q5 ^ q7 ^ r3 ^ r5 ^ r6 ^ r7
		^ math::rotr64(q3 ^ q4 ^ q6 ^ q7 ^ r3 ^ r6 ^ r7, 32);
	q[7] = q4 ^ q5 ^ q6 ^ r4 ^ r6 ^ r7
		^ math::rotr64(q4 ^ q5 ^ q7 ^ r4 ^ r7, 32);
};

// see br_aes_ct64_bitslice_decrypt in src/inner.h of BearSSL
fn br_aes_ct64_bitslice_decrypt(
	num_rounds: size,
	skey: const []u64,
	q: []u64,
) void = {
	add_round_key(q, skey[(num_rounds << 3)..]);
	for (let u: size = num_rounds - 1; u > 0; u -= 1) {
		inv_shift_rows(q);
		br_aes_ct64_bitslice_invSbox(q);
		add_round_key(q, skey[(u << 3)..]);
		inv_mix_columns(q);
	};
	inv_shift_rows(q);
	br_aes_ct64_bitslice_invSbox(q);
	add_round_key(q, skey);
};
