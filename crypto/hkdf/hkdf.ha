// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::hmac;
use crypto::mac;
use hash;

// Calls [[extract]] and [[expand]] to derive a single key from specified 'key'
// material using HMAC with 'h' as underlying hash function and writes it to
// 'dest'. The resulting key size is of the size of 'dest'.
//
// 'info' binds the resulting key to the context in where it is being used and
// therefore prevents the derivation of the same key for different contexts. It
// should be independent of the input key. 'salt' does not need to be secret and
// it's recommended to use a random or pseudo random value, ideally of the hash
// size of the given hash function. The 'salt' must be a fixed value or void
// between many different contexts.
//
// 'buf' must be of the size [[hash::bsz]] + [[hash::sz]] of given hash 'h'.
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

	extract(h, prk, key, salt, buf);
	// use prk as buffer for the last block operation since it's not
	// required for future expanding.
	iexpand(h, dest, prk, info, buf, prk);

	// buf is zeroed in expand
};

// Extracts a pseudo random key (prk) from given 'key' and 'salt' and writes it
// to 'prk' using HMAC of given hash function 'h'. 'prk' must be the size of
// [[hash::sz]] of given hash. The resulting 'prk' can be used to derive keys
// using the [[expand]] function.
//
// 'salt' does not need to be secret and it's recommended to use a random or
// pseudo random value, ideally of the hash size of the given hash function.
// 'buf' must be of the size [[hash::bsz]] of given hash.
export fn extract(
	h: *hash::hash,
	prk: []u8,
	key: []u8,
	salt: ([]u8 | void),
	buf: []u8
) void = {
	const hashsz = hash::sz(h);
	assert(len(buf) >= hash::bsz(h),
		"len(buf) must be at least `hash::bsz(h)`");
	assert(len(prk) == hash::sz(h), "prk must be of hash::sz(h)");

	let prkkey = match(salt) {
	case let s: []u8 =>
		yield s;
	case void =>
		bytes::zero(prk);
		yield prk;
	};

	let hm = hmac::hmac(h, prkkey, buf);
	mac::write(&hm, key);
	mac::sum(&hm, prk);
	mac::finish(&hm);

	// buf is zeroed in mac::finish
};

// Derives a new key form 'prk' using HMAC of given hash function 'h' and stores
// it into 'dest'. 'prk' must be created using [[extract]]. 'info' binds the
// resulting key to the context in where it is being used and therefore prevents
// the derivation of the same key for different contexts. 'buf' must be at least
// of the size [[hash::sz]] + [[hash::bsz]] of given hash function 'h'. The same
// hash function that was used at the [[extract]] step must also be used in
// [[expand]].
export fn expand(
	h: *hash::hash,
	dest: []u8,
	prk: []u8,
	info: []u8,
	buf: []u8,
) void = {
	assert(len(buf) >= (hash::bsz(h) + hash::sz(h)),
		"len(buf) must be at least `hash::bsz(h)`");

	const hashsz = hash::sz(h);
	iexpand(h, dest, prk, info, buf[hashsz..], buf[..hashsz]);
};

// Internal [[expand]] function that allows to specify separately 'hashbuf',
// the buffer for the last block operation.
fn iexpand(
	h: *hash::hash,
	dest: []u8,
	prk: []u8,
	info: []u8,
	buf: []u8,
	hashbuf: []u8,
) void = {
	const hashsz = hash::sz(h);

	// to avoid ctr overflows
	assert((len(dest) + hashsz - 1) / hashsz < 255,
		"'dest' exceeds maximum allowed size");

	let ctr: [1]u8 = [0];
	let preblock: []u8 = [];

	defer bytes::zero(hashbuf);
	// buf is zeroed during mac::finish

	for (let i = 0u8; len(dest) > 0; i += 1) {
		hash::reset(h);
		let hm = hmac::hmac(h, prk, buf);
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
			mac::sum(&hm, hashbuf);
			dest[..] = hashbuf[..len(dest)];
			yield len(dest);
		};

		dest = dest[n..];
	};
};
