// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;


@test fn encode() void = {
	const decoded: [12]u8 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
	let result: [12]u8 = [0...];

	let buf: [5]word = [0...];

	encode(buf, decoded);
	decode(result, buf);

	assert(bytes::equal(result, decoded));
};

@test fn encodebigger() void = {
	const decoded: [25]u8 = [
		0x8c, 0x99, 0xc4, 0x51, 0x53, 0x75, 0x86, 0x20, 0x73, 0x02,
		0x2a, 0x08, 0xf6, 0x01, 0xcd, 0x8a, 0xc8, 0x39, 0xa8, 0xb3,
		0x95, 0xb4, 0x27, 0xa1, 0xbb,
	];
	let result: [25]u8 = [0...];

	let buf: []word = alloc([0...], encodelen(decoded));
	defer free(buf);

	encode(buf, decoded);
	decode(result, buf);

	assert(bytes::equal(result, decoded));
};

@test fn decodebigger() void = {
	const encoded: [_]word = [
		0x32, // only 50 effective bits
		0x7fffffff, 0x0007ffff, 0x7fffffff,
	];

	let result: [8]u8 = [0xaa...];

	decode(result, encoded);
	assert(bytes::equal(result,
		[0x00, 0x03, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]));
};


@test fn encmoddec() void = {
	const input: [4]u8 = [0, 0, 0, 10];

	let mod = fromhex("00190000");
	defer free(mod);
	let resultbuf: []word = alloc([0...], encodelen(input));
	let result: [4]u8 = [0...];

	let ret = encodemod(resultbuf[..], input, mod);

	decode(result[..], resultbuf);
	assert(ret == 1);
	assert(bytes::equal(result, input));

	const input: [4]u8 = [0, 25, 0, 0];
	let ret = encodemod(resultbuf[..], input, mod);
	assert(ret == 0);
	assert(iszero(resultbuf) == 1);

	const input: [4]u8 = [0, 26, 0, 0];
	let ret = encodemod(resultbuf[..], input, mod);
	assert(ret == 0);
	assert(iszero(resultbuf) == 1);
};


@test fn encreddec() void = {
	const input: [4]u8 = [0, 0, 0, 0x0a];

	let mod = fromhex("190000");
	defer free(mod);
	let resultbuf: []word = alloc([0...], encodelen(input));
	let result: [4]u8 = [0...];

	encodereduce(resultbuf, input, mod);
	decode(result, resultbuf);
	assert(bytes::equal(result, input));

	const input: [4]u8 = [0, 0x19, 0, 0];
	let resultbuf: []word = alloc([0...], encodelen(input));
	encodereduce(resultbuf, input, mod);
	decode(result, resultbuf);
	assert(iszero(resultbuf) == 1);

	const input: [4]u8 = [0x24, 0x17, 0x01, 0x05];
	let resultbuf: []word = alloc([0...], encodelen(input));
	encodereduce(resultbuf, input, mod);
	decode(result, resultbuf);
	assert(bytes::equal(result, [0x00, 0x0e, 0x01, 0x05]));
};

@test fn word_countbits() void = {
	assert(word_countbits(0) == 0);
	assert(word_countbits(1) == 1);
	assert(word_countbits(2) == 2);
	assert(word_countbits(4) == 3);
	assert(word_countbits(7) == 3);
	assert(word_countbits(8) == 4);
	assert(word_countbits(1131) == 11);
};
