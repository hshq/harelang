// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bytes;
use errors;
use io;
use memio;
use os;
use strings;

def PADDING: u8 = '=';

export type encoding = struct {
	encmap: [64]u8,
	decmap: [128]u8,
};

// Represents the standard base-64 encoding alphabet as defined in RFC 4648.
export const std_encoding: encoding = encoding { ... };

// Represents the "base64url" alphabet as defined in RFC 4648, suitable for use
// in URLs and file paths.
export const url_encoding: encoding = encoding { ... };

// Initializes a new encoding based on the passed alphabet, which must be a
// 64-byte ASCII string.
export fn encoding_init(enc: *encoding, alphabet: str) void = {
	const alphabet = strings::toutf8(alphabet);
	enc.decmap[..] = [-1...];
	assert(len(alphabet) == 64);
	for (let i: u8 = 0; i < 64; i += 1) {
		const ch = alphabet[i];
		assert(ascii::valid(ch: rune) && enc.decmap[ch] == -1);
		enc.encmap[i] = ch;
		enc.decmap[ch] = i;
	};
};

@init fn init() void = {
	const std_alpha: str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	const url_alpha: str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
	encoding_init(&std_encoding, std_alpha);
	encoding_init(&url_encoding, url_alpha);
};

export type encoder = struct {
	stream: io::stream,
	out: io::handle,
	enc: *encoding,
	ibuf: [3]u8,
	iavail: size,
	obuf: [4]u8,
	oavail: size,
	err: (void | io::error),
};

const encoder_vtable: io::vtable = io::vtable {
	writer = &encode_writer,
	closer = &encode_closer,
	...
};

// Creates a stream that encodes writes as base64 before writing them to a
// secondary stream. Afterwards [[io::close]] must be called to write any
// unwritten bytes, in case of padding. Closing this stream will not close
// the underlying stream.
export fn newencoder(
	enc: *encoding,
	out: io::handle,
) encoder = {
	return encoder {
		stream = &encoder_vtable,
		out = out,
		enc = enc,
		err = void,
		...
	};
};

fn encode_writer(
	s: *io::stream,
	in: const []u8
) (size | io::error) = {
	let s = s: *encoder;
	match(s.err) {
	case void => yield;
	case let err: io::error =>
		s.err = void;
		return err;
	};

	let i = 0z;
	for (i < len(in)) {
		let b = s.ibuf[..];
		// fill ibuf
		for (let j = s.iavail; j < 3 && i < len(in); j += 1) {
			b[j] = in[i];
			i += 1;
			s.iavail += 1;
		};

		if (s.iavail != 3) {
			return i;
		};

		fillobuf(s);

		match (writeavail(s)) {
		case void => yield;
		case let e: io::error =>
			if (i == 0) {
				return e;
			};
			s.err = e;
			return i;
		};
	};

	return i;
};

fn fillobuf(s: *encoder) void = {
	assert(s.iavail == 3);
	let b = s.ibuf[..];
	s.obuf[..] = [
		s.enc.encmap[b[0] >> 2],
		s.enc.encmap[(b[0] & 0x3) << 4 | b[1] >> 4],
		s.enc.encmap[(b[1] & 0xf) << 2 | b[2] >> 6],
		s.enc.encmap[b[2] & 0x3f],
	][..];
	s.oavail = 4;
};

fn writeavail(s: *encoder) (void | io::error) = {
	if (s.oavail == 0) {
		return;
	};

	for (s.oavail > 0) {
		let n = io::write(s.out, s.obuf[len(s.obuf) - s.oavail..])?;
		s.oavail -= n;
	};

	if (s.oavail == 0) {
		s.iavail = 0;
	};
};

// Flushes pending writes to the underlying stream.
fn encode_closer(s: *io::stream) (void | io::error) = {
	let s = s: *encoder;
	let done = false;
	defer if (done) clear(s);

	match (s.err) {
	case let e: io::error =>
		s.err = void;
		return e;
	case void =>
		yield;
	};

	if (s.oavail > 0) {
		for (s.oavail > 0) {
			writeavail(s)?;
		};
		done = true;
		return;
	};

	if (s.iavail == 0) {
		done = true;
		return;
	};

	// prepare padding as input length was not a multiple of 3
	//                        0  1  2
	static const npa: []u8 = [0, 2, 1];
	const np = npa[s.iavail];

	for (let i = s.iavail; i < 3; i += 1) {
		s.ibuf[i] = 0;
		s.iavail += 1;
	};

	fillobuf(s);
	for (let i = 0z; i < np; i += 1) {
		s.obuf[3 - i] = PADDING;
	};

	for (s.oavail > 0) {
		writeavail(s)?;
	};
	done = true;
};

fn clear(e: *encoder) void = {
	bytes::zero(e.ibuf);
	bytes::zero(e.obuf);
};

@test fn partialwrite() void = {
	const raw: [_]u8 = [
		0x00, 0x00, 0x00, 0x07, 0x73, 0x73, 0x68, 0x2d, 0x72, 0x73,
		0x61, 0x00,
	];
	const expected: str = `AAAAB3NzaC1yc2EA`;

	let buf = memio::dynamic();
	let e = newencoder(&std_encoding, &buf);
	io::writeall(&e, raw[..4])!;
	io::writeall(&e, raw[4..11])!;
	io::writeall(&e, raw[11..])!;
	io::close(&e)!;

	assert(memio::string(&buf)! == expected);
};

// Encodes a byte slice in base 64, using the given encoding, returning a slice
// of ASCII bytes. The caller must free the return value.
export fn encodeslice(enc: *encoding, in: []u8) []u8 = {
	let out = memio::dynamic();
	let encoder = newencoder(enc, &out);
	io::writeall(&encoder, in)!;
	io::close(&encoder)!;
	return memio::buffer(&out);
};

// Encodes base64 data using the given alphabet and writes it to a stream,
// returning the number of bytes of data written (i.e. len(buf)).
export fn encode(
	out: io::handle,
	enc: *encoding,
	buf: []u8,
) (size | io::error) = {
	const enc = newencoder(enc, out);
	match (io::writeall(&enc, buf)) {
	case let z: size =>
		io::close(&enc)?;
		return z;
	case let err: io::error =>
		clear(&enc);
		return err;
	};
};

// Encodes a byte slice in base 64, using the given encoding, returning a
// string. The caller must free the return value.
export fn encodestr(enc: *encoding, in: []u8) str = {
	return strings::fromutf8(encodeslice(enc, in))!;
};

@test fn encode() void = {
	// RFC 4648 test vectors
	const in: [_]u8 = ['f', 'o', 'o', 'b', 'a', 'r'];
	const expect: [_]str = [
		"",
		"Zg==",
		"Zm8=",
		"Zm9v",
		"Zm9vYg==",
		"Zm9vYmE=",
		"Zm9vYmFy"
	];
	for (let i = 0z; i <= len(in); i += 1) {
		let out = memio::dynamic();
		let encoder = newencoder(&std_encoding, &out);
		io::writeall(&encoder, in[..i])!;
		io::close(&encoder)!;
		let encb = memio::buffer(&out);
		defer free(encb);
		assert(bytes::equal(encb, strings::toutf8(expect[i])));

		// Testing encodestr should cover encodeslice too
		let s = encodestr(&std_encoding, in[..i]);
		defer free(s);
		assert(s == expect[i]);
	};
};

export type decoder = struct {
	stream: io::stream,
	in: io::handle,
	enc: *encoding,
	avail: []u8, // leftover decoded output
	pad: bool, // if padding was seen in a previous read
	state: (void | io::EOF | io::error),
};

const decoder_vtable: io::vtable = io::vtable {
	reader = &decode_reader,
	...
};

// Creates a stream that reads and decodes base 64 data from a secondary stream.
// This stream does not need to be closed, and closing it will not close the
// underlying stream.
export fn newdecoder(
	enc: *encoding,
	in: io::handle,
) decoder = {
	return decoder {
		stream = &decoder_vtable,
		in = in,
		enc = enc,
		state = void,
		...
	};
};

fn decode_reader(
	s: *io::stream,
	out: []u8
) (size | io::EOF | io::error) = {
	let s = s: *decoder;
	let n = 0z;
	let l = len(out);
	match(s.state) {
	case let err: (io::EOF | io ::error) =>
		return err;
	case void =>
		yield;
	};
	if (len(s.avail) > 0) {
		n += if (l < len(s.avail)) l else len(s.avail);
		out[..n] = s.avail[0..n];
		s.avail = s.avail[n..];
		if (l == n) {
			return n;
		};
	};
	static let buf: [os::BUFSZ]u8 = [0...];
	static let obuf: [os::BUFSZ / 4 * 3]u8 = [0...];
	const nn = ((l - n) / 3 + 1) * 4; // 4 extra bytes may be read.
	let nr = 0z;
	for (nr < nn) {
		match (io::read(s.in, buf[nr..])) {
		case let n: size =>
			if (n == 0) {
				break;
			};
			nr += n;
		case io::EOF =>
			s.state = io::EOF;
			break;
		case let err: io::error =>
			s.state = err;
			return err;
		};
	};
	if (nr % 4 != 0) {
		s.state = errors::invalid;
		return errors::invalid;
	};
	if (nr == 0) { // io::EOF already set
		return n;
	};
	// Validating read buffer
	let valid = true;
	let np = 0; // Number of padding chars.
	let p = true; // Pad allowed in buf
	for (let i = nr; i > 0; i -= 1) {
		const ch = buf[i - 1];
		if (ch >= 128) {
			return errors::invalid;
		};
		if (ch == PADDING) {
			if(s.pad || !p) {
				valid = false;
				break;
			};
			np += 1;
		} else {
			if (s.enc.decmap[ch] == -1) {
				valid = false;
				break;
			};
			// Disallow padding on seeing a non-padding char
			p = false;
		};
	};
	valid = valid && np <= 2;
	if (np > 0) {
		s.pad = true;
	};
	if (!valid) {
		s.state = errors::invalid;
		return errors::invalid;
	};
	for (let i = 0z; i < nr; i += 1) {
		if (buf[i] >= 128) {
			return errors::invalid;
		};
		buf[i] = s.enc.decmap[buf[i]];
	};
	for (let i = 0z, j = 0z; i < nr) {
		obuf[j] = buf[i] << 2 | buf[i + 1] >> 4;
		obuf[j + 1] = buf[i + 1] << 4 | buf[i + 2] >> 2;
		obuf[j + 2] = buf[i + 2] << 6 | buf[i + 3];

		i += 4;
		j += 3;
	};
	// Removing bytes added due to padding.
	//                         0  1  2 // np
	static const npr: [3]u8 = [0, 1, 2]; // bytes to discard
	const navl = nr / 4 * 3 - npr[np];
	const rem = if(l - n < navl) l - n else navl;
	out[n..n + rem] = obuf[..rem];
	s.avail = obuf[rem..navl];
	return n + rem;
};

// Decodes a byte slice of ASCII-encoded base 64 data, using the given encoding,
// returning a slice of decoded bytes. The caller must free the return value.
export fn decodeslice(
	enc: *encoding,
	in: []u8,
) ([]u8 | errors::invalid) = {
	let in = memio::fixed(in);
	let decoder = newdecoder(enc, &in);
	let out = memio::dynamic();
	match (io::copy(&out, &decoder)) {
	case io::error =>
		io::close(&out)!;
		return errors::invalid;
	case size =>
		return memio::buffer(&out);
	};
};

// Decodes a string of ASCII-encoded base 64 data, using the given encoding,
// returning a slice of decoded bytes. The caller must free the return value.
export fn decodestr(enc: *encoding, in: str) ([]u8 | errors::invalid) = {
	return decodeslice(enc, strings::toutf8(in));
};

// Decodes base64 data from a stream using the given alphabet, returning the
// number of bytes of bytes read (i.e. len(buf)).
export fn decode(
	in: io::handle,
	enc: *encoding,
	buf: []u8,
) (size | io::EOF | io::error) = {
	const enc = newdecoder(enc, in);
	match (io::readall(&enc, buf)) {
	case let ret: (size | io::EOF) =>
		io::close(&enc)?;
		return ret;
	case let err: io::error =>
		io::close(&enc): void;
		return err;
	};
};

@test fn decode() void = {
	// RFC 4648 test vectors
	const cases: [_](str, str, *encoding) = [
		("", "", &std_encoding),
		("Zg==", "f", &std_encoding),
		("Zm8=", "fo", &std_encoding),
		("Zm9v", "foo", &std_encoding),
		("Zm9vYg==", "foob", &std_encoding),
		("Zm9vYmE=", "fooba", &std_encoding),
		("Zm9vYmFy", "foobar", &std_encoding),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		let in = memio::fixed(strings::toutf8(cases[i].0));
		let decoder = newdecoder(cases[i].2, &in);
		let decb: []u8 = io::drain(&decoder)!;
		defer free(decb);
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));

		// Testing decodestr should cover decodeslice too
		let decb = decodestr(cases[i].2, cases[i].0) as []u8;
		defer free(decb);
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));
	};
	// Repeat of the above, but with a larger buffer
	for (let i = 0z; i < len(cases); i += 1) {
		let in = memio::fixed(strings::toutf8(cases[i].0));
		let decoder = newdecoder(cases[i].2, &in);
		let decb: []u8 = io::drain(&decoder)!;
		defer free(decb);
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));
	};

	const invalid: [_]str = [
		// invalid padding
		"=", "==", "===", "=====", "======",
		// invalid characters
		"@Zg=", "êg=", "êg==", "$3d==", "%3d==", "[==", "!",
		// data after padding is encountered
		"Zg==Zg==", "Zm8=Zm8=",
	];
	const encodings: [_]*encoding = [&std_encoding, &url_encoding];
	for (let i = 0z; i < len(invalid); i += 1) {
		for (let enc = 0z; enc < 2; enc += 1) {
			let in = memio::fixed(strings::toutf8(invalid[i]));
			let decoder = newdecoder(encodings[enc], &in);
			let buf: [1]u8 = [0...];
			let valid = false;
			for (true) match(io::read(&decoder, buf)) {
			case errors::invalid =>
				break;
			case size =>
				valid = true;
			case io::EOF =>
				break;
			};
			assert(valid == false, "valid is not false");

			// Testing decodestr should cover decodeslice too
			assert(decodestr(encodings[enc], invalid[i]) is errors::invalid);
		};
	};
};

// Given the length of the message, returns the size of its base64 encoding
export fn encodedsize(sz: size) size = if (sz == 0) 0 else ((sz - 1)/ 3 + 1) * 4;

// Given the size of base64 encoded data, returns maximal length of decoded message.
// The message may be at most 2 bytes shorter than the returned value. Input
// size must be a multiple of 4.
export fn decodedsize(sz: size) size = {
	assert(sz % 4 == 0);
	return sz / 4 * 3;
};

@test fn sizecalc() void = {
	let enc: [_](size, size) = [(1, 4), (2, 4), (3, 4), (4, 8), (10, 16),
		(119, 160), (120, 160), (121, 164), (122, 164), (123, 164)
	];
	assert(encodedsize(0) == 0 && decodedsize(0) == 0);
	for (let i = 0z; i < len(enc); i += 1) {
		let (decoded, encoded) = enc[i];
		assert(encodedsize(decoded) == encoded);
		assert(decodedsize(encoded) == ((decoded - 1) / 3 + 1) * 3);
	};
};
