// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::hmac;
use crypto::mac;
use crypto::sha1;
use hash;

// Partial HMAC_DRBG implementation as describe in RFC6979 Section 3.1.1

type drbg = struct {
	h: *hash::hash,
	k: []u8,
	v: []u8,
	initgen: bool,
	buf: []u8,
};

// 'buf' must be at least 2 * hash::sz(h) + hash::bsz(h)
fn hmac_drbg(h: *hash::hash, seed: const []u8, buf: []u8) drbg = {
	const hlen = hash::sz(h);
	assert(len(buf) >= 2 * hlen + hash::bsz(h));

	let s = drbg {
		h = h,
		k = buf[..hlen],
		v = buf[hlen..2*hlen],
		initgen = true,
		buf = buf[2*hlen..],
	};

	s.k[..] = [0...];
	s.v[..] = [1...];

	hash::reset(h);
	let hm = hmac::hmac(h, s.k, s.buf);
	mac::write(&hm, s.v);
	mac::write(&hm, [0x00]);
	mac::write(&hm, seed);
	mac::sum(&hm, s.k);

	hmac_drbg_update(&s);

	hash::reset(h);
	let hm = hmac::hmac(h, s.k, s.buf);
	mac::write(&hm, s.v);
	mac::write(&hm, [0x01]);
	mac::write(&hm, seed);
	mac::sum(&hm, s.k);

	hmac_drbg_update(&s);

	return s;
};

fn hmac_drbg_update(s: *drbg) void = {
	hash::reset(s.h);
	let hm = hmac::hmac(s.h, s.k, s.buf);
	mac::write(&hm, s.v);
	mac::sum(&hm, s.v);
};

fn hmac_drbg_generate(s: *drbg, dest: []u8) void = {
	if (!s.initgen) {
		hash::reset(s.h);
		let hm = hmac::hmac(s.h, s.k, s.buf);
		mac::write(&hm, s.v);
		mac::write(&hm, [0x00]);
		mac::sum(&hm, s.k);

		hmac_drbg_update(s);
	};
	s.initgen = false;

	let n = 0z;
	for (n < len(dest)) {
		hmac_drbg_update(s);

		const remain = len(dest) - n;
		let max = if (remain > len(s.v)) len(s.v) else remain;

		dest[n..n+max] = s.v[..max];
		n += max;
	};
};

@test fn hmac_drbg() void = {
	const seed: [_]u8 = [
		0x79, 0x34, 0x9b, 0xbf, 0x7c, 0xdd, 0xa5, 0x79, 0x95, 0x57,
		0x86, 0x66, 0x21, 0xc9, 0x13, 0x83, 0x11, 0x46, 0x73, 0x3a,
		0xbf, 0x8c, 0x35, 0xc8,
	];

	let h = sha1::sha1();
	let buf: [sha1::SZ * 2 + sha1::BLOCKSZ]u8 = [0...];
	let s = hmac_drbg(&h, seed, buf);

	let dest: [30]u8 = [0...];
	hmac_drbg_generate(&s, dest);
	const expect: [_]u8 = [
		0x4e, 0xea, 0xad, 0x22, 0xb1, 0xbc, 0x51, 0x9e, 0xe6, 0xaa,
		0x5a, 0x56, 0xd7, 0xab, 0x29, 0xc3, 0x39, 0xc4, 0xea, 0x10,
		0x11, 0x2e, 0xe5, 0x4e, 0x2a, 0x6f, 0x81, 0xcd, 0x19, 0x7a,
	];
	assert(bytes::equal(expect, dest));

	const expect: [_]u8 = [
		0xe2, 0x1f, 0x3a, 0x90, 0x38, 0xc4, 0xc6, 0xe1, 0xa5, 0x0c,
		0x72, 0x6c, 0x04, 0x90, 0xe0, 0x6a, 0xa3, 0xcb, 0x8c, 0xce,
		0xd2, 0x89, 0x1d, 0x01, 0xf3,
	];
	hmac_drbg_generate(&s, dest);
	assert(bytes::equal(expect, dest[..25]));
};
