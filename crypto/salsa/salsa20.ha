use bytes;
use crypto::cipher;
use crypto::math::{rotl32, xor};
use endian;

// Size of a Salsa key, in bytes.
export def KEYSIZE: size = 32;

// Size of the XSalsa20 nonce, in bytes.
export def XNONCESIZE: size = 24;

// Size of the Salsa20 nonce, in bytes.
export def NONCESIZE: size = 8;

def ROUNDS: size = 20;

// The block size of the Salsa cipher.
export def BLOCKSIZE: size = 64;

const magic: [4]u32 = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

export type stream = struct {
	cipher::stream,
	state: [16]u32,
	xorbuf: [BLOCKSIZE]u8,
	xorused: size,
	rounds: size,
};

// Create a Salsa20 or XSalsa20 stream. Must be initalized with either
// [[salsa20_init]] or [[xsalsa20_init]], and must be finished with
// [[crypto::cipher::finish]] afterwards to wipe sensitive data from memory.
export fn salsa20() stream = {
	return stream {
		xor = &stream_xor,
		finish = &finish,
		xorused = BLOCKSIZE,
		rounds = ROUNDS,
		...
	};
};

fn init(
	state: *[16]u32,
	key: *[KEYSIZE]u8,
	nonce: *[8]u8,
	ctr: *[8]u8
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
	key: *[KEYSIZE]u8,
	nonce: *[NONCESIZE]u8,
) void = {
	let counter: [8]u8 = [0...];
	init(&s.state, key, nonce, &counter);
	s.xorused = BLOCKSIZE;
};

// Initialize an XSalsa20 stream. XSalsa20 differs from Salsa20 via the use of a
// larger nonce parameter.
export fn xsalsa20_init(
	s: *stream,
	key: *[KEYSIZE]u8,
	nonce: *[XNONCESIZE]u8
) void = {
	let state: [16]u32 = [0...];
	init(&state, key, nonce[0..8]: *[8]u8, nonce[8..16]: *[8]u8);
	hblock(state[..], &state, 20);

	let dkey: [32]u8 = [0...];
	endian::leputu32(dkey[0..4], state[0]);
	endian::leputu32(dkey[4..8], state[5]);
	endian::leputu32(dkey[8..12], state[10]);
	endian::leputu32(dkey[12..16], state[15]);
	endian::leputu32(dkey[16..20], state[6]);
	endian::leputu32(dkey[20..24], state[7]);
	endian::leputu32(dkey[24..28], state[8]);
	endian::leputu32(dkey[28..], state[9]);

	salsa20_init(s, &dkey, nonce[16..]: *[NONCESIZE]u8);

	bytes::zero((state[..]: *[*]u8)[..64]);
	bytes::zero(dkey);
};

// Advances the key stream to "seek" to a future state by 'counter' times
// [[BLOCKSIZE]].
export fn setctr(s: *stream, counter: u64) void = {
	s.state[8] = (counter & 0xFFFFFFFF): u32;
	s.state[9] = (counter >> 32): u32;
	s.xorused = BLOCKSIZE;
};

fn stream_xor(cs: *cipher::stream, dest: []u8, src: []u8) void = {
	assert(endian::host == &endian::little, "TODO big-endian");
	let s = cs: *stream;

	for (len(dest) > 0) {
		if (s.xorused >= BLOCKSIZE) {
			block((s.xorbuf[..]: *[*]u32)[..16], &s.state, s.rounds);
			s.state[8] += 1;
			if (s.state[8] == 0) {
				s.state[9] += 1;
			};
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

fn finish(cs: *cipher::stream) void = {
	let s = cs: *stream;
	bytes::zero((s.state[..]: *[*]u8)[..len(s.state) * size(u32)]);
	bytes::zero(s.xorbuf);
};
