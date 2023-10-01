// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::cipher;
use crypto::math::{rotl32, xor};
use endian;
use io;

// Size of a Salsa key, in bytes.
export def KEYSZ: size = 32;

// Size of the XSalsa20 nonce, in bytes.
export def XNONCESZ: size = 24;

// Size of the Salsa20 nonce, in bytes.
export def NONCESZ: size = 8;

def ROUNDS: size = 20;

// The block size of the Salsa cipher.
export def BLOCKSZ: size = 64;

const magic: [4]u32 = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

export type stream = struct {
	cipher::xorstream,
	state: [16]u32,
	xorbuf: [BLOCKSZ]u8,
	xorused: size,
	rounds: size,
};

// Create a Salsa20 or XSalsa20 stream. Must be initialized with either
// [[salsa20_init]] or [[xsalsa20_init]], and must be closed with [[io::close]]
// after use to wipe sensitive data from memory.
export fn salsa20() stream = {
	return stream {
		stream = &cipher::xorstream_vtable,
		h = 0,
		keybuf = &keybuf,
		advance = &advance,
		finish = &finish,
		xorused = BLOCKSZ,
		rounds = ROUNDS,
		...
	};
};

fn init(
	state: *[16]u32,
	key: []u8,
	nonce: []u8,
	ctr: []u8
) void = {
	state[0] = magic[0];
	state[1] = endian::legetu32(key[0..4]);
	state[2] = endian::legetu32(key[4..8]);
	state[3] = endian::legetu32(key[8..12]);
	state[4] = endian::legetu32(key[12..16]);
	state[5] = magic[1];
	state[6] = endian::legetu32(nonce[0..4]);
	state[7] = endian::legetu32(nonce[4..8]);
	state[8] = endian::legetu32(ctr[0..4]);
	state[9] = endian::legetu32(ctr[4..8]);
	state[10] = magic[2];
	state[11] = endian::legetu32(key[16..20]);
	state[12] = endian::legetu32(key[20..24]);
	state[13] = endian::legetu32(key[24..28]);
	state[14] = endian::legetu32(key[28..32]);
	state[15] = magic[3];
};

// Initialize a Salsa20 stream.
export fn salsa20_init(
	s: *stream,
	h: io::handle,
	key: []u8,
	nonce: []u8,
) void = {
	assert(len(key) == KEYSZ);
	assert(len(nonce) == NONCESZ);

	let counter: [8]u8 = [0...];
	init(&s.state, key, nonce, &counter);
	s.h = h;
};

// Initialize an XSalsa20 stream. XSalsa20 differs from Salsa20 via the use of a
// larger nonce parameter.
export fn xsalsa20_init(
	s: *stream,
	h: io::handle,
	key: []u8,
	nonce: []u8
) void = {
	assert(len(key) == KEYSZ);
	assert(len(nonce) == XNONCESZ);

	let dkey: [32]u8 = [0...];
	defer bytes::zero(dkey);
	hsalsa20(&dkey, key, nonce[..16]);
	salsa20_init(s, h, &dkey, nonce[16..]: *[NONCESZ]u8);
};

// Derives a new key from 'key' and 'nonce' as used during XSalsa20
// initialization. This function may only be used for specific purposes
// such as X25519 key derivation. Do not use if in doubt.
export fn hsalsa20(out: []u8, key: []u8, nonce: []u8) void = {
	assert(len(out) == KEYSZ);
	assert(len(key) == KEYSZ);
	assert(len(nonce) == 16);

	let state: [16]u32 = [0...];
	defer bytes::zero((state: []u8: *[*]u8)[..BLOCKSZ]);

	init(&state, key, nonce[0..8]: *[8]u8, nonce[8..16]: *[8]u8);
	hblock(state[..], &state, 20);

	endian::leputu32(out[0..4], state[0]);
	endian::leputu32(out[4..8], state[5]);
	endian::leputu32(out[8..12], state[10]);
	endian::leputu32(out[12..16], state[15]);
	endian::leputu32(out[16..20], state[6]);
	endian::leputu32(out[20..24], state[7]);
	endian::leputu32(out[24..28], state[8]);
	endian::leputu32(out[28..32], state[9]);
};

// Advances the key stream to "seek" to a future state by 'counter' times
// [[BLOCKSZ]].
export fn setctr(s: *stream, counter: u64) void = {
	s.state[8] = (counter & 0xFFFFFFFF): u32;
	s.state[9] = (counter >> 32): u32;
	s.xorused = BLOCKSZ;
};

fn keybuf(s: *cipher::xorstream) []u8 = {
	let s = s: *stream;
	if (s.xorused >= BLOCKSZ) {
		block((s.xorbuf[..]: *[*]u32)[..16], &s.state, s.rounds);
		s.state[8] += 1;
		if (s.state[8] == 0) {
			s.state[9] += 1;
		};
		s.xorused = 0;
	};

	return s.xorbuf[s.xorused..];
};

fn advance(s: *cipher::xorstream, n: size) void = {
	let s = s: *stream;
	assert(n <= len(s.xorbuf));
	s.xorused += n;
};

fn block(dest: []u32, state: *[16]u32, rounds: size) void = {
	hblock(dest, state, rounds);

	for (let i = 0z; i < 16; i += 1) {
		dest[i] += state[i];
	};
};

fn hblock(dest: []u32, state: *[16]u32, rounds: size) void = {
	for (let i = 0z; i < 16; i += 1) {
		dest[i] = state[i];
	};

	for (let i = 0z; i < rounds; i += 2) {
		qr(&dest[0], &dest[4], &dest[8], &dest[12]);
		qr(&dest[5], &dest[9], &dest[13], &dest[1]);
		qr(&dest[10], &dest[14], &dest[2], &dest[6]);
		qr(&dest[15], &dest[3], &dest[7], &dest[11]);

		qr(&dest[0], &dest[1], &dest[2], &dest[3]);
		qr(&dest[5], &dest[6], &dest[7], &dest[4]);
		qr(&dest[10], &dest[11], &dest[8], &dest[9]);
		qr(&dest[15], &dest[12], &dest[13], &dest[14]);
	};
};

fn qr(a: *u32, b: *u32, c: *u32, d: *u32) void = {
	*b ^= rotl32(*a + *d, 7);
	*c ^= rotl32(*b + *a, 9);
	*d ^= rotl32(*c + *b, 13);
	*a ^= rotl32(*d + *c, 18);
};

fn finish(s: *cipher::xorstream) void = {
	let s = s: *stream;
	bytes::zero((s.state[..]: *[*]u8)[..len(s.state) * size(u32)]);
	bytes::zero(s.xorbuf);
};
