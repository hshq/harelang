// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use hash;
use io;

def R1: int = 32;
def R2: int = 24;
def R3: int = 16;
def R4: int = 63;
def r: u64 = 12;
def BSZ: size = 128;

const iv: [8]u64 = [
	0x6A09E667F3BCC908, 0xBB67AE8584CAA73B,
	0x3C6EF372FE94F82B, 0xA54FF53A5F1D36F1,
	0x510E527FADE682D1, 0x9B05688C2B3E6C1F,
	0x1F83D9ABFB41BD6B, 0x5BE0CD19137E2179,
];

const sigma: [12][16]u8 = [
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
	[11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
	[7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
	[9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
	[2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
	[12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
	[13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
	[6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
	[10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
];

export type digest = struct {
	hash::hash,
	h: [8]u64,
	tlow: u64,
	thigh: u64,
	block: [BSZ]u8,
	blocklen: size,
};

const blake2b_vtable: io::vtable = io::vtable {
	writer = &write,
	closer = &close,
	...
};

// Creates a [[hash::hash]] which computes a BLAKE2b hash with a given key and a
// given hash size. The size must be between 1 and 64, inclusive. If this
// function is used to hash sensitive information, the caller should call
// [[hash::close]] to erase sensitive data from memory after use; if not, the
// use of [[hash::close]] is optional. This function does not provide reset
// functionality and calling [[hash::reset]] on it will terminate execution.
export fn blake2b(key: []u8, sz: size) digest = {
	assert(1 <= sz);
	assert(sz <= 64);
	assert(len(key) <= 64);
	let h = iv;
	h[0] ^= 0x01010000 ^ (len(key) << 8) ^ sz;
	let keyblock: [BSZ]u8 = [0...];
	keyblock[..len(key)] = key;
	return digest {
		stream = &blake2b_vtable,
		sum = &sum,
		sz = sz,
		h = h,
		tlow = 0,
		thigh = 0,
		block = keyblock,
		blocklen = if (len(key) > 0) BSZ else 0,
		...
	};
};

fn write(st: *io::stream, buf: const []u8) (size | io::error) = {
	if (len(buf) == 0) return 0z;
	let h = st: *digest;
	let length = len(buf);
	let buf = buf[..];

	for (h.blocklen + len(buf) > BSZ) {
		const n = BSZ - h.blocklen;
		h.block[h.blocklen..h.blocklen + n] = buf[..n];
		buf = buf[n..];

		h.tlow += BSZ;
		if (h.tlow < n: u64) h.thigh += 1;

		compress(&h.h, &h.block, h.tlow, h.thigh, false);
		h.blocklen = 0;
	};
	h.block[h.blocklen..h.blocklen + len(buf)] = buf;
	h.blocklen += len(buf);
	return length;
};

fn sum(h: *hash::hash, buf: []u8) void = {
	let h = h: *digest;
	let copy = *h;
	let h = &copy;
	defer hash::close(h);

	h.tlow += h.blocklen;
	if (h.tlow < h.blocklen: u64) h.thigh += 1;

	// Padding
	let tmp: [BSZ]u8 = [0...];
	h.block[h.blocklen..BSZ] = tmp[..BSZ - h.blocklen];
	h.blocklen = BSZ;

	compress(&h.h, &h.block, h.tlow, h.thigh, true);

	for (let i = 0z; i < h.sz / 8; i += 1) {
		endian::leputu64(buf[i * 8..i * 8 + 8], h.h[i]);
	};
};

// Compression function F
fn compress(h: *[8]u64, b: *[BSZ]u8, tlow: u64, thigh: u64, f: bool) void = {
	let v: [16]u64 = [0...];
	v[..8] = h[..];
	v[8..] = iv;
	v[12] ^= tlow;
	v[13] ^= thigh;
	if (f) v[14] = ~v[14];
	let m: [16]u64 = [0...];
	for (let i = 0z; i < len(m); i += 1) {
		m[i] = endian::legetu64(b[i * 8..i * 8 + 8]);
	};
	for (let i = 0u64; i < r; i += 1) {
		const s = &sigma[i];
		mix(&v, 0, 4, 8, 12, m[s[0]], m[s[1]]);
		mix(&v, 1, 5, 9, 13, m[s[2]], m[s[3]]);
		mix(&v, 2, 6, 10, 14, m[s[4]], m[s[5]]);
		mix(&v, 3, 7, 11, 15, m[s[6]], m[s[7]]);

		mix(&v, 0, 5, 10, 15, m[s[8]], m[s[9]]);
		mix(&v, 1, 6, 11, 12, m[s[10]], m[s[11]]);
		mix(&v, 2, 7, 8, 13, m[s[12]], m[s[13]]);
		mix(&v, 3, 4, 9, 14, m[s[14]], m[s[15]]);
	};

	for (let i = 0; i < 8; i += 1) {
		h[i] ^= v[i] ^ v[i + 8];
	};
};

// Mixing function G
fn mix(v: *[16]u64, a: size, b: size, c: size, d: size, x: u64, y: u64) void = {
	v[a] = v[a] + v[b] + x;
	v[d] = math::rotr64(v[d] ^ v[a], R1);
	v[c] = v[c] + v[d];
	v[b] = math::rotr64(v[b] ^ v[c], R2);
	v[a] = v[a] + v[b] + y;
	v[d] = math::rotr64(v[d] ^ v[a], R3);
	v[c] = v[c] + v[d];
	v[b] = math::rotr64(v[b] ^ v[c], R4);
};

fn close(stream: *io::stream) (void | io::error) = {
	let s = stream: *digest;
	bytes::zero((s.h[..]: *[*]u8)[..len(s.h) * size(u32)]);
	bytes::zero(s.block);
};
