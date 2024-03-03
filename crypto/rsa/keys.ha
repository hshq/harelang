// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::bigint;
use crypto::math::*;
use endian;
use errors;
use io;
use memio;
use types;

// The default bit size of RSA keys is 4096-bit. Used as base for buffer sizes.
export def BITSZ: size = 4096;

// The minimum bit size of RSA keys used only for validation during key init.
// The default value is 1024-bit.
export def MINBITSZ: size = 1024;

// RSA key parameters for initializing public keys with [[pubkey_init]].
export type pubparams = struct {
	// Modulus in big-endian order
	n: []u8,

	// Public exponent in big-endian order
	e: []u8,
};

// RSA key parameters for initializing private keys with [[privkey_init]]. If
// the private exponent d is available, [[privkey_initd]] may be used, which
// derives 'dp' and 'dq'. All big integer values are in big-endian order.
export type privparams = struct {
	// Bit length of the modulus n. If unknown, the modulus can be provided
	// to the init function, which derivces the length.
	nbitlen: size,

	// First prime factor.
	p: []u8,

	// Second prime factor
	q: []u8,

	// First exponent. dp = d mod (p - 1) where d is the private exponent.
	// May be omitted on [[privkey_initd]].
	dp: []u8,

	// Second exponent. dq = d mod (q - 1) where d is the private exponent.
	// May be omitted on [[privkey_initd]].
	dq: []u8,

	// Coefficient. iq = q^-1 mod p.
	iq: []u8,
};

// Size required to store a public key of [[BITSZ]] length.
export def PUBKEYSZ: size = 5 + 2 * (BITSZ >> 3);

// Initializes a public key from given [[pubparams]] 'x'. The data format
// of 'pubkey' is subject to change and must not be used to serialize the key.
// [[PUBKEYSZ]] defines the required size to store a key of [[BITSZ]].
//
// If given key does not fit into 'pubkey' or is too small, [[errors::overflow]]
// is returned. Returns [[errors::invalid]], if given key parameters are
// invalid. Returns the number of bytes written to 'pubkey' on success.
export fn pubkey_init(pubkey: []u8, x: pubparams) (size | error) = {
	let e = ltrim(x.e);
	let n = ltrim(x.n);

	if (len(pubkey) < pubkey_len(n, e) || len(n) > types::U16_MAX
			|| len(e) > types::U16_MAX) {
		return errors::overflow;
	};

	// Very basic key checks that only catch obvious errors.
	if ((len(e) == 1 && e[0] == 1) || len(e) > len(n)) {
		return errors::invalid;
	};
	if (bitlen(n) < MINBITSZ) {
		return errors::invalid;
	};

	let w = memio::fixed(pubkey);

	let s = 0z;
	s += writeslice(&w, e)!;
	s += writeslice(&w, n)!;
	return s;
};

// Returns the length of the modulus 'n' of given public key.
export fn pubkey_nbitlen(pubkey: []u8) size = {
	let p = pubkey_params(pubkey);
	return bitlen(p.n);
};

// Returns the length the public key would require in its encoded form.
fn pubkey_len(n: []u8, e: []u8) size = 1z + 2 + len(n) + 2 + len(e);

// Returns the slice without preceeding zeroes.
fn ltrim(s: []u8) []u8 = {
	for (len(s) > 0 && s[0] == 0) {
		s = s[1..];
	};
	return s;
};

fn writeslice(dest: io::handle, a: []u8) (size | io::error) = {
	let lenbuf: [2]u8 = [0...];
	endian::beputu16(lenbuf, len(a): u16);
	let s = io::write(dest, lenbuf)?;
	s += io::write(dest, a)?;
	return s;
};

// Counts the bits for given slice 'n'.
fn bitlen(s: []u8) size = {
	for (s[0] == 0) {
		s = s[1..];
	};

	return countbits(s[0]) + 8 * (len(s) - 1);
};

fn countbits(x: u8) size = {
	let k: u32 = nequ32(x, 0);
	let c: u32 = 0;

	c = gtu32(x, 0x0f);
	x = muxu32(c, x >> 4, x): u8;
	k += c << 2;

	c = gtu32(x, 0x03);
	x = muxu32(c, x >> 2, x): u8;
	k += c << 1;

	k += gtu32(x, 0x01);

	return k;
};

@test fn countbits() void = {
	assert(countbits(0xf0) == 8);
	assert(countbits(0x70) == 7);
	assert(countbits(0x30) == 6);
	assert(countbits(0x10) == 5);
	assert(countbits(0x08) == 4);
	assert(countbits(0x04) == 3);
	assert(countbits(0x03) == 2);
	assert(countbits(0x01) == 1);
	assert(countbits(0x00) == 0);
};

// Returns the public key parameters, borrowed from given 'pubkey'.
export fn pubkey_params(pubkey: []u8) pubparams = {
	let keybuf = pubkey;
	return pubparams {
		e = nextslice(&keybuf),
		n = nextslice(&keybuf),
	};
};

fn nextslice(key: *[]u8) []u8 = {
	const l = endian::begetu16(key[..2]);
	let s = key[2..2 + l];
	*key = key[2 + l..];
	return s;
};

// Size required to store a private key of [[BITSZ]] length.
export def PRIVKEYSZ: size = 13 + (MAXFACTOR >> 3) * 5;

fn privkey_len(x: *privparams) size =
	13z + len(x.p) + len(x.q) + len(x.dp) + len(x.dq) + len(x.iq);

// Initializes the private key 'privkey' using the values from 'x'. 'nbitlen' of
// 'x' may be omitted, if the modulus 'n' is passed. All other values of 'x'
// must be present. If 'x' is missing 'dp' and 'dq' use [[privkey_initd]].
//
// In case of invalid parameters or if the key is too small, [[errors::invalid]]
// is returned. If the key does not fit 'privkey', [[errors::overflow]] is
// returned. On success the number of bytes written to 'privkey' is returned.
export fn privkey_init(privkey: []u8, x: privparams, n: []u8...) (size | error) = {
	privkey_normalize(privkey, &x)?;

	if (len(x.dp) == 0 || len(x.dq) == 0) {
		return errors::invalid;
	};

	let s = privkey_writehead(privkey, &x, n...)?;
	let w = memio::fixed(privkey[s..]);

	s += writeslice(&w, x.dp)!;
	s += writeslice(&w, x.dq)!;

	s += writeslice(&w, x.iq)!;
	s += writeslice(&w, x.p)!;
	s += writeslice(&w, x.q)!;
	return s;
};

// Trims key parameters and also does basic key checks.
fn privkey_normalize(privkey: []u8, x: *privparams) (void | error) = {
	x.p = ltrim(x.p);
	x.q = ltrim(x.q);
	x.dp = ltrim(x.dp);
	x.dq = ltrim(x.dq);
	x.iq = ltrim(x.iq);

	if (len(privkey) < privkey_len(x)
			|| len(x.p) > types::U16_MAX
			|| len(x.q) > types::U16_MAX
			|| len(x.dp) > types::U16_MAX
			|| len(x.dq) > types::U16_MAX
			|| len(x.iq) > types::U16_MAX) {
		return errors::overflow;
	};

	if (len(x.p) == 0 || len(x.q) == 0 || len(x.iq) == 0
			|| !isodd(x.p) || !isodd(x.q)) {
		return errors::invalid;
	};
};

fn isodd(x: []u8) bool = {
	assert(len(x) > 0);
	return x[len(x)-1] & 1 == 1;
};

fn privkey_writehead(
	privkey: []u8,
	p: *privparams,
	n: []u8...
) (size | error) = {
	assert(len(n) <= 1);
	const nbitlen = if (len(n) == 1) bitlen(n[0]) else p.nbitlen;
	if (nbitlen > types::U16_MAX) {
		return errors::overflow;
	};
	if (nbitlen < MINBITSZ) {
		return errors::invalid;
	};

	let w = memio::fixed(privkey);
	let lenbuf: [2]u8 = [0...];
	endian::beputu16(lenbuf, nbitlen: u16);
	return io::write(&w, lenbuf)!;
};

// Initializes the private key 'privkey' using the values from 'x' and the
// secret exponent 'd'. 'dp' and 'dq' will be derived from 'p' and 'q' of 'x'.
// 'nbitlen' of 'x' may be omitted, if the modulus 'n' is passed. 'x' must
// provide 'iq'.
//
// In case of invalid parameters or if the key is too small, [[errors::invalid]]
// is returned. If the key does not fit 'privkey', [[errors::overflow]] is
// returned. On success the number of bytes written to 'privkey' is returend.
export fn privkey_initd(
	privkey: []u8,
	x: privparams,
	d: []u8,
	n: []u8...
) (size | error) = {
	privkey_normalize(privkey, &x)?;

	let s = privkey_writehead(privkey, &x, n...)?;

	// the order is important. The dmod operation uses the space for the
	// remaining factors as buffer.
	s += privkey_dmod(privkey[s..], d, x.p);
	s += privkey_dmod(privkey[s..], d, x.q);

	let w = memio::fixed(privkey[s..]);
	s += writeslice(&w, x.iq)!;
	s += writeslice(&w, x.p)!;
	s += writeslice(&w, x.q)!;

	// zero out tail in case the privkey_dmod operation left buffered values
	bytes::zero(privkey[s..]);
	return s;
};

// Calculates 'x' = 'd' mod 'y' - 1 and stores 'x' into 'out' preceeding a
// u16 len. 'out' will also be used as a calculation buffer. 'y' must be odd.
fn privkey_dmod(out: []u8, d: []u8, y: []u8) size = {
	const encwordlen = bigint::encodelen(y);
	const enclen = encwordlen * size(bigint::word);
	const xlen = len(y);

	assert(len(out) >= 2 + xlen + 2 * enclen);
	assert(isodd(y));

	let buf = out[2 + xlen..];
	// XXX: this may be only done once for both dp and dq
	let by = (buf[..enclen]: *[*]bigint::word)[..encwordlen];
	bigint::encode(by, y);
	bigint::decrodd(by);

	let bx = (buf[enclen..2 * enclen]: *[*]bigint::word)[..encwordlen];
	bigint::encodereduce(bx, d, by);

	out[0] = (xlen >> 8): u8;
	out[1] = xlen: u8;
	bigint::decode(out[2..2 + xlen], bx);
	return 2 + xlen;
};

// Returns the private key parameters borrowed from 'privkey'.
export fn privkey_params(privkey: []u8) privparams = {
	let keybuf = privkey[2..];
	return privparams {
		nbitlen = privkey_nbitlen(privkey),
		dp = nextslice(&keybuf),
		dq = nextslice(&keybuf),
		iq = nextslice(&keybuf),
		p = nextslice(&keybuf),
		q = nextslice(&keybuf),
		...
	};
};

// Returns the length of the modulus 'n'.
export fn privkey_nbitlen(privkey: []u8) size = {
	return endian::begetu16(privkey[0..2]);
};

// Returns the number of bytes that are required to store a value modulo 'n'.
export fn privkey_nsize(privkey: []u8) size = {
	return (privkey_nbitlen(privkey) + 7) / 8;
};
