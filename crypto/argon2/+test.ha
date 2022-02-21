// License: MPL-2.0
// (c) 2021-2022 Armin Preiml <apreiml@strohwolke.at>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use bytes;

@test fn mode_d_one_pass() void = {
	let pass: [32]u8 = [1...];
	let salt: [16]u8 = [2...];
	let secret: [8]u8 = [3...];
	let data: [12]u8 = [4...];
	let result: [32]u8 = [0...];

	let expected: [_]u8 = [
		0xfa, 0x17, 0x75, 0xca, 0x80, 0x90, 0x64, 0x66, 0x18, 0xbe,
		0x70, 0xeb, 0x0f, 0xc9, 0xde, 0x43, 0x67, 0x58, 0xed, 0x0c,
		0xa5, 0x36, 0x83, 0x1a, 0xe9, 0xe1, 0x03, 0x48, 0x93, 0x81,
		0xc1, 0x79,
	];

	let cfg = config {
		secret = secret,
		data = data,
		passes = 1,
		parallel = 4,
		version = 0x13,
		mem = 32,
		...
	};

	argon2d(result[..], pass, salt, &cfg)!;

	assert(bytes::equal(result, expected));
};

@test fn rfc_d_test_vector() void = {
	let pass: [32]u8 = [1...];
	let salt: [16]u8 = [2...];
	let secret: [8]u8 = [3...];
	let data: [12]u8 = [4...];
	let result: [32]u8 = [0...];

	let mem: []u64 = alloc([0...], 32z * BLOCKSIZE);
	defer free(mem);

	let expected: [_]u8 = [
		0x51, 0x2b, 0x39, 0x1b, 0x6f, 0x11, 0x62, 0x97, 0x53, 0x71,
		0xd3, 0x09, 0x19, 0x73, 0x42, 0x94, 0xf8, 0x68, 0xe3, 0xbe,
		0x39, 0x84, 0xf3, 0xc1, 0xa1, 0x3a, 0x4d, 0xb9, 0xfa, 0xbe,
		0x4a, 0xcb,
	];

	let cfg = config {
		secret = secret,
		data = data,
		passes = 3,
		parallel = 4,
		version = 0x13,
		mem = mem[..],
		...
	};

	argon2d(result[..], pass, salt, &cfg)!;

	assert(bytes::equal(result, expected));
};


@test fn rfc_i_test_vector() void = {
	let pass: [32]u8 = [1...];
	let salt: [16]u8 = [2...];
	let secret: [8]u8 = [3...];
	let data: [12]u8 = [4...];
	let result: [32]u8 = [0...];

	let mem: []u64 = alloc([0...], 32z * BLOCKSIZE);
	defer free(mem);

	let expected: [_]u8 = [
		0xc8, 0x14, 0xd9, 0xd1, 0xdc, 0x7f, 0x37, 0xaa, 0x13, 0xf0,
		0xd7, 0x7f, 0x24, 0x94, 0xbd, 0xa1, 0xc8, 0xde, 0x6b, 0x01,
		0x6d, 0xd3, 0x88, 0xd2, 0x99, 0x52, 0xa4, 0xc4, 0x67, 0x2b,
		0x6c, 0xe8,
	];

	let cfg = config {
		secret = secret,
		data = data,
		passes = 3,
		parallel = 4,
		version = 0x13,
		mem = mem[..],
		...
	};

	argon2i(result[..], pass, salt, &cfg)!;

	assert(bytes::equal(result, expected));
};

@test fn rfc_id_test_vector() void = {
	let pass: [32]u8 = [1...];
	let salt: [16]u8 = [2...];
	let secret: [8]u8 = [3...];
	let data: [12]u8 = [4...];
	let result: [32]u8 = [0...];

	let mem: []u64 = alloc([0...], 32z * BLOCKSIZE);
	defer free(mem);

	let expected: [_]u8 = [
		0x0d, 0x64, 0x0d, 0xf5, 0x8d, 0x78, 0x76, 0x6c, 0x08, 0xc0,
		0x37, 0xa3, 0x4a, 0x8b, 0x53, 0xc9, 0xd0, 0x1e, 0xf0, 0x45,
		0x2d, 0x75, 0xb6, 0x5e, 0xb5, 0x25, 0x20, 0xe9, 0x6b, 0x01,
		0xe6, 0x59,
	];

	let cfg = config {
		secret = secret,
		data = data,
		passes = 3,
		parallel = 4,
		version = 0x13,
		mem = mem[..],
		...
	};

	argon2id(result[..], pass, salt, &cfg)!;

	assert(bytes::equal(result, expected));
};

