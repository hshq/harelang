// SPDX-License-Identifier: MIT
// (c) Hare authors <https://harelang.org>
// (c) 2010 The Go Authors. All rights reserved.

use bytes;
use crypto::cipher;
use endian;

// The block size of the Blowfish cipher in bytes.
export def BLOCKSZ: size = 8;

export type state = struct {
	block: cipher::block,
	p: [18]u32,
	s0: [256]u32,
	s1: [256]u32,
	s2: [256]u32,
	s3: [256]u32,
};

const vtable: cipher::blockvtable = cipher::blockvtable {
	blocksz = BLOCKSZ,
	nparallel = 1,
	encrypt = &block_encrypt,
	decrypt = &block_decrypt,
	finish = &block_finish,
};

// Initializes a new Blowfish cipher. The user should must call [[init]] or
// [[init_salt]] prior to use, then may use [[crypto::cipher::encrypt]] et al.
// The user must call [[finish]] when they are done using the stream to securely
// erase secret information stored in the stream state.
export fn new() state = {
	return state {
		block = &vtable,
		p = p,
		s0 = s0,
		s1 = s1,
		s2 = s2,
		s3 = s3,
	};
};

// Performs key expansion for a Blowfish cipher.
export fn init(c: *state, key: []u8) void = {
	let j = 0z;
	for (let i = 0z; i < len(c.p); i += 1) {
		c.p[i] ^= getword(key, &j);
	};

	let l = 0u32, r = 0u32;
	init_vector(c, &l, &r, c.p);
	init_vector(c, &l, &r, c.s0);
	init_vector(c, &l, &r, c.s1);
	init_vector(c, &l, &r, c.s2);
	init_vector(c, &l, &r, c.s3);
};

fn init_vector(c: *state, l: *u32, r: *u32, vec: []u32) void = {
	for (let i = 0z; i < len(vec); i += 2) {
		const (v0, v1) = encrypt(c, *l, *r);
		*l = v0;
		*r = v1;
		vec[i] = *l;
		vec[i+1] = *r;
	};
};

// Performs salted key expansion for a Blowfish cipher.
export fn init_salt(c: *state, key: []u8, salt: []u8) void = {
	if (len(salt) == 0) {
		init(c, key);
		return;
	};

	assert(len(key) >= 1, "Invalid blowfish key size");
	let j = 0z;
	for (let i = 0z; i < 18; i += 1) {
		c.p[i] ^= getword(key, &j);
	};

	j = 0;
	let l = 0u32, r = 0u32;
	init_vector_salt(c, &l, &r, c.p, salt, &j);
	init_vector_salt(c, &l, &r, c.s0, salt, &j);
	init_vector_salt(c, &l, &r, c.s1, salt, &j);
	init_vector_salt(c, &l, &r, c.s2, salt, &j);
	init_vector_salt(c, &l, &r, c.s3, salt, &j);
};

fn init_vector_salt(
	c: *state,
	l: *u32,
	r: *u32,
	vec: []u32,
	salt: []u8,
	j: *size,
) void = {
	for (let i = 0z; i < len(vec); i += 2) {
		*l ^= getword(salt, j);
		*r ^= getword(salt, j);
		const (v0, v1) = encrypt(c, *l, *r);
		*l = v0;
		*r = v1;
		vec[i] = *l;
		vec[i+1] = *r;
	};
};

fn block_encrypt(c: *cipher::block, dest: []u8, src: []u8) void = {
	const c = c: *state;
	assert(c.block.encrypt == &block_encrypt);

	let l = src[0]<<24u32 | src[1]<<16u32 | src[2]<<8u32 | src[3]: u32;
	let r = src[4]<<24u32 | src[5]<<16u32 | src[6]<<8u32 | src[7]: u32;
	const (l, r) = encrypt(c, l, r);
	dest[0] = (l>>24): u8;
	dest[1] = (l>>16): u8;
	dest[2] = (l>>8): u8;
	dest[3] = l: u8;
	dest[4] = (r>>24): u8;
	dest[5] = (r>>16): u8;
	dest[6] = (r>>8): u8;
	dest[7] = r: u8;
};

fn block_decrypt(c: *cipher::block, dest: []u8, src: []u8) void = {
	const c = c: *state;
	assert(c.block.decrypt == &block_decrypt);

	let l = src[0]<<24u32 | src[1]<<16u32 | src[2]<<8u32 | src[3]: u32;
	let r = src[4]<<24u32 | src[5]<<16u32 | src[6]<<8u32 | src[7]: u32;
	const v = decrypt(c, l, r);
	l = v.0;
	r = v.1;
	dest[0] = (l>>24): u8;
	dest[1] = (l>>16): u8;
	dest[2] = (l>>8): u8;
	dest[3] = l: u8;
	dest[4] = (r>>24): u8;
	dest[5] = (r>>16): u8;
	dest[6] = (r>>8): u8;
	dest[7] = r: u8;
};

fn block_finish(cipher: *cipher::block) void = {
	const cipher = cipher: *state;
	assert(cipher.block.finish == &block_finish);
	bytes::zero((&cipher.p: *[*]u8)[..len(cipher.p) * size(u32)]);
	bytes::zero((&cipher.s0: *[*]u8)[..len(cipher.s0) * size(u32)]);
	bytes::zero((&cipher.s1: *[*]u8)[..len(cipher.s1) * size(u32)]);
	bytes::zero((&cipher.s2: *[*]u8)[..len(cipher.s2) * size(u32)]);
	bytes::zero((&cipher.s3: *[*]u8)[..len(cipher.s3) * size(u32)]);
};

fn encrypt(c: *state, l: u32, r: u32) (u32, u32) = {
	let xl = l, xr = r;
	xl ^= c.p[0];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[1];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[2];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[3];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[4];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[5];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[6];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[7];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[8];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[9];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[10];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[11];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[12];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[13];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[14];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[15];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[16];
	xr ^= c.p[17];
	return (xr, xl);
};

fn decrypt(c: *state, l: u32, r: u32) (u32, u32) = {
	let xl = l, xr = r;
	xl ^= c.p[17];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[16];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[15];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[14];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[13];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[12];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[11];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[10];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[9];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[8];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[7];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[6];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[5];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[4];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[3];
	xr ^= ((c.s0[(xl>>24): u8] + c.s1[(xl>>16): u8]) ^ c.s2[(xl>>8): u8]) + c.s3[(xl): u8] ^ c.p[2];
	xl ^= ((c.s0[(xr>>24): u8] + c.s1[(xr>>16): u8]) ^ c.s2[(xr>>8): u8]) + c.s3[(xr): u8] ^ c.p[1];
	xr ^= c.p[0];
	return (xr, xl);
};

// Gets the next word from b and updates the index, looping around in a circular
// buffer.
fn getword(b: []u8, i: *size) u32 = {
	let j = *i;
	let w = 0u32;
	for (let i = 0; i < 4; i += 1) {
		w = w<<8 | b[j]: u32;
		j += 1;
		if (j >= len(b)) {
			j = 0;
		};
	};
	*i = j;
	return w;
};
