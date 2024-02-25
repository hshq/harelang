// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;

@test fn add() void = {
	let result: [4]u8 = [0...];

	let bx = fromhex("002132a0");
	defer free(bx);
	let by = fromhex("00ff3201");
	defer free(by);

	let carry = add(bx, by, 0);

	assert(carry == 0);

	decode(result, bx);
	assert(bytes::equal([0x00, 0x21, 0x32, 0xa0], result));

	let carry = add(bx, by, 1);

	assert(carry == 0);
	decode(result, bx);
	assert(bytes::equal([0x01, 0x20, 0x64, 0xa1], result));
};

@test fn muladd_small() void = {
	const mod = fromhex("0100");
	defer free(mod);
	let x = fromhex("0100");
	defer free(x);

	muladd_small(x, 3, mod);
	assert(equalshex(x, "03"));

	const mod = fromhex("1000000000");
	defer free(mod);
	let x = fromhexmod("0000000001", mod);
	defer free(x);
	muladd_small(x, 27, mod);
	assert(equalshex(x, "8000001b"));
};

@test fn mulacc() void = {
	let d = fromhex("0000000000000000");
	defer free(d);
	let a = fromhex("0010");
	defer free(a);
	let b = fromhex("0014");
	defer free(b);

	mulacc(d, a, b);
	assert(equalshex(d, "0140"));

	mulacc(d, a, b);
	assert(equalshex(d, "0280"));
};

@test fn rshift() void = {
	let x = fromhex("1020304050");
	defer free(x);
	rshift(x, 1);
	assert(equalshex(x, "0810182028"));

	let x = fromhex("00");
	defer free(x);
	rshift(x, 1);
	assert(equalshex(x, ""));
};

@test fn reduce() void = {
	let m = fromhex("87654321");
	defer free(m);

	let a = fromhex("1234");
	defer free(a);
	let x = fromhex("00000000");
	defer free(x);
	reduce(x, a, m);
	assert(equalshex(x, "1234"));

	let a = fromhex("0123456789abcdef");
	defer free(a);
	let x = fromhex("00000000");
	defer free(x);
	reduce(x, a, m);
	assert(equalshex(x, "14786ead"));
};

@test fn modpow() void = {
	let m = fromhex("87654321");
	defer free(m);
	let x = fromhexmod("00f03202", m);
	defer free(x);

	let e: [_]u8 = [0x00, 0x00, 0xc1, 0xf4];
	const m0i = ninv31(m[1]);

	let tmp: [10]word = [0...];
	modpow(x, e, m, m0i, tmp);

	assert(equalshex(x, "3de073fc"));

	let x = fromhexmod("00f03202", m);
	defer free(x);
	let tmp: [20]word = [0...];

	modpow(x, e, m, m0i, tmp);
	assert(equalshex(x, "3de073fc"));
};
