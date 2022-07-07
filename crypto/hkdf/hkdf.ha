// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use bytes;
use crypto::hmac;
use crypto::mac;
use hash;

// Derives a new key from specified 'key' material using HMAC with 'h' as
// underlying hash function and writes it to 'dest'. The resulting key size is
// of the size of 'dest'.
// 
// 'info' binds the resulting key to the context in where it is being used and
// therefore prevents the derivation of the same key for different contexts. It
// should be independent of the input key. 'salt' does not need to be secret and
// it's recommended to use a random or pseudo random value, ideally of the hash
// size of the given hash function. The 'salt' must be a fixed value or void
// between many different contexts.
//
// 'buf' must be of the size [[hash::bsz]] + [[hash::sz]] of given hash 'h'.
//
// See the RFC 5869 for detailed usage guidance.
export fn hkdf(
	h: *hash::hash,
	dest: []u8,
	key: []u8,
	info: []u8,
	salt: ([]u8 | void),
	buf: []u8,
) void = {
	const hashsz = hash::sz(h);
	assert(len(buf) >= (hash::sz(h) + hash::bsz(h)),
		"len(buf) must be at least `hash::sz(h) + hash::bsz(h)`");

	let prk = buf[..hashsz];
	let buf = buf[hashsz..];

	let prkkey = match(salt) {
	case let s: []u8 =>
		yield s;
	case void =>
		// use prk for an hashsz full of zeros
		bytes::zero(prk);
		yield prk;
	};

	let hm = hmac::hmac(h, prkkey, buf);

	mac::write(&hm, key);
	mac::sum(&hm, prk);
	mac::finish(&hm);

	let ctr: [1]u8 = [0];
	let preblock: []u8 = [];

	for (let i = 0u8; len(dest) > 0; i += 1) {
		hash::reset(h);
		hm = hmac::hmac(h, prk, buf);
		defer mac::finish(&hm);

		if (i > 0) {
			mac::write(&hm, preblock);
		};
		mac::write(&hm, info);

		ctr[0] = i + 1;
		mac::write(&hm, ctr);

		const n = if (len(dest) >= hashsz) {
			mac::sum(&hm, dest[..hashsz]);
			preblock = dest[..hashsz];
			yield hashsz;
		} else {
			// use the prk as buffer for the last block as it's
			// not needed anymore afterwards.
			mac::sum(&hm, prk);
			dest[..] = prk[..len(dest)];
			yield len(dest);
		};

		dest = dest[n..];
	};

	bytes::zero(prk);
	bytes::zero(buf);
};
