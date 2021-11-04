use fmt;
use hash;
use strings;
use encoding::hex;

@test fn md5() void = {
	let md5 = md5();
	const vectors = [
		("", "d41d8cd98f00b204e9800998ecf8427e"),
		("abc", "900150983cd24fb0d6963f7d28e17f72"),
		("hello world", "5eb63bbbe01eeed093cb22bb8f5acdc3"),
		("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "8215ef0796a20bcaaae116d3876c664a"),
		("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "03dd8807a93175fb062dfb55dc7d359c"),
		("Hare is a cool language", "391601a424a3331251b7fbaaa073458d"),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn", "e0d32da5235e0375e887d5dbff3bf44b"),
		("'Life is too short to run proprietary software' - Bdale Garbee", "09f9326df2fde54e53a15a6482c2bc26"),
		("'The central enemy of reliability is complexity.' - Geer et al", "839182c45d66fd79e8be1d9faacc1b00"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const vector = vectors[i];
		hash::reset(&md5);
		hash::write(&md5, strings::toutf8(vector.0));

		let sum: [SIZE]u8 = [0...];
		hash::sum(&md5, sum);

		let sumhex = hex::encodestr(sum);
		if (sumhex != vector.1) {
			fmt::errorfln("Vector {}: {} != {}", i, sumhex, vector.1)!;
			abort();
		};
	};
};
