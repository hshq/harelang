// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::hex;
use fmt;
use hash;
use strings;

@test fn sha512() void = {
	let sha = sha512();
	const vectors = [
		("abc", "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"),
		("", "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"),
		("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909"),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn",
			"f3d99b807bd734bcec25d64109ff5d78405d5b76a34332270c7062a4c9e6d1711ee6ed230e688fef257cf19e94e0163671c99f4c785d50e8adddef9f37060023"),
		("'Life is too short to run proprietary software' - Bdale Garbee", "b1eeae774232d4ba74410e7d951fc3e7de165dbc9498babb243e4a87983595a79f5970ed67ebf2e275059928b4f0309926f85dad45126875530e8d2350a93a2b"),
		("'The central enemy of reliability is complexity.' - Geer et al", "7eee0bc24a069679eb272aeb698136f8e3bca79b4220c70bf091607b78358fe4b3621a9e28295d73157806a20470a17cc21b9a3eefa7408c6cf1f288d1403a0d"),
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

@test fn sha512_224() void = {
	let sha = sha512_224();
	const vectors = [
		("", "6ed0dd02806fa89e25de060c19d3ac86cabb87d6a0ddd05c333b84f4"),
		("abc", "4634270f707b6a54daae7530460842e20e37ed265ceee9a43e8924aa"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "23fec5bb94d60b23308192640b0c453335d664734fe40e7268674af9")
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		hash::reset(&sha);
		hash::write(&sha, strings::toutf8(vector.0));

		let sum: [SZ224]u8 = [0...];
		hash::sum(&sha, sum);

		let shahex = hex::encodestr(sum);
		defer free(shahex);
		if (shahex != vector.1) {
			fmt::errorfln("Vector {}: {} != {}", i, shahex, vector.1)!;
			abort();
		};
	};
};

@test fn sha512_256() void = {
	let sha = sha512_256();
	const vectors = [
		("", "c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a"),
		("abc", "53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "3928e184fb8690f840da3988121d31be65cb9d3ef83ee6146feac861e19b563a"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		hash::reset(&sha);
		hash::write(&sha, strings::toutf8(vector.0));

		let sum: [SZ256]u8 = [0...];
		hash::sum(&sha, sum);

		let shahex = hex::encodestr(sum);
		defer free(shahex);
		if (shahex != vector.1) {
			fmt::errorfln("Vector {}: {} != {}", i, shahex, vector.1)!;
			abort();
		};
	};

};

@test fn sha384() void = {
	let sha = sha384();
	const vectors = [
		("", "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"),
		("abc", "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		hash::reset(&sha);
		hash::write(&sha, strings::toutf8(vector.0));

		let sum: [SZ384]u8 = [0...];
		hash::sum(&sha, sum);

		let shahex = hex::encodestr(sum);
		defer free(shahex);
		if (shahex != vector.1) {
			fmt::errorfln("Vector {}: {} != {}", i, shahex, vector.1)!;
			abort();
		};
	};
};
