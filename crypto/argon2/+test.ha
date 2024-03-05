// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::hex;
use os;
use strings;
use test;

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

	let cfg = conf {
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

	let mem: []u64 = alloc([0...], 32z * BLOCKSZ);
	defer free(mem);

	let expected: [_]u8 = [
		0x51, 0x2b, 0x39, 0x1b, 0x6f, 0x11, 0x62, 0x97, 0x53, 0x71,
		0xd3, 0x09, 0x19, 0x73, 0x42, 0x94, 0xf8, 0x68, 0xe3, 0xbe,
		0x39, 0x84, 0xf3, 0xc1, 0xa1, 0x3a, 0x4d, 0xb9, 0xfa, 0xbe,
		0x4a, 0xcb,
	];

	let cfg = conf {
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

	let mem: []u64 = alloc([0...], 32z * BLOCKSZ);
	defer free(mem);

	let expected: [_]u8 = [
		0xc8, 0x14, 0xd9, 0xd1, 0xdc, 0x7f, 0x37, 0xaa, 0x13, 0xf0,
		0xd7, 0x7f, 0x24, 0x94, 0xbd, 0xa1, 0xc8, 0xde, 0x6b, 0x01,
		0x6d, 0xd3, 0x88, 0xd2, 0x99, 0x52, 0xa4, 0xc4, 0x67, 0x2b,
		0x6c, 0xe8,
	];

	let cfg = conf {
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

	let mem: []u64 = alloc([0...], 32z * BLOCKSZ);
	defer free(mem);

	let expected: [_]u8 = [
		0x0d, 0x64, 0x0d, 0xf5, 0x8d, 0x78, 0x76, 0x6c, 0x08, 0xc0,
		0x37, 0xa3, 0x4a, 0x8b, 0x53, 0xc9, 0xd0, 0x1e, 0xf0, 0x45,
		0x2d, 0x75, 0xb6, 0x5e, 0xb5, 0x25, 0x20, 0xe9, 0x6b, 0x01,
		0xe6, 0x59,
	];

	let cfg = conf {
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

type tcase = struct {
	c: conf,
	m: mode,
	h: str,
};

@test fn samples() void = {
	const pass = strings::toutf8("trustno1");
	const salt = strings::toutf8("abcdefgh");

	const tests: [_]tcase = [
		tcase {
			c = conf {
				passes = 1,
				parallel = 3,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::ID,
			h = "c7ada5ba3222fa45a3802249b509dcfb10e68a50e3faad2a6377eeca8395ab47",
		},
		tcase {
			c = conf {
				passes = 1,
				parallel = 4,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::ID,
			h = "21543b2017ede3f865ea5cb88295628ba25eb3be53a8c4aeb0ac1a264be0110a",
		},
		tcase {
			c = conf {
				passes = 1,
				parallel = 4,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::I,
			h = "5c3124ce5f3556e5e25f06b5108718f2cd72afee98a3249656eb85ecc0e5b314",
		},
		tcase {
			c = conf {
				passes = 1,
				parallel = 4,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::D,
			h = "d75524ad0b899363ce77f2d1e1040763dc01cfc725db635391bba163001f08cb",
		},
		tcase {
			c = conf {
				passes = 3,
				parallel = 3,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::ID,
			h = "226c3ca6caba42b102035d332a11b350f1e19675fccb6e24aa33ca8c31d588c1",
		},
		tcase {
			c = conf {
				passes = 1,
				parallel = 8,
				version = 0x13,
				mem = 64,
				...
			},
			m = mode::ID,
			h = "fadf598b70708f4d91b0e98f038fd25a73950f1f85d57fb250740d817f95e9a9",
		},
		tcase {
			c = conf {
				passes = 1,
				parallel = 4,
				version = 0x13,
				mem = 96,
				...
			},
			m = mode::ID,
			h = "c99aa41cb53cc4919d336c19d38b30d8633c71faa9475293f3fbe0aa6ccd65b2",
		},
	];

	for (let i = 0z; i < len(tests); i += 1) {
		const t = tests[i];
		const expected = hex::decodestr(t.h)!;
		defer free(expected);
		let dest: []u8 = alloc([0...], len(expected));
		defer free(dest);

		argon2(dest, pass, salt, &t.c, t.m)!;
		assert(bytes::equal(expected, dest));
	};
};

@test fn samples_slow() void = {
	test::require("slow");

	const pass = strings::toutf8("trustno1");
	const salt = strings::toutf8("abcdefgh");

	const tests: [_]tcase = [
		tcase {
			c = low_mem_conf,
			m = mode::ID,
			h = "8974537c53677aae532b319af700bb4232a0d74eee7d57296b2a3f8303a6bafe",
		},
		tcase {
			c = default_conf,
			m = mode::ID,
			h = "3b282cbf435b0e022f7041549583ddc802e519109f1da8f12d2054910913d660",
		},
	];

	for (let i = 0z; i < len(tests); i += 1) {
		const t = tests[i];
		const expected = hex::decodestr(t.h)!;
		defer free(expected);
		let dest: []u8 = alloc([0...], len(expected));
		defer free(dest);

		argon2(dest, pass, salt, &t.c, t.m)!;
		assert(bytes::equal(expected, dest));
	};
};
