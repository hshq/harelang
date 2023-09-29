// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// This implementation was ported from Loup Vaillant's monocypher project.

use bytes;
use crypto::mac;
use endian;
use io;

// Internal block size in bytes.
export def BLOCKSZ: size = 16;

// Length of the resulting MAC in bytes.
export def SZ: size = 16;

// Poly1305 key.
export type key = [32]u8;

export type state = struct {
	mac::mac,
	r: [4]u32,
	h: [5]u32,
	c: [16]u8,
	pad: [4]u32,
	cidx: size,
};

const poly1305_vtable: io::vtable = io::vtable {
	writer = &write,
	...
};

// Creates a [[crypto::mac::mac]] that computes the poly1305 MAC. It needs to
// be initialised using [[init]]. Like the other MACs it needs to be finished
// using [[crypto::mac::finish]] after use.
export fn poly1305() state = {
	return state {
		stream = &poly1305_vtable,
		sum = &sum,
		finish = &finish,
		sz = SZ,
		bsz = BLOCKSZ,
		...
	};
};

// Initialises the MAC with given one time key.
export fn init(p: *state, key: *key) void = {
	leputu32slice(p.r, key);
	leputu32slice(p.pad, key[16..]);

	p.r[0] &= 0x0fffffff;
	for (let i = 1z; i < 4; i += 1) {
		p.r[i] &= 0x0ffffffc;
	};

	p.cidx = 0;
};

fn leputu32slice(dest: []u32, src: []u8) void = {
	for (let i = 0z; i < len(dest); i += 1) {
		dest[i] = endian::legetu32(src[i * 4..(i + 1) * 4]);
	};
};

fn write(st: *io::stream, bbuf: const []u8) (size | io::error) = {
	let p = st: *state;
	let buf: []u8 = bbuf;
	const written = len(buf);

	for (len(buf) > 0) {
		const n = if (len(buf) <= BLOCKSZ - p.cidx) {
			yield len(buf);
		} else {
			yield BLOCKSZ - p.cidx;
		};

		p.c[p.cidx..p.cidx + n] = buf[..n];
		p.cidx += n;
		buf = buf[n..];

		if (p.cidx >= BLOCKSZ) {
			block(p, p.c, 1);
			p.cidx = 0;
		};
	};

	return written;
};

fn block(p: *state, buf: []u8, end: u32) void = {
	let s: [4]u32 = [0...];
	leputu32slice(s, buf);

	// s = h + c, without carry propagation
	const s0: u64 = p.h[0]: u64 + s[0];
	const s1: u64 = p.h[1]: u64 + s[1];
	const s2: u64 = p.h[2]: u64 + s[2];
	const s3: u64 = p.h[3]: u64 + s[3];
	const s4: u32 = p.h[4] + end;

	// Local all the things!
	const r0: u32 = p.r[0];
	const r1: u32 = p.r[1];
	const r2: u32 = p.r[2];
	const r3: u32 = p.r[3];
	const rr0: u32 = (r0 >> 2) * 5;
	const rr1: u32 = (r1 >> 2) + r1;
	const rr2: u32 = (r2 >> 2) + r2;
	const rr3: u32 = (r3 >> 2) + r3;

	// (h + c) * r, without carry propagation
	const x0: u64 = s0 * r0 + s1 * rr3 + s2 * rr2 + s3 * rr1 + s4 * rr0;
	const x1: u64 = s0 * r1 + s1 * r0 + s2 * rr3 + s3 * rr2 + s4 * rr1;
	const x2: u64 = s0 * r2 + s1 * r1 + s2 * r0 + s3 * rr3 + s4 * rr2;
	const x3: u64 = s0 * r3 + s1 * r2 + s2 * r1 + s3 * r0 + s4 * rr3;
	const x4: u32 = s4 * (r0 & 3);

	// partial reduction modulo 2^130 - 5
	const u5: u32 = x4 + (x3 >> 32): u32;
	const u0: u64 = (u5 >>  2) * 5 + (x0 & 0xffffffff);
	const u1: u64 = (u0 >> 32) + (x1 & 0xffffffff) + (x0 >> 32);
	const u2: u64 = (u1 >> 32) + (x2 & 0xffffffff) + (x1 >> 32);
	const u3: u64 = (u2 >> 32) + (x3 & 0xffffffff) + (x2 >> 32);
	const u4: u64 = (u3 >> 32) + (u5 & 3);

	// Update the hash
	p.h[0] = u0: u32;
	p.h[1] = u1: u32;
	p.h[2] = u2: u32;
	p.h[3] = u3: u32;
	p.h[4] = u4: u32;
};

fn sum(m: *mac::mac, buf: []u8) void = {
	let p = m: *state;
	if (p.cidx > 0) {
		// update last block
		p.c[p.cidx] = 1;
		bytes::zero(p.c[p.cidx + 1..]);
		block(p, p.c, 0);
	};

	// check if we should subtract 2^130-5 by performing the
	// corresponding carry propagation.
	let c: u64 = 5;
	for (let i = 0z; i < 4; i += 1) {
		c  += p.h[i];
		c >>= 32;
	};
	c += p.h[4];
	c = (c >> 2) * 5; // shift the carry back to the beginning
	// c now indicates how many times we should subtract 2^130-5 (0 or 1)

	for (let i = 0z; i < 4; i += 1) {
		c += p.h[i]: u64 + p.pad[i]: u64;
		endian::leputu32(buf[i * 4..(i + 1) * 4], c: u32);
		c = c >> 32;
	};
};

fn finish(m: *mac::mac) void = {
	let p = m: *state;
	bytes::zero((p.r[..]: *[*]u8)[..len(p.r) * size(u32)]);
	bytes::zero((p.h[..]: *[*]u8)[..len(p.h) * size(u32)]);
	bytes::zero(p.c[..]);
	bytes::zero((p.pad[..]: *[*]u8)[..len(p.pad) * size(u32)]);
};
