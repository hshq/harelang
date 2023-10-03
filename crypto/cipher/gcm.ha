// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math::{xor,eqslice};
use endian::{beputu64, beputu32, begetu32};
use errors;
use io;
use types;

def GCMBLOCKSZ: size = 16;

export def GCMTAGSZ: size = 16;

export type gcmstream = struct {
	stream: io::stream,
	block: nullable *block,
	handle: io::handle,
	tagbuf: [GCMBLOCKSZ]u8,
	xorbuf: [GCMBLOCKSZ]u8,
	cipherbuf: [GCMBLOCKSZ]u8,
	y0: [GCMBLOCKSZ]u8,
	h: [GCMBLOCKSZ]u8,
	y: u32,
	xorbufpos: size,
	adlen: u64,
	clen: u64,
};

const gcm_vtable: io::vtable = io::vtable {
	writer = &gcm_writer,
	reader = &gcm_reader,
	closer = &gcm_closer,
	...
};

// Creates a Galois Counter Mode (GCM) io::stream which can be used for
// encryption (by encrypting writes to the underlying handle) or decryption (or
// by decrypting reads from the underlying handle), but not both. [[gcm_init]]
// must be called to initialize the stream, before reading or writing. To
// authenticate the encrypted data an authentication tag must be created using
// [[gcm_seal]] after the encryption step. The authentication tag must be passed
// to [[gcm_verify]] after decryption to make sure that the encrypted and
// additional data were not modified. In case of a verification fail the
// decrypted data must not be trusted and hence discarded.
//
// A maximum of 2**36-32 bytes may be encrypted.
//
// The user must call [[io::close]] when they are done using the stream to
// securely erase secret information stored in the stream state. Close will
// also finish the 'block' provided by [[gcm_init]].
export fn gcm() gcmstream = {
	return gcmstream {
		stream = &gcm_vtable,
		handle = 0,
		...
	};
};

// Initialises the gcmstream. The data will be encrypted to or encrypted from
// the given 'handle' The implementation only supports a block cipher 'b' with a
// block size of 16 bytes. The initialization vector (nonce) 'iv' may have any
// size up to 2**61 bytes. 12 bytes is the recommended size, if efficiency is
// critical. The additional data 'ad' will be authenticated but not encrypted
// and may have a maximum length of 2**61 - 1 bytes. 'ad' will not be written to
// the underlying handle.
export fn gcm_init(
	s: *gcmstream,
	handle: io::handle,
	b: *block,
	iv: const []u8,
	ad: const []u8
) void = {
	assert(blocksz(b) == GCMBLOCKSZ);
	assert(len(iv): u64 <= (types::U64_MAX >> 3));

	s.handle = handle;
	s.block = b;
	s.adlen = len(ad);
	s.xorbufpos = GCMBLOCKSZ; // to force fill xorbuf at start

	encrypt(b, s.h, s.h);

	if (len(iv) == 12) {
		s.y0[..12] = iv[..];
		s.y0[15] |= 1;
	} else {
		let ivlen = s.tagbuf;
		beputu64(ivlen[8..], len(iv) << 3);
		ghash_ctmul64(s.y0, s.h, iv);
		ghash_ctmul64(s.y0, s.h, ivlen);
		bytes::zero(ivlen);
	};

	s.y = begetu32(s.y0[12..]) + 1;

	let ad = ad[..];
	for (len(ad) > 0) {
		const max = if (len(ad) >= GCMBLOCKSZ) {
			yield GCMBLOCKSZ;
		} else {
			yield len(ad);
		};

		ghash_ctmul64(s.tagbuf, s.h, ad[..max]);
		ad = ad[max..];
	};
};

fn gcm_writer(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *gcmstream;
	if (len(buf) == 0) {
		return 0z;
	};

	if (s.xorbufpos == GCMBLOCKSZ) {
		// current key block is depleted, prepare the next one
		fillxorbuf(s);
	};

	let buf = buf[..];

	let n: size = 0;
	const max = if (s.xorbufpos + len(buf) > len(s.cipherbuf)) {
		yield len(s.cipherbuf) - s.xorbufpos;
	} else {
		yield len(buf);
	};

	let cipher = s.cipherbuf[s.xorbufpos..s.xorbufpos + max];
	let key = s.xorbuf[s.xorbufpos..s.xorbufpos + max];
	xor(cipher, key, buf[..max]);

	const n = io::write(s.handle, cipher)?;
	s.xorbufpos += n;
	s.clen += n;

	if (s.xorbufpos == GCMBLOCKSZ) {
		ghash_ctmul64(s.tagbuf, s.h, s.cipherbuf);
	};

	return n;
};

fn fillxorbuf(s: *gcmstream) void = {
	let y: [GCMBLOCKSZ]u8 = [0...];
	s.xorbuf[..] = s.y0[..];
	beputu32(s.xorbuf[12..], s.y);
	encrypt(s.block as *block, s.xorbuf, s.xorbuf);
	s.y += 1;
	s.xorbufpos = 0;
};

fn gcm_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *gcmstream;

	const n = match (io::read(s.handle, buf)?) {
	case io::EOF =>
		return io::EOF;
	case let s: size =>
		yield s;
	};

	for (let i = n; i > 0) {
		if (s.xorbufpos == GCMBLOCKSZ) {
			fillxorbuf(s);
		};

		const max = if (s.xorbufpos + i > GCMBLOCKSZ) {
			yield len(s.cipherbuf) - s.xorbufpos;
		} else {
			yield i;
		};

		let cipher = s.cipherbuf[s.xorbufpos..s.xorbufpos + max];
		let key = s.xorbuf[s.xorbufpos..s.xorbufpos + max];

		cipher[..] = buf[..max];
		xor(buf[..max], buf[..max], key);

		buf = buf[max..];
		i -= max;

		s.xorbufpos += max;
		s.clen += max;

		if (s.xorbufpos == len(s.cipherbuf)) {
			ghash_ctmul64(s.tagbuf, s.h, s.cipherbuf);
		};
	};

	return n;
};

// Finishes encryption and returns the authentication tag. After calling seal,
// the user must not write any more data to the stream.
export fn gcm_seal(s: *gcmstream, tag: []u8) void = {
	assert(len(tag) == GCMTAGSZ);
	if (s.xorbufpos > 0 && s.xorbufpos < GCMBLOCKSZ) {
		// last block was is not full, therefore the content was not
		// hashed yet.
		ghash_ctmul64(s.tagbuf, s.h, s.cipherbuf[..s.xorbufpos]);
	};

	beputu64(tag, s.adlen << 3);
	beputu64(tag[8..], s.clen << 3);
	ghash_ctmul64(s.tagbuf, s.h, tag);

	// use tmp to store the resulting tag
	encrypt(s.block as *block, tag, s.y0);
	xor(tag, tag, s.tagbuf);
};

// Verifies the authentication tag against the decrypted data. Must be called
// after reading all data from the stream to ensure that the data was not
// modified. If the data was modified, [[errors::invalid]] will be returned and
// the data must not be trusted.
export fn gcm_verify(s: *gcmstream, tag: []u8) (void | errors::invalid) = {
	assert(len(tag) == GCMTAGSZ);
	if (s.xorbufpos > 0 && s.xorbufpos < GCMBLOCKSZ) {
		ghash_ctmul64(s.tagbuf, s.h, s.cipherbuf[..s.xorbufpos]);
	};

	let tmp: [16]u8 = [0...];
	beputu64(tmp, s.adlen << 3);
	beputu64(tmp[8..], s.clen << 3);

	ghash_ctmul64(s.tagbuf, s.h, tmp);

	encrypt(s.block as *block, tmp, s.y0);
	xor(tmp, tmp, s.tagbuf);

	if (eqslice(tag, tmp) == 0) {
		return errors::invalid;
	};
};

fn gcm_closer(s: *io::stream) (void | io::error) = {
	let s = s: *gcmstream;
	bytes::zero(s.tagbuf);
	bytes::zero(s.xorbuf);
	bytes::zero(s.cipherbuf);
	bytes::zero(s.y0);
	bytes::zero(s.h);

	if (s.block is *block) {
		finish(s.block as *block);
	};
};
