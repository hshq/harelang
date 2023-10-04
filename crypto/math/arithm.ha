// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The following code was initially ported from BearSSL.
//
// Copyright (c) 2017 Thomas Pornin <pornin@bolet.org>
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

// Returns the quotient and remainder of (hi, lo) divided by y:
// quo = (hi, lo) / y, rem = (hi, lo) % y with the dividend bits' upper
// half in parameter hi and the lower half in parameter lo.
// Panics for y == 0 (division by zero) or y <= hi (quotient overflow).
export fn divu32(hi: u32, lo: u32, y: u32) (u32, u32) = {
	assert(y != 0);
	assert(y > hi);

	let q: u32 = 0;
	const ch: u32 = equ32(hi, y);
	hi = muxu32(ch, 0, hi);
	for (let k: u32 = 31; k > 0; k -= 1) {
		const j = (32 - k);
		const w = (hi << j) | (lo >> k);
		const ctl = geu32(w, y) | (hi >> k);
		const hi2 = (w - y) >> j;
		const lo2 = lo - (y << k);
		hi = muxu32(ctl, hi2, hi);
		lo = muxu32(ctl, lo2, lo);
		q |= ctl << k;
	};
	let cf = geu32(lo, y) | hi;
	q |= cf;
	const r = muxu32(cf, lo - y, lo);
	return (q, r);
};

@test fn divu32() void = {
	const r = divu32(1, 4294967295, 9);
	assert(r.0 == 954437176);
	assert(r.1 == 7);

	const r = divu32(0, 485, 13);
	assert(r.0 == 37);
	assert(r.1 == 4);
};
