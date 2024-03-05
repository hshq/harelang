// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::hex;
use fmt;
use hash;
use os;
use strings;
use test;

@test fn sha256() void = {
	let sha = sha256();
	const vectors = [
		("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
		("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
		("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1"),
		("hello world", "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"),
		("Hare is a cool language", "3f6fe31611580448e33af475ce0e66c7d55a156c6ec43c794225cc3084e04635"),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn", "5cfa9eccaafa0a7d9d965e36b0a54cc1dd97dd1dff7e11d5e631bdea7f2ef328"),
		("'Life is too short to run proprietary software' - Bdale Garbee", "79ecc26605c1fa5156821c5da9ebc959d8a46050ee49f47da57bf9391a558ceb"),
		("'The central enemy of reliability is complexity.' - Geer et al", "80b2fd9ae9e9c2ccd801c923f5e3684d56c6b05edc2eb480634b0af10f9c810b"),
		("'A language that doesn’t have everything is actually easier to program in than some that do.' - Dennis Ritchie", "10ebb04c1ddd55528d0c8db05a1f5fad6c04ebc20cfc4a53308f9a05a90cc438"),
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

@test fn sha256_1gb() void = {
	test::require("slow");

	let sha = sha256();
	const input = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmno";
	const expected = "50e72a0e26442fe2552dc3938ac58658228c0cbfb1d2ca872ae435266fcd055e";
	hash::reset(&sha);
	for (let i = 0z; i < 16777216; i += 1) {
		hash::write(&sha, strings::toutf8(input));
	};
	let sum: [SZ]u8 = [0...];
	hash::sum(&sha, sum);

	let shahex = hex::encodestr(sum);
	if (shahex != expected) {
		fmt::errorfln("Biggo vector: {} != {}", shahex, expected)!;
		abort();
	};
};
