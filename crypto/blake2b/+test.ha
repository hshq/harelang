// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::hex;
use fmt;
use hash;
use io;
use memio;
use strings;

@test fn blake2b() void = {
	for (let i = 0z; i < len(vectors); i += 1) {
		let key = hex::decodestr(vectors[i].key)!;
		defer free(key);
		let out = hex::decodestr(vectors[i].out)!;
		defer free(out);
		let in = hex::decodestr(vectors[i].in)!;
		defer free(in);
		let blake = blake2b(key, len(out));
		defer hash::close(&blake);
		hash::write(&blake, in);
		let sum: []u8 = alloc([], len(out));
		defer free(sum);
		for (let i = 0z; i < len(out); i += 1) {
			append(sum, 0);
		};
		hash::sum(&blake, sum);
		let out = memio::dynamic();
		defer io::close(&out)!;
		let enc = hex::newencoder(&out);
		io::write(&enc, sum)!;
		assert(memio::string(&out)! == vectors[i].out);
	};

	const vectors = [
		("", "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce"),
		("abc", "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923"),
		("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "7285ff3e8bd768d69be62b3bf18765a325917fa9744ac2f582a20850bc2b1141ed1b3e4528595acc90772bdf2d37dc8a47130b44f33a02e8730e5ad8e166e888"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "ce741ac5930fe346811175c5227bb7bfcd47f42612fae46c0809514f9e0e3a11ee1773287147cdeaeedff50709aa716341fe65240f4ad6777d6bfaf9726e5e52"),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn",
			"ecd6fbbe1c86782edf2a00d008787f8ef3afb5fd6e9f93a1c9ec121feb3aca3935c64f57b75e73e2b3754c10d4cc5638e32a3dfc55cf259a7e57ad3222ff70f3"),
		("'Life is too short to run proprietary software' - Bdale Garbee", "62d6301236854494d2303c4cf35e56a26b00eedeb603cc975bbcb8208cfb8ca5b13ffe5ff7d38beffe2a75aad5386eac1b3f3896fe4ba4bee70abbc4523f1808"),
		("'The central enemy of reliability is complexity.' - Geer et al", "855016890590a1e470d01154fcd4acd23ba4a64699a1ef0375c2b6227c6a928768589788316e8eb6008811027ffde1f6ce16bd6ad7f002888fbf45461a2e1a12"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		let blake = blake2b([], 64);
		defer hash::close(&blake);
		hash::write(&blake, strings::toutf8(vector.0));

		static let sum: [64]u8 = [0...];
		assert(len(sum) >= hash::sz(&blake));
		hash::sum(&blake, sum);

		let hex = memio::dynamic();
		defer io::close(&hex)!;

		for (let j = 0z; j < len(sum); j += 1) {
			fmt::fprintf(&hex, "{:.2x}", sum[j])!;
		};

		if (memio::string(&hex)! != vector.1) {
			fmt::errorfln("Vector {}: {} != {}",
				i, memio::string(&hex)!, vector.1)!;
			abort();
		};
	};
};

@test fn blake2b_multiple_writes() void = {
	let in: [_]u8 = [
		0x20, 0x00, 0x00, 0x00, 0x75, 0x96, 0xf8, 0xa3, 0x2f, 0xb7,
		0xcf, 0x12, 0x83, 0x05, 0x0f, 0xbd, 0x4b, 0x48, 0x97, 0x70,
		0xe1, 0x67, 0x90, 0x1d, 0xc2, 0x02, 0x63, 0x31, 0x48, 0x2c,
		0xda, 0xdc, 0xf4, 0x37, 0x3b, 0xa1, 0x33, 0x10, 0xb8, 0xb9,
		0x91, 0x1e, 0xc5, 0xc8, 0xb7, 0x45, 0xcc, 0x3c, 0x45, 0x26,
		0xf4, 0x95, 0xf1, 0x79, 0x1b, 0x0b, 0xe4, 0x5f, 0xed, 0xdf,
		0x5e, 0xbf, 0x61, 0xef, 0xa6, 0x21, 0x12, 0x4b, 0x8a, 0x81,
		0x65, 0xe8, 0x92, 0x3d, 0xe4, 0x99, 0x66, 0x76, 0x4e, 0x68,
		0x46, 0xfe, 0x22, 0x5b, 0xce, 0xce, 0x80, 0x86, 0x72, 0xa5,
		0x0d, 0x23, 0x45, 0xd3, 0x27, 0x42, 0x4b, 0xf7, 0x34, 0x31,
		0xd5, 0x17, 0x8d, 0x48, 0x87, 0x6a, 0x1b, 0x52, 0x32, 0xc8,
		0x86, 0x7b, 0x42, 0x57, 0xc7, 0xd0, 0xe1, 0x27, 0x79, 0x53,
		0xd6, 0xf6, 0xb1, 0xcb, 0x3f, 0x9b, 0xed, 0x28, 0xb4,
	];

	let expected: [_]u8 = [
		0xf8, 0x9a, 0x3a, 0x42, 0x54, 0x89, 0x3a, 0xe7, 0x48, 0xa7,
		0x76, 0xb8, 0x45, 0x1e, 0x15, 0x5c, 0x13, 0x56, 0x33, 0xac,
		0x23, 0x30, 0xb6, 0xb7, 0x74, 0xe7, 0x93, 0x7e, 0x29, 0xfa,
		0xcd, 0x3e,
	];

	let result: [32]u8 = [0...];

	let h = blake2b([], len(result));
	defer hash::close(&h);
	hash::write(&h, in[..4]);
	hash::write(&h, in[4..]);
	hash::sum(&h, result[..]);

	assert(bytes::equal(expected, result));
};
