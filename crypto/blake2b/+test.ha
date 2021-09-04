use encoding::hex;
use fmt;
use hash;
use io;
use strings;
use strio;

@test fn blake2b() void = {
	for (let i = 0z; i < len(vectors); i += 1) {
		let key = hex::decode(vectors[i].key)!;
		defer free(key);
		let out = hex::decode(vectors[i].out)!;
		defer free(out);
		let in = hex::decode(vectors[i].in)!;
		defer free(in);
		let blake = blake2b(key, len(out));
		hash::write(&blake, in);
		let sum: []u8 = alloc([], len(out));
		defer free(sum);
		for (let i = 0z; i < len(out); i += 1) {
			append(sum, 0);
		};
		hash::finish(&blake, sum);
		let out = strio::dynamic();
		hex::encode(out, sum)!;
		assert(strio::string(out) == vectors[i].out);
	};

	let blake = blake2b([], 64);
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
		hash::reset(&blake);
		hash::write(&blake, strings::toutf8(vector.0));

		static let sum: [64]u8 = [0...];
		assert(len(sum) >= hash::sz(&blake));
		hash::sum(&blake, sum);

		let hex = strio::dynamic();
		defer io::close(hex);

		for (let j = 0z; j < len(sum); j += 1) {
			fmt::fprintf(hex, "{:02x}", sum[j])!;
		};

		if (strio::string(hex) != vector.1) {
			fmt::errorfln("Vector {}: {} != {}",
				i, strio::string(hex), vector.1)!;
			abort();
		};
	};
};
