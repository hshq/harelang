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
	encmap: [32]u8,
	decmap: [256]u8,
	valid: [256]bool,
};

// Represents the standard base-32 encoding alphabet as defined in RFC 4648.
export const std_encoding: encoding = encoding { ... };

// Represents the "base32hex" alphabet as defined in RFC 4648.
export const hex_encoding: encoding = encoding { ... };

// Initializes a new encoding based on the passed alphabet, which must be a
// 32-byte ASCII string.
export fn encoding_init(enc: *encoding, alphabet: str) void = {
	const alphabet = strings::toutf8(alphabet);
	assert(len(alphabet) == 32);
	for (let i: u8 = 0; i < 32; i += 1) {
		const ch = alphabet[i];
		assert(ascii::valid(ch: rune));
		enc.encmap[i] = ch;
		enc.decmap[ch] = i;
		enc.valid[ch] = true;
	};
};

@init fn init() void = {
	const std_alpha: str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
	const hex_alpha: str = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
	encoding_init(&std_encoding, std_alpha);
	encoding_init(&hex_encoding, hex_alpha);
};

export type encoder = struct {
	stream: io::stream,
	out: io::handle,
	enc: *encoding,
	buf: [4]u8, // leftover input
	avail: size, // bytes available in buf
	err: (void | io::error),
};

const encoder_vtable: io::vtable = io::vtable {
	writer = &encode_writer,
	closer = &encode_closer,
	...
};

// Creates a stream that encodes writes as base-32 before writing them to a
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
	case void => void;
	};
	let l = len(in);
	let i = 0z;
	for (i + 4 < l + s.avail; i += 5) {
		static let b: [5]u8 = [0...]; // 5 bytes -> (enc) 8 bytes
		if (i < s.avail) {
			for (let j = 0z; j < s.avail; j += 1) {
				b[j] = s.buf[i];
			};
			for (let j = s.avail; j < 5; j += 1) {
				b[j] = in[j - s.avail];
			};
		} else {
			for (let j = 0z; j < 5; j += 1) {
				b[j] = in[j - s.avail + i];
			};
		};
		let encb: [8]u8 = [
			s.enc.encmap[b[0] >> 3],
			s.enc.encmap[(b[0] & 0x7) << 2 | (b[1] & 0xC0) >> 6],
			s.enc.encmap[(b[1] & 0x3E) >> 1],
			s.enc.encmap[(b[1] & 0x1) << 4 | (b[2] & 0xF0) >> 4],
			s.enc.encmap[(b[2] & 0xF) << 1 | (b[3] & 0x80) >> 7],
			s.enc.encmap[(b[3] & 0x7C) >> 2],
			s.enc.encmap[(b[3] & 0x3) << 3 | (b[4] & 0xE0) >> 5],
			s.enc.encmap[b[4] & 0x1F],
		];
		match(io::write(s.out, encb)) {
		case let err: io::error =>
			s.err = err;
			return err;
		case size => void;
		};
	};
	// storing leftover bytes
	if (l + s.avail < 5) {
		for (let j = s.avail; j < s.avail + l; j += 1) {
			s.buf[j] = in[j - s.avail];
		};
	} else {
		const begin = (l + s.avail) / 5 * 5;
		for (let j = begin; j < l + s.avail; j += 1) {
			s.buf[j - begin] = in[j - s.avail];
		};
	};
	s.avail = (l + s.avail) % 5;
	return l;
};

fn encode_closer(s: *io::stream) (void | io::error) = {
	let s = s: *encoder;
	if (s.avail == 0) {
		return;
	};
	static let b: [5]u8 = [0...]; // the 5 bytes that will be encoded into 8 bytes
	for (let i = 0z; i < 5; i += 1) {
		b[i] = if (i < s.avail) s.buf[i] else 0;
	};
	let encb: [8]u8 = [
		s.enc.encmap[b[0] >> 3],
		s.enc.encmap[(b[0] & 0x7) << 2 | (b[1] & 0xC0) >> 6],
		s.enc.encmap[(b[1] & 0x3E) >> 1],
		s.enc.encmap[(b[1] & 0x1) << 4 | (b[2] & 0xF0) >> 4],
		s.enc.encmap[(b[2] & 0xF) << 1 | (b[3] & 0x80) >> 7],
		s.enc.encmap[(b[3] & 0x7C) >> 2],
		s.enc.encmap[(b[3] & 0x3) << 3 | (b[4] & 0xE0) >> 5],
		s.enc.encmap[b[4] & 0x1F],
	];
	// adding padding as input length was not a multiple of 5
	//                        0  1  2  3  4
	static const npa: []u8 = [0, 6, 4, 3, 1];
	const np = npa[s.avail];
	for (let i = 0z; i < np; i += 1) {
		encb[7 - i] = PADDING;
	};
	io::writeall(s.out, encb)?;
};

// Encodes a byte slice in base-32, using the given encoding, returning a slice
// of ASCII bytes. The caller must free the return value.
export fn encodeslice(enc: *encoding, in: []u8) []u8 = {
	let out = memio::dynamic();
	let encoder = newencoder(enc, &out);
	io::writeall(&encoder, in)!;
	io::close(&encoder)!;
	return memio::buffer(&out);
};

// Encodes a byte slice in base-32, using the given encoding, returning a
// string. The caller must free the return value.
export fn encodestr(enc: *encoding, in: []u8) str = {
	return strings::fromutf8(encodeslice(enc, in))!;
};

@test fn encode() void = {
	// RFC 4648 test vectors
	const in: [_]u8 = ['f', 'o', 'o', 'b', 'a', 'r'];
	const expect: [_]str = [
		"",
		"MY======",
		"MZXQ====",
		"MZXW6===",
		"MZXW6YQ=",
		"MZXW6YTB",
		"MZXW6YTBOI======",
	];
	const expect_hex: [_]str = [
		"",
		"CO======",
		"CPNG====",
		"CPNMU===",
		"CPNMUOG=",
		"CPNMUOJ1",
		"CPNMUOJ1E8======",
	];
	for (let i = 0z; i <= len(in); i += 1) {
		let out = memio::dynamic();
		let enc = newencoder(&std_encoding, &out);
		io::writeall(&enc, in[..i]) as size;
		io::close(&enc)!;
		let outb = memio::buffer(&out);
		assert(bytes::equal(outb, strings::toutf8(expect[i])));
		free(outb);
		// Testing encodestr should cover encodeslice too
		let s = encodestr(&std_encoding, in[..i]);
		defer free(s);
		assert(s == expect[i]);

		out = memio::dynamic();
		enc = newencoder(&hex_encoding, &out);
		io::writeall(&enc, in[..i]) as size;
		io::close(&enc)!;
		let outb = memio::buffer(&out);
		assert(bytes::equal(outb, strings::toutf8(expect_hex[i])));
		free(outb);
		let s = encodestr(&hex_encoding, in[..i]);
		defer free(s);
		assert(s == expect_hex[i]);
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

// Creates a stream that reads and decodes base-32 data from a secondary stream.
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
	case void => void;
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
	static let obuf: [os::BUFSZ / 8 * 5]u8 = [0...];
	const nn = ((l - n) / 5 + 1) * 8; // 8 extra bytes may be read.
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
	if (nr % 8 != 0) {
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
	valid = valid && np <= 6 && np != 2 && np != 5;
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
		obuf[j] = (buf[i] << 3) | (buf[i + 1] & 0x1C) >> 2;
		obuf[j + 1] =
			(buf[i + 1] & 0x3) << 6 | buf[i + 2] << 1 | (buf[i + 3] & 0x10) >> 4;
		obuf[j + 2] = (buf[i + 3] & 0x0F) << 4 | (buf[i + 4] & 0x1E) >> 1;
		obuf[j + 3] =
			(buf[i + 4] & 0x1) << 7 | buf[i + 5] << 2 | (buf[i + 6] & 0x18) >> 3;
		obuf[j + 4] = (buf[i + 6] & 0x7) << 5 | buf[i + 7];
		i += 8;
		j += 5;
	};
	// Removing bytes added due to padding.
	//                         0  1  2  3  4  5  6   // np
	static const npr: [7]u8 = [0, 1, 0, 2, 3, 0, 4]; // bytes to discard
	const navl = nr / 8 * 5 - npr[np];
	const rem = if(l - n < navl) l - n else navl;
	out[n..n + rem] = obuf[..rem];
	s.avail = obuf[rem..navl];
	return n + rem;
};

// Decodes a byte slice of ASCII-encoded base-32 data, using the given encoding,
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

// Decodes a string of ASCII-encoded base-32 data, using the given encoding,
// returning a slice of decoded bytes. The caller must free the return value.
export fn decodestr(enc: *encoding, in: str) ([]u8 | errors::invalid) = {
	return decodeslice(enc, strings::toutf8(in));
};

@test fn decode() void = {
	const cases: [_](str, str, *encoding) = [
		("", "", &std_encoding),
		("MY======", "f", &std_encoding),
		("MZXQ====", "fo", &std_encoding),
		("MZXW6===", "foo", &std_encoding),
		("MZXW6YQ=", "foob", &std_encoding),
		("MZXW6YTB", "fooba", &std_encoding),
		("MZXW6YTBOI======", "foobar", &std_encoding),
		("", "", &hex_encoding),
		("CO======", "f", &hex_encoding),
		("CPNG====", "fo", &hex_encoding),
		("CPNMU===", "foo", &hex_encoding),
		("CPNMUOG=", "foob", &hex_encoding),
		("CPNMUOJ1", "fooba", &hex_encoding),
		("CPNMUOJ1E8======", "foobar", &hex_encoding),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		let in = memio::fixed(strings::toutf8(cases[i].0));
		let dec = newdecoder(cases[i].2, &in);
		let out: []u8 = io::drain(&dec)!;
		defer free(out);
		assert(bytes::equal(out, strings::toutf8(cases[i].1)));

		// Testing decodestr should cover decodeslice too
		let decb = decodestr(cases[i].2, cases[i].0) as []u8;
		defer free(decb);
		assert(bytes::equal(decb, strings::toutf8(cases[i].1)));
	};
	// Repeat of the above, but with a larger buffer
	for (let i = 0z; i < len(cases); i += 1) {
		let in = memio::fixed(strings::toutf8(cases[i].0));
		let dec = newdecoder(cases[i].2, &in);
		let out: []u8 = io::drain(&dec)!;
		defer free(out);
		assert(bytes::equal(out, strings::toutf8(cases[i].1)));
	};

	const invalid: [_](str, *encoding) = [
		// invalid padding
		("=", &std_encoding),
		("==", &std_encoding),
		("===", &std_encoding),
		("=====", &std_encoding),
		("======", &std_encoding),
		("=======", &std_encoding),
		("========", &std_encoding),
		("=========", &std_encoding),
		// invalid characters
		("1ZXW6YQ=", &std_encoding),
		("êZXW6YQ=", &std_encoding),
		("MZXW1YQ=", &std_encoding),
		// data after padding is encountered
		("CO======CO======", &std_encoding),
		("CPNG====CPNG====", &std_encoding),
	];
	for (let i = 0z; i < len(invalid); i += 1) {
		let in = memio::fixed(strings::toutf8(invalid[i].0));
		let dec = newdecoder(invalid[i].1, &in);
		let buf: [1]u8 = [0...];
		let valid = false;
		for (true) match(io::read(&dec, buf)) {
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
