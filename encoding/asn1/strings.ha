// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use endian;
use errors;
use io;
use strings;


// numeric string
def N: u8 = 0o1;

// printable string
def P: u8 = 0o2;

// LUT of bitfields with character attributes
const cclass: [_]u8 = [
//	 0	 1	 2	 3	 4	 5	 6	 7
	0,	0,	0,	0,	0,	0,	0,	0,	// 0
	0,	0,	0,	0,	0,	0,	0,	0,	// 10
	0,	0,	0,	0,	0,	0,	0,	0,	// 20
	0,	0,	0,	0,	0,	0,	0,	0,	// 30
	N|P,	0,	0,	0,	0,	0,	0,	P,	// 40
	P,	P,	0,	P,	P,	P,	P,	P,	// 50
	N|P,	N|P,	N|P,	N|P,	N|P,	N|P,	N|P,	N|P,	// 60
	N|P,	N|P,	P,	0,	0,	P,	0,	P,	// 70
	0,	P,	P,	P,	P,	P,	P,	P,	// 100
	P,	P,	P,	P,	P,	P,	P,	P,	// 110
	P,	P,	P,	P,	P,	P,	P,	P,	// 120
	P,	P,	P,	0,	0,	0,	0,	0,	// 130
	0,	P,	P,	P,	P,	P,	P,	P,	// 140
	P,	P,	P,	P,	P,	P,	P,	P,	// 150
	P,	P,	P,	P,	P,	P,	P,	P,	// 160
	P,	P,	P,	0,	0,	0,	0,	0,	// 170
];

type char_validator = fn (c: u8) bool;

// Whether 'c' is valid in a NumericString
fn c_is_num(c: u8) bool = c & 0x80 == 0 && cclass[c] & N != 0;

// Whether 'c' is valid in a PrintableString
fn c_is_print(c: u8) bool = c & 0x80 == 0 && cclass[c] & P != 0;

fn c_is_ia5(c: u8) bool = c & 0x80 == 0;

// Returns the number of bytes of the biggest complete utf8 chunk. Returns
// invalid, if the biggest complete chunk contains invalid utf8 characters.
fn validutf8(buf: []u8) (size | invalid) = {
	if (len(buf) == 0) {
		return 0z;
	};

	const min = if (len(buf) < 4) 0z else len(buf) - 4;

	let lastvalid = 0z;
	let lastsz = 0z;
	for (let i = min; i < len(buf); i += 1) {
		match (utf8::utf8sz(buf[i])) {
		case utf8::invalid => void;
		case let s: size =>
			lastsz = s;
			lastvalid = i;
		};
	};

	if (lastsz == 0) return invalid;

	const n = if (len(buf) - lastvalid == lastsz) len(buf) else lastvalid;
	if (utf8::validate(buf[..n]) is utf8::invalid) {
		return invalid;
	};

	return n;
};

@test fn validutf8() void = {
	let b: [_]u8 = [
		0x55, 0x56, 0xd0, 0x98, 0xe0, 0xa4, 0xb9, 0xf0, 0x90, 0x8d, 0x88
	];
	const runesat: [_]size = [0, 1, 2, 2, 4, 4, 4, 7, 7, 7, 7, 8];

	for (let i = 0z; i < len(b); i += 1) {
		assert(validutf8(b[..i])! == runesat[i]);
	};

	b[10] = 0x55;
	assert(validutf8(b[..10])! == 7);
	assert(validutf8(b) is invalid);
};

// An io::stream reader that returns only valid utf8 chunks on read.
export type utf8stream = struct {
	stream: io::stream,
	d: *decoder,
	strdec: *strdecoder,
};

const utf8stream_vtable = io::vtable {
	reader = &utf8stream_reader,
	...
};

fn utf8stream_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	// at least a rune must fit in buf
	assert(len(buf) >= 4);
	let s = s: *utf8stream;
	let cur = match (s.d.cur) {
	case void =>
		abort();
	case let dh: head =>
		yield dh;
	};

	match (s.strdec(s, buf)?) {
	case let n: size =>
		return n;
	case io::EOF =>
		return io::EOF;
	};
};

export type strdecoder = fn(
	s: *utf8stream,
	buf: []u8,
) (size | io::EOF | io::error);

fn no_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) =
	dataread(s.d, buf);

fn char_decoder(
	s: *utf8stream, buf: []u8,
	v: *char_validator,
) (size | io::EOF | io::error) = {
	let n = match (dataread(s.d, buf)?) {
	case let n: size =>
		yield n;
	case io::EOF =>
		return io::EOF;
	};

	for (let i = 0z; i < n; i += 1) {
		if (!v(buf[i])) return wrap_err(invalid);
	};
	return n;
};

fn num_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) =
	char_decoder(s, buf, &c_is_num);

fn print_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) =
	char_decoder(s, buf, &c_is_print);

fn ia5_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) =
	char_decoder(s, buf, &c_is_ia5);

fn utf8_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) = {
	let n = 0z;

	n += match (dataread(s.d, buf)?) {
	case let sz: size =>
		yield sz;
	case io::EOF =>
		if (s.d.unbufn > 0) return wrap_err(invalid);
		return io::EOF;
	};

	const max = match (validutf8(buf[..n])) {
	case let s: size =>
		yield s;
	case invalid =>
		return wrap_err(invalid);
	};

	if (max < n) {
		if (dataeof(s.d)) {
			// string ends with incomplete rune
			return wrap_err(invalid);
		};
		dataunread(s.d, buf[max..n]);
		return max;
	};

	return n;
};

// A bmp string is an UTF-16 string.
fn bmp_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) = {
	const max = len(buf) - (len(buf) % 2);

	// TODO disallow control functions (X.690: 8.23.9)

	let n = 0z;
	let rbuf: [2]u8 = [0...];
	for (true) {
		match (dataread(s.d, rbuf)?) {
		case let sz: size =>
			if (sz < 2) return wrap_err(invalid);
		case io::EOF =>
			return if (n == 0) io::EOF else n;
		};

		let r = endian::begetu16(rbuf): rune;
		let rb = utf8::encoderune(r);
		if (len(buf) - n < len(rb)) {
			dataunread(s.d, rbuf);
			return n;
		};

		buf[n..n + len(rb)] = rb;
		n += len(rb);
	};
};

// Universal string is an UTF32BE string.
fn universal_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) = {
	const max = len(buf) - (len(buf) % 4);

	let n = 0z;
	let rbuf: [4]u8 = [0...];
	for (true) {
		match (dataread(s.d, rbuf)?) {
		case let sz: size =>
			if (sz < 4) return wrap_err(invalid);
		case io::EOF =>
			return if (n == 0) io::EOF else n;
		};

		let r = endian::begetu32(rbuf): rune;
		let rb = utf8::encoderune(r);
		if (len(buf) - n < len(rb)) {
			dataunread(s.d, rbuf);
			return n;
		};

		buf[n..n + len(rb)] = rb;
		n += len(rb);
	};
};

fn t61_decoder(s: *utf8stream, buf: []u8) (size | io::EOF | io::error) = {
	let inbuf: [2]u8 = [0...];
	let in = inbuf[..0];

	let n = 0z;

	for (true) {
		let chr: [1]u8 = [0];
		match (dataread(s.d, chr)?) {
		case let sz: size =>
			assert(sz == 1);
			static append(in, chr[0]);
		case io::EOF =>
			if (len(in) > 0) return wrap_err(invalid);
			if (n > 0) return n;
			return io::EOF;
		};

		match (t61_chardecode(in)) {
		case let r: rune =>
			let raw = utf8::encoderune(r);
			const bufremain = len(buf) - n;
			if (len(raw) < bufremain) {
				buf[n..n + len(raw)] = raw[..];
				n += len(raw);
				in = inbuf[..0];
			} else {
				dataunread(s.d, in);
				break;
			};
		case insufficient =>
			// leave combining char in in
			void;
		case invalid =>
			return wrap_err(invalid);
		};
	};

	return n;
};

fn newstrreader(d: *decoder, t: utag) (utf8stream | error) = {
	let strdec: *strdecoder = switch (t) {
	case utag::NUMERIC_STRING =>
		yield &num_decoder;
	case utag::PRINTABLE_STRING =>
		yield &print_decoder;
	case utag::IA5_STRING =>
		yield &ia5_decoder;
	case utag::UTF8_STRING =>
		yield &utf8_decoder;
	case utag::TELETEX_STRING =>
		yield &t61_decoder;
	case utag::BMP_STRING =>
		yield &bmp_decoder;
	case utag::UNIVERSAL_STRING =>
		yield &universal_decoder;
	case =>
		return invalid;
	};

	return utf8stream {
		stream = &utf8stream_vtable,
		d = d,
		strdec = strdec,
		...
	};
};

// Returns an [[utf8stream]] for a supported utag 't', which is one of:
//   * utag::NUMERIC_STRING
//   * utag::PRINTABLE_STRING
//   * utag::IA5_STRING
//   * utag::UTF8_STRING
//   * utag::TELETEX_STRING
//   * utag::BMP_STRING
//   * utag::UNIVERSAL_STRING
export fn strreader(d: *decoder, t: utag) (utf8stream | error) = {
	let dh = next(d)?;
	expect_utag(dh, t)?;
	return newstrreader(d, t)!;
};

// Reads a printable string into 'buf'.
export fn read_printstr(d: *decoder, buf: []u8) (size | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::PRINTABLE_STRING)?;

	const n = read_bytes(d, buf)?;

	for (let i = 0z; i < n; i += 1) {
		if (!c_is_print(buf[i])) {
			return invalid;
		};
	};
	return n;
};

// Reads an utf8 string into 'buf' and returns a str that borrows from buf.
export fn read_utf8str(d: *decoder, buf: []u8) (str | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::UTF8_STRING)?;

	let r = newstrreader(d, utag::UTF8_STRING)!;
	let n = 0z;

	for (true) {
		n += match (io::read(&r, buf[n..])) {
		case let sz: size =>
			yield sz;
		case io::EOF =>
			break;
		case let e: io::error =>
			return unwrap_err(e);
		};
	};

	return strings::fromutf8(buf[..n])!;
};
