// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::ec;
use crypto::random;
use io;


// Size of the shared secret in bytes when using p256 curves.
export def P256_SHAREDSZ = ec::P256_POINTSZ / 2;

// Size of the shared secret in bytes when using p384 curves.
export def P384_SHAREDSZ = ec::P384_POINTSZ / 2;

// Size of the shared secret in bytes when using p521 curves.
export def P521_SHAREDSZ = ec::P521_POINTSZ / 2;

// Key is either not of expected size or is not a valid point on given curve.
export type invalidkey = !void;

export type privkey = struct {
	curve: *ec::curve,
	get_x: *fn (priv: *privkey) []u8,
};

fn p256_get_x(priv: *privkey) []u8 = (priv: *p256key).x;
fn p384_get_x(priv: *privkey) []u8 = (priv: *p384key).x;
fn p521_get_x(priv: *privkey) []u8 = (priv: *p521key).x;

export type p256key = struct {
	priv: privkey,
	x: [ec::P256_SCALARSZ]u8,
};

export type p384key = struct {
	priv: privkey,
	x: [ec::P384_SCALARSZ]u8,
};

export type p521key = struct {
	priv: privkey,
	x: [ec::P521_SCALARSZ]u8,
};

// Creates an unitialized p256 key. The curve is also known as secp256r1 or
// prime256. The key must be initialized using [[newkey]].
export fn p256() p256key = p256key {
	priv = privkey {
		curve = ec::p256,
		get_x = &p256_get_x,
	},
	...
};

// Creates an unitialized p384 key. The curve is also known as secp384r1. The
// key must be initialized using [[newkey]].
export fn p384() p384key = p384key {
	priv = privkey {
		curve = ec::p384,
		get_x = &p384_get_x,
	},
	...
};

// Creates an unitialized p521 key. The curve is also known as secp521r1. The
// key must be initialized using [[newkey]].
export fn p521() p521key = p521key {
	priv = privkey {
		curve = ec::p521,
		get_x = &p521_get_x,
	},
	...
};

// Generates a key seeding from the 'rand' stream and stores it in 'priv'.
// 'rand' must be a cryptographic random generator like
// [[crypto::random::stream]].
export fn newkey(priv: *privkey, rand: io::handle) (void | io::error) =
	ec::keygen(priv.curve, priv.get_x(priv), rand)?;

// Derives the public key from given 'priv' and stores it into 'pub'. Returns
// the number of key bytes written to 'pub'.
export fn pubkey(pub: []u8, priv: *privkey) size =
	priv.curve.mulgen(pub, priv.get_x(priv));

// Derives a shared secret with the private key 'priv' and the peer's public
// key 'pub' and stores it in 'shared'.
export fn derive(
	shared: []u8,
	priv: *privkey,
	pub: []u8
) (size | invalidkey)  = {
	match (ec::validate_pointformat(priv.curve, pub)) {
	case ec::invalid =>
		return invalidkey;
	case void => void;
	};

	let buf: [ec::MAX_POINTSZ]u8 = [0...];
	let buf = buf[..len(pub)];
	buf[..] = pub[..];

	if (priv.curve.mul(buf, priv.get_x(priv)) == 0) {
		return invalidkey;
	};

	const csz = priv.curve.pointsz / 2;
	shared[..] = buf[1..csz + 1];
	bytes::zero(buf);
	return csz;
};
