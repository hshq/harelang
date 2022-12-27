// License: MPL-2.0
// (c) 2022 Ajay R <ar324@protonmail.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Steven Guikal <void@fluix.one>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use ascii;
use bufio;
use bytes;
use errors;
use io;
use os;
use strings;

def PADDING: u8 = '=';

export type encoding = struct {
	encmap: [64]u8,
	decmap: [256]u8,
	valid: [256]bool,
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
	assert(len(alphabet) == 64);
	for (let i: u8 = 0; i < 64; i += 1) {
		const ch = alphabet[i];
		assert(ascii::valid(ch: u32: rune));
		enc.encmap[i] = ch;
		enc.decmap[ch] = i;
		enc.valid[ch] = true;
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
	buf: [2]u8, // leftover input
	avail: size, // bytes available in buf
	err: (void | io::error),
};

const encoder_vtable: io::vtable = io::vtable {
	writer = &encode_writer,
	closer = &encode_closer,
	...
};

// Creates a stream that encodes writes as base64 before writing them to a
// secondary stream. The encoder stream must be closed to finalize any unwritten
// bytes. Closing this stream will not close the underlying stream.
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
	case let err: io::error =>
		return err;
	case void =>
		yield;
	};
	let l = len(in);
	let i = 0z;
	for (i + 2 < l + s.avail; i += 3) {
		static let b: [3]u8 = [0...]; // 3 bytes get converted into 4 bytes
		if (i < s.avail) {
			for (let j = 0z; j < s.avail; j += 1) {
				b[j] = s.buf[j];
			};
			for (let j = s.avail; j < 3; j += 1) {
				b[j] = in[j - s.avail];
			};
		} else {
			for (let j = 0z; j < 3; j += 1) {
				b[j] = in[j - s.avail + i];
			};
		};
		let encb: [4]u8 = [
			s.enc.encmap[b[0] >> 2],
			s.enc.encmap[(b[0] & 0x3) << 4 | b[1] >> 4],
			s.enc.encmap[(b[1] & 0xf) << 2 | b[2] >> 6],
			s.enc.encmap[b[2] & 0x3F],
		];
		match(io::write(s.out, encb)) {
		case let err: io::error =>
			s.err = err;
			return err;
		case size =>
			yield;
		};
	};
	// storing leftover bytes
	if (l + s.avail < 3) {
		for (let j = s.avail; j < s.avail + l; j += 1) {
			s.buf[j] = in[j - s.avail];
		};
	} else {
		const begin = (l + s.avail) / 3 * 3;
		for (let j = begin; j < l + s.avail; j += 1) {
			s.buf[j - begin] = in[j - s.avail];
		};
	};
	s.avail = (l + s.avail) % 3;
	return l;
};

fn encode_closer(s: *io::stream) (void | io::error) = {
	let s = s: *encoder;
	if (s.avail == 0) {
		return;
	};
	static let b: [3]u8 = [0...]; // the 3 bytes that will be encoded into 4 bytes
	for (let i = 0z; i < 3; i += 1) {
		b[i] = if (i < s.avail) s.buf[i] else 0;
	};
	let encb: [4]u8 = [
		s.enc.encmap[b[0] >> 2],
		s.enc.encmap[(b[0] & 0x3) << 4 | b[1] >> 4],
		s.enc.encmap[(b[1] & 0xf) << 2 | b[2] >> 6],
		s.enc.encmap[b[2] & 0x3F],
	];
	// adding padding as input length was not a multiple of 3
	//                        0  1  2
	static const npa: []u8 = [0, 2, 1];
	const np = npa[s.avail];
	for (let i = 0z; i < np; i += 1) {
		encb[3 - i] = PADDING;
	};
	io::writeall(s.out, encb)?;
};

@test fn partialwrite() void = {
	const raw: [_]u8 = [
		0x00, 0x00, 0x00, 0x07, 0x73, 0x73, 0x68, 0x2d, 0x72, 0x73,
		0x61, 0x00,
	];
	const expected: str = `AAAAB3NzaC1yc2EA`;

	let buf = bufio::dynamic(io::mode::WRITE);
	let e = newencoder(&std_encoding, &buf);
	io::writeall(&e, raw[..4])!;
	io::writeall(&e, raw[4..11])!;
	io::writeall(&e, raw[11..])!;
	io::close(&e)!;

	assert(strings::fromutf8(bufio::buffer(&buf))! == expected);
};

// Encodes a byte slice in base 64, using the given encoding, returning a slice
// of ASCII bytes. The caller must free the return value.
export fn encodeslice(enc: *encoding, in: []u8) []u8 = {
	let out = bufio::dynamic(io::mode::WRITE);
	let encoder = newencoder(enc, &out);
	io::writeall(&encoder, in)!;
	io::close(&encoder)!;
	return bufio::buffer(&out);
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
		io::close(&enc): void;
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
		let out = bufio::dynamic(io::mode::WRITE);
		let encoder = newencoder(&std_encoding, &out);
		io::writeall(&encoder, in[..i])!;
		io::close(&encoder)!;
		let encb = bufio::buffer(&out);
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
	static let buf: [os::BUFSIZ]u8 = [0...];
	static let obuf: [os::BUFSIZ / 4 * 3]u8 = [0...];
	const nn = ((l - n) / 3 + 1) * 4; // 4 extra bytes may be read.
	let nr = 0z;
	for (nr < nn) {
		match (io::read(s.in, buf[nr..])) {
		case let n: size =>
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
		if (ch == PADDING) {
			if(s.pad || !p) {
				valid = false;
				break;
			};
			np += 1;
		} else {
			if (!s.enc.valid[ch]) {
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
	for (let i = n; i < n + rem; i += 1) {
		out[i] = obuf[i - n];
	};
	s.avail = obuf[rem..navl];
	return n + rem;
};

// Decodes a byte slice of ASCII-encoded base 64 data, using the given encoding,
// returning a slice of decoded bytes. The caller must free the return value.
export fn decodeslice(
	enc: *encoding,
	in: []u8,
) ([]u8 | errors::invalid) = {
	let in = bufio::fixed(in, io::mode::READ);
	let decoder = newdecoder(enc, &in);
	let out = bufio::dynamic(io::mode::WRITE);
	match (io::copy(&out, &decoder)) {
	case io::error =>
		io::close(&out)!;
		return errors::invalid;
	case size =>
		return bufio::buffer(&out);
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
		let in = bufio::fixed(strings::toutf8(cases[i].0), io::mode::READ);
		let decoder = newdecoder(cases[i].2, &in);
		let buf: [1]u8 = [0];
		let decb: []u8 = [];
		defer free(decb);
		for (true) match (io::read(&decoder, buf)!) {
		case let z: size =>
			if (z > 0) {
				append(decb, buf[0]);
			};
		case io::EOF =>
			break;
		};
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));

		// Testing decodestr should cover decodeslice too
		let decb = decodestr(cases[i].2, cases[i].0) as []u8;
		defer free(decb);
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));
	};
	// Repeat of the above, but with a larger buffer
	for (let i = 0z; i < len(cases); i += 1) {
		let in = bufio::fixed(strings::toutf8(cases[i].0), io::mode::READ);
		let decoder = newdecoder(cases[i].2, &in);
		let buf: [1024]u8 = [0...];
		let decb: []u8 = [];
		defer free(decb);
		for (true) match (io::read(&decoder, buf)!) {
		case let z: size =>
			if (z > 0) {
				append(decb, buf[..z]...);
			};
		case io::EOF =>
			break;
		};
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));
	};

	const invalid: [_](str, *encoding) = [
		// invalid padding
		("=", &std_encoding),
		("==", &std_encoding),
		("===", &std_encoding),
		("=====", &std_encoding),
		("======", &std_encoding),
		// invalid characters
		("@Zg=", &std_encoding),
		("êg==", &std_encoding),
		// data after padding is encountered
		("Zg==Zg==", &std_encoding),
		("Zm8=Zm8=", &std_encoding),
	];
	for (let i = 0z; i < len(invalid); i += 1) {
		let in = bufio::fixed(strings::toutf8(invalid[i].0), io::mode::READ);
		let decoder = newdecoder(invalid[i].1, &in);
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
		assert(decodestr(invalid[i].1, invalid[i].0) is errors::invalid);
	};
};
