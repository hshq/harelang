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
use bytes;

// Sets encoded bitlen of 'x' to 'ebitlen' and then zeroes its effective words.
export fn zero(x: []word, ebitlen: word) void = {
	x[0] = ebitlen;
	const ewordlen = ewordlen(x);
	bytes::zero((x: *[*]u8)[size(word)..(1 + ewordlen) * size(word)]);
};

@test fn zero() void = {
	let w: [4]word = [0xffffffff...];

	// set effective word len to 2 words.
	const elen = countbits(w[1..3]);
	w[0] = elen;

	zero(w[..3], elen);

	// check if zero does not overwrite more or less than elen
	assert(w[0] == elen);
	assert(w[3] == 0xffffffff);
};

// Checks whether the effective words of 'x' are zero. Returns 1 if so, or 0
// otherwise.
fn iszero(x: []word) u32 = {
	let z: u32 = 0;

	for (let i = ewordlen(x); i > 0; i -= 1) {
		z |= x[i];
	};
	return ~(z | -(z: i32): u32) >> 31;
};

@test fn iszero() void = {
	let x = fromhex("210032a0");
	let y = fromhex("00000000");

	assert(iszero(x) == 0);
	assert(iszero(y) == 1);

	free(x);
	free(y);
};


