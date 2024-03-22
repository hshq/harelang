// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The following code was initially ported from BearSSL.
//
// Copyright (c) 2016 Thomas Pornin <pornin@bolet.org>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
use bytes;
use endian::{begetu64,beputu64};

fn bmul64(x: u64, y: u64) u64 = {
	const x0 = x & 0x1111111111111111;
	const x1 = x & 0x2222222222222222;
	const x2 = x & 0x4444444444444444;
	const x3 = x & 0x8888888888888888;
	const y0 = y & 0x1111111111111111;
	const y1 = y & 0x2222222222222222;
	const y2 = y & 0x4444444444444444;
	const y3 = y & 0x8888888888888888;
	let z0 = (x0 * y0) ^ (x1 * y3) ^ (x2 * y2) ^ (x3 * y1);
	let z1 = (x0 * y1) ^ (x1 * y0) ^ (x2 * y3) ^ (x3 * y2);
	let z2 = (x0 * y2) ^ (x1 * y1) ^ (x2 * y0) ^ (x3 * y3);
	let z3 = (x0 * y3) ^ (x1 * y2) ^ (x2 * y1) ^ (x3 * y0);
	z0 &= 0x1111111111111111;
	z1 &= 0x2222222222222222;
	z2 &= 0x4444444444444444;
	z3 &= 0x8888888888888888;
	return z0 | z1 | z2 | z3;
};


fn rev64(x: u64) u64 = {
	x = ((x & 0x5555555555555555) << 1) | ((x >> 1) & 0x5555555555555555);
	x = ((x & 0x3333333333333333) << 2) | ((x >> 2) & 0x3333333333333333);
	x = ((x & 0x0F0F0F0F0F0F0F0F) << 4) | ((x >> 4) & 0x0F0F0F0F0F0F0F0F);
	x = ((x & 0x00FF00FF00FF00FF) << 8) | ((x >> 8) & 0x00FF00FF00FF00FF);
	x = ((x & 0x0000FFFF0000FFFF) << 16) | ((x >> 16) & 0x0000FFFF0000FFFF);
	return (x << 32) | (x >> 32);
};

// GHASH implementation that relies on constant time 64bit multiplication
fn ghash_ctmul64(y: []u8, h: const []u8, data: const []u8) void = {
	let buf = data[..];
	let tmp: [16]u8 = [0...];

	let y1 = begetu64(y);
	let y0 = begetu64(y[8..]);
	const h1 = begetu64(h);
	const h0 = begetu64(h[8..]);
	const h0r = rev64(h0);
	const h1r = rev64(h1);
	const h2 = h0 ^ h1;
	const h2r = h0r ^ h1r;

	for (len(buf) > 0) {
		let src: []u8 = [];

		if (len(buf) >= 16) {
			src = buf[..16];
			buf = buf[16..];
		} else {
			tmp[..len(buf)] = buf[..];
			bytes::zero(tmp[len(buf)..len(tmp)]);
			src = tmp;
			buf = [];
		};
		y1 ^= begetu64(src);
		y0 ^= begetu64(src[8..]);

		const y0r = rev64(y0);
		const y1r = rev64(y1);
		const y2 = y0 ^ y1;
		const y2r = y0r ^ y1r;

		const z0 = bmul64(y0, h0);
		const z1 = bmul64(y1, h1);
		let z2 = bmul64(y2, h2);
		let z0h = bmul64(y0r, h0r);
		let z1h = bmul64(y1r, h1r);
		let z2h = bmul64(y2r, h2r);
		z2 ^= z0 ^ z1;
		z2h ^= z0h ^ z1h;
		z0h = rev64(z0h) >> 1;
		z1h = rev64(z1h) >> 1;
		z2h = rev64(z2h) >> 1;


		let v0 = z0;
		let v1 = z0h ^ z2;
		let v2 = z1 ^ z2h;
		let v3 = z1h;

		v3 = (v3 << 1) | (v2 >> 63);
		v2 = (v2 << 1) | (v1 >> 63);
		v1 = (v1 << 1) | (v0 >> 63);
		v0 = (v0 << 1);

		v2 ^= v0 ^ (v0 >> 1) ^ (v0 >> 2) ^ (v0 >> 7);
		v1 ^= (v0 << 63) ^ (v0 << 62) ^ (v0 << 57);
		v3 ^= v1 ^ (v1 >> 1) ^ (v1 >> 2) ^ (v1 >> 7);
		v2 ^= (v1 << 63) ^ (v1 << 62) ^ (v1 << 57);

		y0 = v2;
		y1 = v3;
	};

	beputu64(y, y1);
	beputu64(y[8..], y0);
};
