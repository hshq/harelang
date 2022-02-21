// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use bytes;
use crypto::cipher;
use crypto::math::{rotl32, xor};
use endian;

// Size of a Chacha key, in bytes.
export def KEYSIZE: size = 32;

// Size of the XChacha20 nonce, in bytes.
export def XNONCESIZE: size = 24;

// Size of the Chacha20 nonce, in bytes.
export def NONCESIZE: size = 12;

// The block size of the Chacha cipher in bytes.
export def BLOCKSIZE: size = 64;

def ROUNDS: size = 20;
const magic: [4]u32 = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

// Create a Chacha20 or XChacha20 stream. Needs to be initalized with either
// [[chacha20_init]] or [[xchacha20_init]]. It must be finished with
// [[crypto::cipher::finish]].
export type stream = struct {
	cipher::stream,
	state: [16]u32,
	xorbuf: [BLOCKSIZE]u8,
	xorused: size,
	rounds: size,
};

// Creates a ChaCha20 or XChaCha20 stream cipher. Must be initialized with
// [[chacha20_init]] or [[xchacha20_init]] prior to use, and must be finished
// with [[crypto::cipher::finish]] afterwards to wipe sensitive data from
// memory.
export fn chacha20() stream = {
	return stream {
		xor = &stream_xor,
		finish = &finish,
		xorused = BLOCKSIZE,
		rounds = ROUNDS,
		...
	};
};

// Initialize a Chacha20 stream.
export fn chacha20_init(
	s: *stream,
	key: *[KEYSIZE]u8,
	nonce: *[NONCESIZE]u8
) void = {
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

	s.xorused = BLOCKSIZE;
};

// Initialise a XChacha20 stream.
export fn xchacha20_init(
	s: *stream,
	key: *[KEYSIZE]u8,
	nonce: *[XNONCESIZE]u8
) void = {
	let state: [16]u32 = [0...];

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

	hblock(state[..], &state, s.rounds);

	let dkey: [32]u8 = [0...];
	dkey[..16] = (state: []u8: *[*]u8)[0..16];
	dkey[16..] = (state: []u8: *[*]u8)[48..64];

	let dnonce: [NONCESIZE]u8 = [0...];
	dnonce[4..] = nonce[16..];

	chacha20_init(s, &dkey, &dnonce);

	bytes::zero((state: []u8: *[*]u8)[..BLOCKSIZE]);
	bytes::zero(dkey);
	bytes::zero(dnonce);
};

// Advances the key stream to "seek" to a future state by 'counter' times
// [[BLOCKSIZE]].
export fn setctr(s: *stream, counter: u32) void = {
	s.state[12] = counter;

	// enforce block generation
	s.xorused = BLOCKSIZE;
};

fn stream_xor(c: *cipher::stream, dest: []u8, src: []u8) void = {
	let s = c: *stream;

	for (len(dest) > 0) {
		if (s.xorused >= BLOCKSIZE) {
			block((s.xorbuf: []u8: *[*]u32)[..16], &s.state,
				s.rounds);
			// TODO on big endian systems s.xorbuf values need to
			// be converted from little endian.
			s.state[12] += 1;
			s.xorused = 0;
		};

		const max = if (len(dest) > (BLOCKSIZE - s.xorused)) {
			yield BLOCKSIZE - s.xorused;
		} else {
			yield len(dest);
		};

		xor(dest[..max], src[..max],
			s.xorbuf[s.xorused..s.xorused + max]);
		s.xorused += max;

		dest = dest[max..];
		src = src[max..];
	};
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

fn finish(c: *cipher::stream) void = {
	let s = c: *stream;
	bytes::zero((s.state[..]: *[*]u8)[..BLOCKSIZE]);
	bytes::zero(s.xorbuf);
};
