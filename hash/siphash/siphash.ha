// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::math::{rotl64};
use endian::{leputu64, legetu64};
use hash;
use io;

export type state = struct {
	hash::hash,
	v: [4]u64,
	x: [CHUNKSZ]u8,
	x_len: u8,
	c: u8,
	d: u8,
	ln: size,
};

def CHUNKSZ: size = 8;

const sip_vtable: io::vtable = io::vtable {
	writer = &write,
	closer = &close,
	...
};

// Creates a [hash::hash] that computes SipHash-c-d with the given 16 byte key,
// where c denotes number of compression rounds and d denotes number of
// finalization rounds. Recommended values for c and d are 2 and 4 respectively.
// Calling [[hash::close]] on this function will erase its state information.
// This function does not provide reset functionality and calling
// [[hash::reset]] on it will terminate execution.
export fn siphash(c: u8, d: u8, key: *[16]u8) state = {
	let h = state {
		stream = &sip_vtable,
		sum = &sum64_bytes,
		sz = CHUNKSZ,
		c = c,
		d = d,
		...
	};
	let s = legetu64(key[..8]);
	h.v[0] = 0x736f6d6570736575 ^ s;
	h.v[2] = 0x6c7967656e657261 ^ s;
	let s = legetu64(key[8..]);
	h.v[1] = 0x646f72616e646f6d ^ s;
	h.v[3] = 0x7465646279746573 ^ s;
	return h;
};

fn write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let h = s: *state;
	h.ln += len(buf);
	let n = CHUNKSZ - h.x_len;

	if (len(buf) < n) {
		// not enough data to fill a chunk
		h.x[h.x_len..h.x_len + len(buf)] = buf;
		h.x_len += len(buf): u8;
		return len(buf);
	};

	h.x[h.x_len..] = buf[..n];
	let b = legetu64(h.x);
	h.v[3] ^= b;
	for (let i = 0u8; i < h.c; i += 1) {
		round(h);
	};
	h.v[0] ^= b;

	let buf = buf[n..];
	for (len(buf) >= CHUNKSZ) {
		let b = legetu64(buf);
		h.v[3] ^= b;
		for (let i = 0u8; i < h.c; i += 1) {
			round(h);
		};
		h.v[0] ^= b;
		buf = buf[CHUNKSZ..];
	};

	h.x_len = len(buf): u8;
	h.x[..h.x_len] = buf;
	return len(buf);
};

// Returns the sum as a u64
export fn sum(h: *state) u64 = {
	let h = *h;

	for (let i = h.x_len; i < 7; i += 1) {
		h.x[i] = 0;
	};
	h.x[7] = h.ln: u8;

	let b = legetu64(h.x);
	h.v[3] ^= b;
	for (let i = 0u8; i < h.c; i += 1) {
		round(&h);
	};
	h.v[0] ^= b;

	h.v[2] ^= 0xff;
	for (let i = 0u8; i < h.d; i += 1) {
		round(&h);
	};
	return h.v[0] ^ h.v[1] ^ h.v[2] ^ h.v[3];
};

fn sum64_bytes(h: *hash::hash, buf: []u8) void = leputu64(buf, sum(h: *state));

fn round(h: *state) void = {
	h.v[0] += h.v[1];
	h.v[1] = rotl64(h.v[1], 13);
	h.v[1] ^= h.v[0];
	h.v[0] = rotl64(h.v[0], 32);
	h.v[2] += h.v[3];
	h.v[3] = rotl64(h.v[3], 16);
	h.v[3] ^= h.v[2];
	h.v[0] += h.v[3];
	h.v[3] = rotl64(h.v[3], 21);
	h.v[3] ^= h.v[0];
	h.v[2] += h.v[1];
	h.v[1] = rotl64(h.v[1], 17);
	h.v[1] ^= h.v[2];
	h.v[2] = rotl64(h.v[2], 32);
};

fn close(h: *io::stream) (void | io::error) = {
	let h = h: *state;
	h.v = [0...];
	h.x = [0...];
	h.ln = 0;
	h.x_len = 0;
};
