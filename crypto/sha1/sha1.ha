// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use hash;
use io;

// The size, in bytes, of a SHA-1 digest.
export def SZ: size = 20;

// The internal block size.
export def BLOCKSZ: size = 64;

def chunk: size = 64;
def init0: u32 = 0x67452301;
def init1: u32 = 0xEFCDAB89;
def init2: u32 = 0x98BADCFE;
def init3: u32 = 0x10325476;
def init4: u32 = 0xC3D2E1F0;

export type state = struct {
	hash::hash,
	h: [5]u32,
	x: [chunk]u8,
	nx: size,
	ln: size,
};

const sha1_vtable: io::vtable = io::vtable {
	writer = &write,
	closer = &close,
	...
};

// Creates a [[hash::hash]] which computes a SHA-1 hash. Note that this
// algorithm is no longer considered secure. Where possible, applications are
// encouraged to use [[crypto::sha256::]] or [[crypto::sha512::]] instead. If
// this function is used to hash sensitive information, the caller should call
// [[hash::close]] to erase sensitive data from memory after use; if not, the
// use of [[hash::close]] is optional.
export fn sha1() state = {
	let sha = state {
		stream = &sha1_vtable,
		sum = &sum,
		reset = &reset,
		sz = SZ,
		bsz = BLOCKSZ,
		...
	};
	hash::reset(&sha);
	return sha;
};

fn write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let h = st: *state;
	let b: []u8 = buf;
	let nn = len(buf);

	h.ln += nn;

	if (h.nx > 0) {
		// Compute how many bytes can be copied into h.x
		let r = len(h.x) - h.nx;
		let n = if (nn > r) r else nn;
		h.x[h.nx..h.nx + n] = b[..n];
		h.nx += n;
		if (h.nx == chunk) {
			block(h, h.x[..]);
			h.nx = 0;
		};
		b = b[n..];
	};
	if (len(b) >= chunk) {
		let n = len(b) & ~(chunk - 1);
		block(h, b[..n]);
		b = b[n..];
	};
	if (len(b) > 0) {
		let n = len(b);
		h.x[..n] = b[..n];
		h.nx = n;
	};
	return nn;
};

fn reset(h: *hash::hash) void = {
	let h = h: *state;
	h.h[0] = init0;
	h.h[1] = init1;
	h.h[2] = init2;
	h.h[3] = init3;
	h.h[4] = init4;
	h.nx = 0;
	h.ln = 0;
};

fn sum(h: *hash::hash, buf: []u8) void = {
	let h = h: *state;
	let copy = *h;
	let h = &copy;
	defer hash::close(h);

	// Padding. Add a 1 bit and 0 bits until 56 bytes mod 64.
	let ln = h.ln;
	let tmp: [64]u8 = [0x80, 0...];
	const pad = if ((ln % 64z) < 56z) 56z - ln % 64z
		else 64 + 56z - ln % 64z;
	write(h, tmp[..pad])!;

	// Length in bits.
	ln <<= 3;
	endian::beputu64(tmp, ln: u64);
	write(h, tmp[..8])!;

	assert(h.nx == 0);

	// Where we write the digest
	endian::beputu32(buf[0..], h.h[0]);
	endian::beputu32(buf[4..], h.h[1]);
	endian::beputu32(buf[8..], h.h[2]);
	endian::beputu32(buf[12..], h.h[3]);
	endian::beputu32(buf[16..], h.h[4]);
};

let K0: u32 = 0x5A827999;
let K1: u32 = 0x6ED9EBA1;
let K2: u32 = 0x8F1BBCDC;
let K3: u32 = 0xCA62C1D6;

// A generic, pure Hare version of the SHA-1 block step
fn block(h: *state, p: []u8) void = {
	let w: [16]u32 = [0...];

	let h0 = h.h[0];
	let h1 = h.h[1];
	let h2 = h.h[2];
	let h3 = h.h[3];
	let h4 = h.h[4];

	for (len(p) >= chunk) {
		for (let i = 0z; i < 16; i += 1) {
			let j = i * 4;
			w[i] = p[j]: u32 << 24
				| p[j+1]: u32 << 16
				| p[j+2]: u32 << 8
				| p[j+3]: u32;
		};
		let a = h0;
		let b = h1;
		let c = h2;
		let d = h3;
		let e = h4;

		// Each of the four 20-iteration rounds differs only in the
		// computation of f and the choice of Ki for i=0..5
		let i = 0z;
		for (i < 16; i += 1) {
			let f = (b & c) | (~b & d);
			let t = math::rotl32(a, 5) + f + e + w[i & 0xf] + K0;
			// The order matters here!
			e = d; d = c; c = math::rotl32(b, 30); b = a; a = t;
		};
		for (i < 20; i += 1) {
			let tmp = w[(i - 3) & 0xf]
				^ w[(i - 8) & 0xf]
				^ w[(i - 14) & 0xf]
				^ w[i & 0xf];
			w[i & 0xf] = tmp << 1 | tmp >> 31;

			let f = (b & c) | (~b & d);
			let t = math::rotl32(a, 5) + f + e + w[i & 0xf] + K0;
			e = d; d = c; c = math::rotl32(b, 30); b = a; a = t;
		};
		for (i < 40; i += 1) {
			let tmp = w[(i - 3) & 0xf]
				^ w[(i - 8) & 0xf]
				^ w[(i - 14) & 0xf]
				^ w[i & 0xf];
			w[i & 0xf] = tmp << 1 | tmp >> 31;

			let f = b ^ c ^ d;
			let t = math::rotl32(a, 5) + f + e + w[i & 0xf] + K1;
			e = d; d = c; c = math::rotl32(b, 30); b = a; a = t;
		};
		for (i < 60; i += 1) {
			let tmp = w[(i - 3) & 0xf]
				^ w[(i - 8) & 0xf]
				^ w[(i - 14) & 0xf]
				^ w[i & 0xf];
			w[i & 0xf] = tmp << 1 | tmp >> 31;

			let f = ((b | c) & d) | (b & c);
			let t = math::rotl32(a, 5) + f + e + w[i & 0xf] + K2;
			e = d; d = c; c = math::rotl32(b, 30); b = a; a = t;
		};
		for (i < 80; i += 1) {
			let tmp = w[(i - 3) & 0xf]
				^ w[(i - 8) & 0xf]
				^ w[(i - 14) & 0xf]
				^ w[i & 0xf];
			w[i & 0xf] = tmp << 1 | tmp >> 31;

			let f = b ^ c ^ d;
			let t = math::rotl32(a, 5) + f + e + w[i & 0xf] + K3;
			e = d; d = c; c = math::rotl32(b, 30); b = a; a = t;
		};

		h0 += a;
		h1 += b;
		h2 += c;
		h3 += d;
		h4 += e;

		p = p[chunk..];
	};

	h.h[0] = h0;
	h.h[1] = h1;
	h.h[2] = h2;
	h.h[3] = h3;
	h.h[4] = h4;
};

fn close(stream: *io::stream) (void | io::error) = {
	let s = stream: *state;
	bytes::zero((s.h[..]: *[*]u8)[..len(s.h) * size(u32)]);
	bytes::zero(s.x);
};
