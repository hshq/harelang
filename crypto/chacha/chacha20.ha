// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::cipher;
use crypto::math::{rotl32, xor};
use endian;
use io;

// Size of a Chacha key, in bytes.
export def KEYSZ: size = 32;

// Size of the XChacha20 nonce, in bytes.
export def XNONCESZ: size = 24;

// Size of the Chacha20 nonce, in bytes.
export def NONCESZ: size = 12;

// The block size of the Chacha cipher in bytes.
export def BLOCKSZ: size = 64;

def ROUNDS: size = 20;
const magic: [4]u32 = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

// A ChaCha20 or XChaCha20 [[crypto::cipher::xorstream]] depending on
// intialisation.
export type stream = struct {
	cipher::xorstream,
	state: [16]u32,
	xorbuf: [BLOCKSZ]u8,
	xorused: size,
	rounds: size,
};

// Creates a ChaCha20 or XChaCha20 stream cipher. Must be initialized with
// [[chacha20_init]] or [[xchacha20_init]] prior to use, and must be closed
// with [[io::close]] after use to wipe sensitive data from memory.
export fn chacha20() stream = {
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

// Initialize a Chacha20 stream.
export fn chacha20_init(
	s: *stream,
	h: io::handle,
	key: []u8,
	nonce: []u8
) void = {
	assert(len(key) == KEYSZ);
	assert(len(nonce) == NONCESZ);

	s.h = h;

	s.state[0] = magic[0];
	s.state[1] = magic[1];
	s.state[2] = magic[2];
	s.state[3] = magic[3];
	s.state[4] = endian::legetu32(key[0..4]);
	s.state[5] = endian::legetu32(key[4..8]);
	s.state[6] = endian::legetu32(key[8..12]);
	s.state[7] = endian::legetu32(key[12..16]);
	s.state[8] = endian::legetu32(key[16..20]);
	s.state[9] = endian::legetu32(key[20..24]);
	s.state[10] = endian::legetu32(key[24..28]);
	s.state[11] = endian::legetu32(key[28..32]);
	s.state[13] = endian::legetu32(nonce[0..4]);
	s.state[14] = endian::legetu32(nonce[4..8]);
	s.state[15] = endian::legetu32(nonce[8..12]);
};

// Initialise a XChacha20 stream.
export fn xchacha20_init(
	s: *stream,
	h: io::handle,
	key: []u8,
	nonce: []u8
) void = {
	assert(len(key) == KEYSZ);
	assert(len(nonce) == XNONCESZ);

	let dkey: [32]u8 = [0...];
	hchacha20(&dkey, key, nonce[..16]);

	let dnonce: [NONCESZ]u8 = [0...];
	dnonce[4..] = nonce[16..];

	chacha20_init(s, h, &dkey, dnonce);

	bytes::zero(dkey);
	bytes::zero(dnonce);
};

// Derives a new key from 'key' and 'nonce' as used during XChaCha20
// initialization. This function may only be used for specific purposes
// such as X25519 key derivation. Do not use if in doubt.
export fn hchacha20(out: []u8, key: []u8, nonce: []u8) void = {
	assert(len(out) == KEYSZ);
	assert(len(key) == KEYSZ);
	assert(len(nonce) == 16);

	let state: [16]u32 = [0...];
	defer bytes::zero((state: []u8: *[*]u8)[..BLOCKSZ]);

	state[0] = magic[0];
	state[1] = magic[1];
	state[2] = magic[2];
	state[3] = magic[3];
	state[4] = endian::legetu32(key[0..4]);
	state[5] = endian::legetu32(key[4..8]);
	state[6] = endian::legetu32(key[8..12]);
	state[7] = endian::legetu32(key[12..16]);
	state[8] = endian::legetu32(key[16..20]);
	state[9] = endian::legetu32(key[20..24]);
	state[10] = endian::legetu32(key[24..28]);
	state[11] = endian::legetu32(key[28..32]);
	state[12] = endian::legetu32(nonce[0..4]);
	state[13] = endian::legetu32(nonce[4..8]);
	state[14] = endian::legetu32(nonce[8..12]);
	state[15] = endian::legetu32(nonce[12..16]);

	hblock(state[..], &state, 20);

	endian::leputu32(out[0..4], state[0]);
	endian::leputu32(out[4..8], state[1]);
	endian::leputu32(out[8..12], state[2]);
	endian::leputu32(out[12..16], state[3]);
	endian::leputu32(out[16..20], state[12]);
	endian::leputu32(out[20..24], state[13]);
	endian::leputu32(out[24..28], state[14]);
	endian::leputu32(out[28..32], state[15]);
};

// Advances the key stream to "seek" to a future state by 'counter' times
// [[BLOCKSZ]].
export fn setctr(s: *stream, counter: u32) void = {
	s.state[12] = counter;

	// enforce block generation
	s.xorused = BLOCKSZ;
};

fn keybuf(s: *cipher::xorstream) []u8 = {
	let s = s: *stream;

	if (s.xorused >= BLOCKSZ) {
		block((s.xorbuf: []u8: *[*]u32)[..16], &s.state,
			s.rounds);
		// TODO on big endian systems s.xorbuf values need to
		// be converted from little endian.
		s.state[12] += 1;
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
		qr(&dest[1], &dest[5], &dest[9], &dest[13]);
		qr(&dest[2], &dest[6], &dest[10], &dest[14]);
		qr(&dest[3], &dest[7], &dest[11], &dest[15]);

		qr(&dest[0], &dest[5], &dest[10], &dest[15]);
		qr(&dest[1], &dest[6], &dest[11], &dest[12]);
		qr(&dest[2], &dest[7], &dest[8], &dest[13]);
		qr(&dest[3], &dest[4], &dest[9], &dest[14]);
	};
};


fn qr(a: *u32, b: *u32, c: *u32, d: *u32) void = {
	*a += *b;
	*d ^= *a;
	*d = rotl32(*d, 16);

	*c += *d;
	*b ^= *c;
	*b = rotl32(*b, 12);

	*a += *b;
	*d ^= *a;
	*d = rotl32(*d, 8);

	*c += *d;
	*b ^= *c;
	*b = rotl32(*b, 7);
};

fn finish(c: *cipher::xorstream) void = {
	let s = c: *stream;
	bytes::zero((s.state[..]: *[*]u8)[..BLOCKSZ]);
	bytes::zero(s.xorbuf);
};
