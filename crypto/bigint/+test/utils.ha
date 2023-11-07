// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::hex;

// The caller must free the result.
export fn fromhex(h: str) []word = {
	let n: []u8 = hex::decodestr(h)!;
	defer free(n);

	let i: []word = alloc([0...], encodelen(n));
	encode(i, n);
	return i;
};

// 'h' must be lower than 'm'
export fn fromhexmod(h: str, m: []word) []word = {
	let r = fromhex(h);
	r[0] = m[0];
	return r;
};

// The caller must free the result.
export fn tohex(x: []word) str = {
	let buf: []u8 = alloc([0...], (len(x) - 1) * size(word));
	defer free(buf);

	decode(buf, x);

	let i = 0z;
	for (i < len(buf); i += 1) {
		if (buf[i] != 0) {
			break;
		};
	};

	return hex::encodestr(buf[i..]);
};

export fn equalshex(x: []word, h: str) bool = {
	let result = tohex(x);
	defer free(result);
	return result == h;
};

@test fn iszero() void = {
	let x = fromhex("210032a0");
	defer free(x);
	let y = fromhex("00000000");
	defer free(y);

	assert(iszero(x) == 0);
	assert(iszero(y) == 1);
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
