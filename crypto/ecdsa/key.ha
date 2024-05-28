// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::ec;
use io;

// Invalid key.
export type invalidkey = !void;

export type pubkey = struct {
	curve: *ec::curve,
	get_q: *fn (pub: *pubkey) []u8,
};

export type privkey = struct {
	curve: *ec::curve,
	get_x: *fn (priv: *privkey) []u8,
};

export type p256privkey = struct {
	priv: privkey,
	x: [ec::P256_SCALARSZ]u8,
};

export type p384privkey = struct {
	priv: privkey,
	x: [ec::P384_SCALARSZ]u8,
};

export type p521privkey = struct {
	priv: privkey,
	x: [ec::P521_SCALARSZ]u8,
};

fn p256_get_x(priv: *privkey) []u8 = (priv: *p256privkey).x;
fn p384_get_x(priv: *privkey) []u8 = (priv: *p384privkey).x;
fn p521_get_x(priv: *privkey) []u8 = (priv: *p521privkey).x;

// Creates an unitialized p256 [[privkey]]. The curve is also known as secp256r1
// or prime256. The key must be initialized using [[newkey]].
export fn p256priv() p256privkey = p256privkey {
	priv = privkey {
		curve = ec::p256,
		get_x = &p256_get_x,
	},
	...
};

// Creates an unitialized p384 [[privkey]]. The curve is also known as
// secp384r1. The key must be initialized using [[newkey]].
export fn p384priv() p384privkey = p384privkey {
	priv = privkey {
		curve = ec::p384,
		get_x = &p384_get_x,
	},
	...
};

// Creates an unitialized p521 [[privkey]]. The curve is also known as
// secp521r1. The key must be initialized using [[newkey]].
export fn p521priv() p521privkey = p521privkey {
	priv = privkey {
		curve = ec::p521,
		get_x = &p521_get_x,
	},
	...
};


fn p256_get_q(pub: *pubkey) []u8 = (pub: *p256pubkey).q;
fn p384_get_q(pub: *pubkey) []u8 = (pub: *p384pubkey).q;
fn p521_get_q(pub: *pubkey) []u8 = (pub: *p521pubkey).q;

// Generates a key seeding from the 'rand' stream and stores it in 'priv'.
// 'rand' must be a cryptographic random generator like
// [[crypto::random::stream]].
export fn newkey(priv: *privkey, rand: io::handle) (void | io::error) = {
	ec::keygen(priv.curve, priv.get_x(priv), rand)?;
};

// Returns the buffer to the encoded key. See [[crypto::ec::curve]] on how the
// scalar must be encoded. The key must be valid, otherwise undefined behaviour
// may result. The function [[privkey_validate]] checks if the scalar is valid
// for given curve.
export fn privkey_buf(priv: *privkey) []u8 = priv.get_x(priv);

// Checks whether 'priv' is a valid private key.
export fn privkey_validate(priv: *privkey) (void | invalidkey) = {
	match (ec::validate_scalar(priv.curve, priv.get_x(priv))) {
	case void => void;
	case ec::invalid =>
		return invalidkey;
	};
};

export type p256pubkey = struct {
	pub: pubkey,
	q: [ec::P256_POINTSZ]u8,
};

export type p384pubkey = struct {
	pub: pubkey,
	q: [ec::P384_POINTSZ]u8,
};

export type p521pubkey = struct {
	pub: pubkey,
	q: [ec::P521_POINTSZ]u8,
};

// Creates an unitialized p256 [[pubkey]]. The curve is also known as secp256r1
// or prime256.
export fn p256pub() p256pubkey = p256pubkey {
	pub = pubkey {
		curve = ec::p256,
		get_q = &p256_get_q,
	},
	...
};

export fn p384pub() p384pubkey = p384pubkey {
	pub = pubkey {
		curve = ec::p384,
		get_q = &p384_get_q,
	},
	...
};

export fn p521pub() p521pubkey = p521pubkey {
	pub = pubkey {
		curve = ec::p521,
		get_q = &p521_get_q,
	},
	...
};

// Initializes the pubkey 'pub' from the coordinates 'x' and 'y' of a public
// point.
//
// Does not validate if the point is on curve. [[verify]] will fail, if such is
// the case.
export fn pubkey_init(pub: *pubkey, x: []u8, y: []u8) (void | invalidkey) = {
	const csz = pub.curve.pointsz / 2;
	if (len(x) > csz || len(y) > csz) {
		return invalidkey;
	};

	let q = pub.get_q(pub);
	q[..] = [0x04, 0x00...];

	const xoff = 1 + (csz - len(x));
	const yoff = 1 + xoff + (csz - len(y));

	q[xoff..xoff + len(x)] = x[..];
	q[yoff..] = y[..];
};

// Derives the public key from given 'priv' and stores it into 'pub'.
export fn pubkey_derive(pub: *pubkey, priv: *privkey) void = {
	assert(pub.curve == priv.curve);
	priv.curve.mulgen(pub.get_q(pub), priv.get_x(priv));
};

// Returns the buffer to the point stored in 'pub' to be able to store or read
// the point in encoded form. See [[crypto::ec::curve]] for how the point is
// and must be encoded.
export fn pubkey_buf(pub: *pubkey) []u8 = pub.get_q(pub);

// Validates if the pubkey is encoded properly. Does not check if the point is
// on curve. [[verify]] will fail, if the point is not on the curve.
export fn pubkey_validate_format(pub: *pubkey) (void | invalidkey) = {
	match (ec::validate_pointformat(pub.curve, pub.get_q(pub))) {
	case void => void;
	case ec::invalid =>
		return invalidkey;
	};
};

// Validates the key of 'pub' and checks whether the point is on the curve.
// This operation is expensive and is not strictly necessary, since this is
// done during [[verify]] also.
export fn pubkey_validate(pub: *pubkey) (void | invalidkey) = {
	match (ec::validate_point(pub.curve, pub.get_q(pub))) {
	case void => void;
	case ec::invalid =>
		return invalidkey;
	};
};
