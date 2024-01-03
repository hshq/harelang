// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::chacha;
use crypto::mac;
use crypto::math;
use crypto::poly1305;
use endian;
use errors;
use io;
use memio;
use types;

// Nonce size as required by [[init]].
export def NONCESZ: size = chacha::NONCESZ;

// Nonce size as required by [[xinit]].
export def XNONCESZ: size = chacha::XNONCESZ;

// Key size
export def KEYSZ: size = chacha::KEYSZ;

// Tag size
export def TAGSZ: size = poly1305::SZ;

export type stream = struct {
	stream: io::stream,
	h: io::teestream,
	c: chacha::stream,
	p: poly1305::state,
	adsz: size,
	msgsz: size,
};

// Create a stream that must be initialised by [[init]] or [[xinit]]. The user
// must call [[io::close]] when they are done using the stream to securly erase
// secret information stored in the stream state.
export fn chachapoly() stream = {
	return stream {
		stream = &vtable,
		c = chacha::chacha20(),
		p = poly1305::poly1305(),
		h = io::tee(io::empty, io::empty),
		...
	};
};

const vtable: io::vtable = io::vtable {
	writer = &writer,
	reader = &reader,
	closer = &closer,
	...
};

type initfunc = fn (s: *chacha::stream, h: io::handle, k: []u8, n: []u8) void;

// Initialises the stream as Chacha20-Poly1305. Encrypts to or decrypts from
// 'h'. 'nonce' must be a random value that will only be used once. Additional
// data can be passed as 'ad'.
export fn init(
	s: *stream,
	h: io::handle,
	key: const []u8,
	nonce: const []u8,
	ad: const []u8...
) void = geninit(s, &chacha::chacha20_init, h, key, nonce, ad...);

// Initialise the stream as XChacha20-Poly1305. Encrypts to or decrypts from
// 'h'. 'nonce' must be a random value that will only be used once. Additional
// data can be passed as 'ad'.
export fn xinit(
	s: *stream,
	h: io::handle,
	key: const []u8,
	nonce: const []u8,
	ad: const []u8...
) void = geninit(s, &chacha::xchacha20_init, h, key, nonce, ad...);

fn geninit(
	s: *stream,
	finit: *initfunc,
	h: io::handle,
	key: const []u8,
	nonce: const []u8,
	ad: const []u8...
) void = {
	assert(len(ad) <= types::U32_MAX);

	let otk: poly1305::key = [0...];
	defer bytes::zero(otk);

	let otkbuf = memio::fixed(otk);
	finit(&s.c, &otkbuf, key, nonce);
	io::writeall(&s.c, otk[..])!;

	poly1305::init(&s.p, &otk);

	s.adsz = 0z;
	for (let i = 0z; i < len(ad); i += 1) {
		s.adsz += len(ad[i]);
		mac::write(&s.p, ad[i]);
	};
	polypad(&s.p, s.adsz);

	s.h = io::tee(h, &s.p);
	finit(&s.c, &s.h, key, nonce);
	chacha::setctr(&s.c, 1);

	s.msgsz = 0;
};

fn polypad(p: *poly1305::state, n: size) void = {
	if (n % poly1305::BLOCKSZ == 0) {
		return;
	};

	const pad: [poly1305::BLOCKSZ]u8 = [0...];
	const padlen = poly1305::BLOCKSZ - (n % poly1305::BLOCKSZ);
	mac::write(p, pad[..padlen]);
};

// Finishes encryption and writes the authentication code to 'tag'. After
// calling seal, the user must not write any more data to the stream.
export fn seal(s: *stream, tag: []u8) void = writemac(s, tag);

fn writemac(s: *stream, tag: []u8) void = {
	assert(len(tag) == TAGSZ);
	assert(s.msgsz <= types::U32_MAX);

	polypad(&s.p, s.msgsz);

	let nbuf: [8]u8 = [0...];
	endian::leputu64(nbuf, s.adsz: u32);
	mac::write(&s.p, nbuf);

	endian::leputu64(nbuf, s.msgsz: u32);
	mac::write(&s.p, nbuf);

	mac::sum(&s.p, tag[..]);
};

// Verifies the authentication tag against the decrypted data. Must be called
// after reading all data from the stream to ensure that the data was not
// modified. If the data was modified, [[errors::invalid]] will be returned and
// the data must not be trusted.
export fn verify(s: *stream, tag: []u8) (void | errors::invalid) = {
	let ntag: [TAGSZ]u8 = [0...];
	writemac(s, ntag);
	if (math::eqslice(ntag, tag) == 0) {
		return errors::invalid;
	};
};

fn writer(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *stream;
	const n = io::write(&s.c, buf)?;
	s.msgsz += n;
	return n;
};

fn reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *stream;
	match (io::read(&s.c, buf)?) {
	case io::EOF =>
		return io::EOF;
	case let n: size =>
		s.msgsz += n;
		return n;
	};
};

fn closer(s: *io::stream) (void | io::error) = {
	let s = s: *stream;
	io::close(&s.c)!;
	mac::finish(&s.p);
};
