// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::hex;
use fmt;
use hash;
use os;
use strings;
use test;

@test fn sha1() void = {
	let sha = sha1();
	const vectors = [
		("", "da39a3ee5e6b4b0d3255bfef95601890afd80709"),
		("abc", "a9993e364706816aba3e25717850c26c9cd0d89d"),
		("hello world", "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"),
		("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "84983e441c3bd26ebaae4aa1f95129e5e54670f1"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "a49b2446a02c645bf419f995b67091253a04a259"),
		// From Pro Git Chapter 10.2
		// https://git-scm.com/book/en/v2/Git-Internals-Git-Objects#_object_storage
		// output of: echo -n 'what is up, doc?' | git hash-object --stdin
		("blob 16\0what is up, doc?", "bd9dbf5aae1a3862dd1526723246b20206e5fc37"),
		("Hare is a cool language", "947feae3d0d65cc083c8f3e87858206e36aae908"),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn", "05c8dd2605161bdd0b5d70f1f225f4dd69a01e3b"),
		("'Life is too short to run proprietary software' - Bdale Garbee", "91ad4bdc2fbe2b731cbe8bf2958099391c7af3b8"),
		("'The central enemy of reliability is complexity.' - Geer et al", "4b6eb2aa55ef59cc59be6d181c64141e7c1e5eab"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		hash::reset(&sha);
		hash::write(&sha, strings::toutf8(vector.0));

		let sum: [SZ]u8 = [0...];
		hash::sum(&sha, sum);

		let shahex = hex::encodestr(sum);
		defer free(shahex);
		if (shahex != vector.1) {
			fmt::errorfln("Vector {}: {} != {}", i, shahex, vector.1)!;
			abort();
		};
	};
};

@test fn sha1_1gb() void = {
	test::require("slow");

	const input = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmno";
	const expected = "7789f0c9ef7bfc40d93311143dfbe69e2017f592";

	let sha = sha1();

	for (let i = 0z; i < 16777216; i += 1)
		hash::write(&sha, strings::toutf8(input));

	let sum: [SZ]u8 = [0...];
	hash::sum(&sha, sum);

	let shahex = hex::encodestr(sum);

	if (shahex != expected) {
		fmt::errorfln("1GB vector: {} != {}", shahex, expected)!;
		abort();
	};
};
