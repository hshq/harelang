// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use crypto::math;
use crypto::sha1;
use crypto::sha256;
use crypto::sha512;
use errors;
use hash;
use io;

// Supported hash algorithms for [[pkcs1_sign]] and [[pkcs1_verify]].
export type pkcs1_hashalgo = enum {
	SHA1,
	// SHA224, We don't have this one yet
	SHA256,
	SHA384,
	SHA512,
	SHA512_224,
	SHA512_256,
};

const OID_SHA1: [_]u8 = [
	0x30,  0x21,  0x30,  0x09,  0x06,  0x05,  0x2b,  0x0e,  0x03,  0x02,
	0x1a,  0x05,  0x00,  0x04,  0x14,
];

const OID_SHA224: [_]u8 = [
	0x30,  0x2d,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x04,  0x05,  0x00,  0x04,  0x1c,
];

const OID_SHA256: [_]u8 = [
	0x30,  0x31,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x01,  0x05,  0x00,  0x04,  0x20,
];

const OID_SHA384: [_]u8 = [
	0x30,  0x41,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x02,  0x05,  0x00,  0x04,  0x30,
];

const OID_SHA512: [_]u8 = [
	0x30,  0x51,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x03,  0x05,  0x00,  0x04,  0x40,
];

const OID_SHA512_224: [_]u8 = [
	0x30,  0x2d,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x05,  0x05,  0x00,  0x04,  0x1c,
];

const OID_SHA512_256: [_]u8 = [
	0x30,  0x31,  0x30,  0x0d,  0x06,  0x09,  0x60,  0x86,  0x48,  0x01,
	0x65,  0x03,  0x04,  0x02,  0x06,  0x05,  0x00,  0x04,  0x20,
];

// Required buffer size for [[pkcs1_verify]].
export def PKCS1_VERIFYBUFSZ: size = PUBEXP_BUFSZ + (BITSZ / 8);

// Verifies a PKCS#1 v1.5 signature given a public key 'pubkey', the message
// hash 'msghash', the signature 'sig' and the hash algorithm 'algo'. 'algo'
// must reflect the hash algorithm 'sig' was created with.
//
// A temporary buffer 'buf' of size [[PKCS1_VERIFYBUFSZ]] must be provided.
export fn pkcs1_verify(
	pubkey: []u8,
	msghash: []u8,
	sig: []u8,
	algo: pkcs1_hashalgo,
	buf: []u8
) (void | error) = {
	let pub = pubkey_params(pubkey);

	let actualsig = buf[..len(sig)];
	let pubbuf = buf[len(sig)..];

	actualsig[..] = sig[..];
	match (pubexp(&pub, actualsig, pubbuf)) {
	case let e: error =>
		return e;
	case void => void;
	};

	let expectedsig = pubbuf[..len(sig)];
	pkcs1_sig_encode(expectedsig, msghash, algo)?;

	if (math::eqslice(expectedsig, actualsig) == 0) {
		return badsig;
	};
};

// Required buffer size for [[pkcs1_sign]].
export def PKCS1_SIGNBUFSZ: size = PRIVEXP_BUFSZ;

// Signs a message hash 'msghash' using the PKCS#1 V1.5 signature scheme. The
// signature will be written to 'sig' which must be in the the size of the
// modulus n (see [[privkey_nsize]]). 'algo' defines the hash algorithm
// 'msghash' was created with.
//
// A temporary buffer 'buf' of size [[PKCS1_SIGNBUFSZ]]  must be provided.
export fn pkcs1_sign(
	priv: []u8,
	msghash: []u8,
	sig: []u8,
	algo: pkcs1_hashalgo,
	buf: []u8
) (void | error) = {
	let priv = privkey_params(priv);
	pkcs1_sig_encode(sig, msghash, algo)?;
	privexp(&priv, sig, buf)?;
};

// Returns hash id and hash size for given 'algo'.
fn pkcs1_hashinfo(algo: pkcs1_hashalgo) (const []u8, size) = {
	switch (algo) {
	case pkcs1_hashalgo::SHA1 =>
		return (OID_SHA1, sha1::SZ);
	case pkcs1_hashalgo::SHA256 =>
		return (OID_SHA256, sha256::SZ);
	case pkcs1_hashalgo::SHA384 =>
		return (OID_SHA384, sha512::SZ384);
	case pkcs1_hashalgo::SHA512 =>
		return (OID_SHA512, sha512::SZ);
	case pkcs1_hashalgo::SHA512_224 =>
		return (OID_SHA512_224, sha512::SZ224);
	case pkcs1_hashalgo::SHA512_256 =>
		return (OID_SHA512_256, sha512::SZ256);
	case =>
		abort("unreachable");
	};
};

// Creates an unauthenticated signature of 'msg' and writes it into 'sig' using
// given hash algorithm 'algo'.
fn pkcs1_sig_encode(
	sig: []u8,
	msghash: []u8,
	algo: pkcs1_hashalgo
) (void | error) = {
	let (hid, hsz) = pkcs1_hashinfo(algo);
	if (len(msghash) != hsz) {
		return errors::invalid;
	};

	let tlen = len(hid) + hsz;
	if (len(sig) < tlen + 11) {
		return badsig;
	};

	const hsep = len(sig) - tlen - 1;

	sig[..2] = [0x00, 0x01];
	for (let i = 2z; i < hsep; i += 1) {
		sig[i] = 0xff;
	};
	sig[hsep] = 0x00;
	sig[hsep + 1..len(sig) - hsz] = hid[..];
	sig[len(sig) - hsz..] = msghash[..];
};
