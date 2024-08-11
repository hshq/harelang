// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use errors;
use hash;
use io;
use types;

export type default = void;

// Required minimum buffer size for [[pss_verify]]
export def PSS_VERIFYBUFSZ = PUBEXP_BUFSZ + ((BITSZ + 7) / 8);

// Required minimum buffer size for [[pss_sign]]
export def PSS_SIGNBUFSZ = PRIVEXP_BUFSZ;

// Signs the hash 'msghash' using the private key 'privkey' by applying the PSS
// signature scheme as defined in RFC 8017. 'sig' must be in the the size of the
// modulus n (see [[privkey_nsize]])
//
// It is recommended that 'hf' is the same hash function that was used to
// generate 'msgmhash'. 'buf' needs to be at least the size of
// [[PSS_SIGNBUFSZ]]. 'rand' must be an [[io::reader]] that returns a
// cryptographiclly random data on read like [[crypto::random::stream]]. The
// expected size of the salt is provided with 'saltsz'. Default is the maximum
// possible salt size.
//
// Returns [[errors::invalid]], if one of the parameters are invalid.
// [[errors::overflow]] is returned, if 'buf' is to small. Errors that occur by
// reading from 'rand' are returned as [[io::error]].
export fn pss_sign(
	privkey: []u8,
	msghash: []u8,
	sig: []u8,
	hf: *hash::hash,
	rand: io::handle,
	buf: []u8,
	saltsz: (size | default) = default,
) (void | error | io::error) = {
	let priv = privkey_params(privkey);

	// Use var names that match the rfc.
	let embits = priv.nbitlen - 1;
	if (len(sig) != (embits + 7) / 8) {
		return errors::invalid: error;
	};
	let em = sig;
	let hlen = len(msghash);
	let emlen = len(em);
	const slen = dsaltsz(len(sig), hlen, saltsz);

	if (emlen < hlen + slen + 2) {
		return errors::invalid: error;
	};

	let db = em[..emlen - hlen - 1];
	db[..] = [0...];
	db[len(db) - slen - 1] = 0x01;
	let salt = db[len(db) - slen..];
	io::readall(rand, salt)?;

	let h = em[emlen - hlen - 1..emlen - 1];
	const padding: [8]u8 = [0...];
	hash::reset(hf);
	hash::write(hf, padding);
	hash::write(hf, msghash);
	hash::write(hf, salt);
	hash::sum(hf, h);

	mgfxor(db, hf, h, buf);

	em[0] &= 0xff >> (8*emlen - embits): u8;
	em[len(db)..emlen - 1] = h[..];
	em[emlen - 1] = 0xbc;

	privexp(&priv, em, buf)?;
};

fn dsaltsz(nsz: size, hsz: size, s: (size | default)) size = {
	match (s) {
	case let s: size =>
		return s;
	case default =>
		return nsz - hsz - 2;
	};
};

// Verifies a PSS signature 'sig' of the mesage hash 'msghash' using the public
// key 'pupkey' as defined in RFC 8017.
//
// 'hf' must be the hash that was used to create the signature. 'buf' needs to
// be at least the size of [[PSS_VERIFYBUFSZ]]. The expected size of the salt is
// provided with 'saltsz'. Default is the maximum possible salt size. The
// function will fail, if the signature's salt size does not match the expected.
//
// Returns [[badsig]], if the signature verification fails. [[errors::overflow]]
// is returned, if 'buf' is to small.
export fn pss_verify(
	pubkey: []u8,
	msghash: []u8,
	sig: []u8,
	hf: *hash::hash,
	buf: []u8,
	saltsz: (size | default) = default,
) (void | error) = {
	let pub = pubkey_params(pubkey);
	if (len(sig) != len(pub.n)) {
		return badsig;
	};

	// rename some variables to match the ones in the RFC
	let mhash = msghash;
	const hlen = hash::sz(hf);
	const slen = dsaltsz(len(pub.n), hlen, saltsz);
	let em = buf[..len(sig)];
	const emlen = len(em);
	em[..] = sig[..];

	if (emlen < hlen + slen + 2) {
		return badsig;
	};

	let pubbuf = buf[len(sig)..];
	match (pubexp(&pub, em, pubbuf)) {
	case void => void;
	case errors::invalid =>
		return badsig;
	case let e: error =>
		return e;
	};

	if (em[emlen - 1] != 0xbc) {
		return badsig;
	};

	const maskdbsz = emlen - hlen - 1;
	let maskeddb = em[..maskdbsz];
	let h = em[maskdbsz..maskdbsz + hlen];

	const embitlen = pubkey_nbitlen(pubkey) - 1;
	const zerobitsh = 8 - (8*len(em) - embitlen);
	if (maskeddb[0] >> zerobitsh != 0) {
		return badsig;
	};

	let db = maskeddb;
	mgfxor(db, hf, h, pubbuf);
	db[0] &= 0xff >> (8*len(em) - embitlen): u8;

	const seppos = len(em) - hlen - slen - 2;
	for (let i = 0z; i < seppos; i += 1) {
		if (db[i] != 0x00) {
			return badsig;
		};
	};
	if (db[seppos] != 0x01) {
		return badsig;
	};

	const salt = db[len(db) - slen..];
	const padding: [8]u8 = [0...];
	hash::reset(hf);
	hash::write(hf, padding);
	hash::write(hf, mhash);
	hash::write(hf, salt);

	let genh = pubbuf[..hlen];
	hash::sum(hf, genh);

	if (math::eqslice(genh, h) != 1) {
		return badsig;
	};
};

// dest = dest XOR mgf(h, seed, len(dest)). 'buf' must be hash::sz(h) bytes
// long.
fn mgfxor(dest: []u8, h: *hash::hash, seed: []u8, buf: []u8) void = {
	assert(len(buf) >= hash::sz(h));

	let ctrbuf: [4]u8 = [0...];
	let sum = buf[..hash::sz(h)];
	const iterations = (len(dest) + len(sum) - 1) / len(sum);

	for (let ctr: u32 = 0; ctr < iterations; ctr += 1) {
		endian::beputu32(ctrbuf, ctr);
		hash::reset(h);
		hash::write(h, seed);
		hash::write(h, ctrbuf);
		hash::sum(h, sum);

		const start = ctr * len(sum);
		const remain = len(dest) - start;
		const chunksz = if (remain < len(sum)) remain else len(sum);

		let chunk = dest[start..start + chunksz];
		math::xor(chunk, chunk, sum[..chunksz]);
	};

	bytes::zero(sum);
};
