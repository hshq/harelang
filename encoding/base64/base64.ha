use bufio;
use bytes;
use io;
use strio;
use strings;
use errors;

// RFC 4648 standard "base64" base 64 encoding alphabet.
export const standard: []u8 = [
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/'
];

// RFC 4648 URL and filename safe "base64url" base 64 encoding alphabet.
export const urlsafe: []u8 = [
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '-', '_'
];

// The padding character used at the end of encoding.
export def PADDING: u8 = '=': u32: u8;

// Encodes a byte slice using a base 64 encoding alphabet, with padding, and
// writes it to an [[io::handle]]. The number of bytes written is returned.
export fn encode(
	alphabet: []u8,
	sink: io::handle,
	b: []u8
) (size | io::error) = {
	let z = 0z;
	let i = 0z;
	for (i + 2 < len(b); i += 3) {
		z += io::write(sink, [
			alphabet[b[i] >> 2],
			alphabet[(b[i] & 0x3) << 4 | b[i + 1] >> 4],
			alphabet[(b[i + 1] & 0xf) << 2 | b[i + 2] >> 6],
			alphabet[b[i + 2] & 0x3F],
		])?;
	};
	if (len(b) - i > 0) {
		if (len(b) - i == 2) {
			z += io::write(sink, [
				alphabet[b[i] >> 2],
				alphabet[(b[i] & 0x3) << 4 | b[i + 1] >> 4],
				alphabet[(b[i + 1] & 0xf) << 2],
				PADDING,
			])?;
		} else {
			z += io::write(sink, [
				alphabet[b[i] >> 2],
				alphabet[(b[i] & 0x3) << 4],
				PADDING,
				PADDING,
			])?;
		};
	};
	return z;
};

// Encodes a byte slice using a base 64 encoding alphabet, with padding, and
// returns it. The caller must free the return value.
export fn encodestr(alphabet: []u8, b: []u8) str = {
	let sink = strio::dynamic();
	encode(alphabet, &sink, b) as size;
	return strio::string(&sink);
};

@test fn encode() void = {
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
		let s = encodestr(standard, in[..i]);
		defer free(s);
		assert(s == expect[i]);
	};
};

// Decodes base 64-encoded data in the given base 64 alphabet, with padding,
// from an [[io::handle]]. The number of bytes written is returned.
export fn decode(
	alphabet: []u8,
	in: io::handle,
	out: io::handle,
) (size | errors::invalid | io::error) = {
	let dec = decoder(alphabet, in);
	match (io::copy(out, &dec)) {
	case let err: io::error =>
		match (err) {
		case errors::invalid =>
			return errors::invalid;
		case =>
			return err;
		};
	case let s: size =>
		return s;
	};
};

// Decodes base 64-encoded data in the given base 64 alphabet, with padding,
// from an [[io::handle]]. The number of bytes written is returned.
export fn decode_static(
	alphabet: []u8,
	out: []u8,
	in: io::handle,
) (size | errors::invalid | io::error) = {
	let buf = bufio::fixed(out, io::mode::WRITE);
	let dec = decoder(alphabet, in);
	match (io::copy(&buf, &dec)) {
	case let err: io::error =>
		match (err) {
		case errors::invalid =>
			return errors::invalid;
		case =>
			return err;
		};
	case let s: size =>
		return s;
	};
};

// Decodes a string of base 64-encoded data in the given base 64 encoding
// alphabet, with padding, into a byte slice. The caller must free the return
// value.
export fn decodestr(alphabet: []u8, in: str) ([]u8 | errors::invalid) = {
	return decodeslice(alphabet, strings::toutf8(in));
};

// Decodes a string of base 64-encoded data in the given base 64 encoding
// alphabet, with padding. The number of bytes written is returned.
export fn decodestr_static(
	alphabet: []u8,
	out: []u8,
	in: str,
) (size | errors::invalid) = {
	return decodeslice_static(alphabet, out, strings::toutf8(in));
};

// Decodes a byte slice of base 64-encoded data in the given base 64 encoding
// alphabet, with padding, into a byte slice. The caller must free the return
// value.
export fn decodeslice(alphabet: []u8, in: []u8) ([]u8 | errors::invalid) = {
	let out = bufio::dynamic(io::mode::WRITE);
	let in = bufio::fixed(in, io::mode::READ);
	let dec = decoder(alphabet, &in);
	match (io::copy(&out, &dec)) {
	case io::error =>
		io::close(&out);
		return errors::invalid;
	case size =>
		return bufio::buffer(&out);
	};
};

// Decodes a byte slice of base 64-encoded data in the given base 64 encoding
// alphabet, with padding. The number of bytes written is returned.
export fn decodeslice_static(
	alphabet: []u8,
	out: []u8,
	in: []u8,
) (size | errors::invalid) = {
	let in = bufio::fixed(in, io::mode::READ);
	match (decode_static(alphabet, out, &in)) {
	case let s: size =>
		return s;
	case errors::invalid =>
		return errors::invalid;
	case =>
		abort();
	};
};

@test fn decode() void = {
	const in: [_]str = [
		"",
		"Zg==",
		"Zm8=",
		"Zm9v",
		"Zm9vYg==",
		"Zm9vYmE=",
		"Zm9vYmFy",
	];
	const expect: [_]u8 = ['f', 'o', 'o', 'b', 'a', 'r'];
	for (let i = 0z; i < len(in); i += 1) {
		let s = decodestr(standard, in[i]) as []u8;
		defer free(s);
		assert(bytes::equal(s, expect[..i]));
	};

	const bad: [_]str = [
		"A",
		"AA",
		"AAA",
		"!!!!",
		"====",
		"A=A=",
		"AA=A",
		"Zg==Zg==",
	];
	for (let i = 0z; i < len(bad); i += 1) {
		let result = decodestr(standard, bad[i]);
		assert(result is errors::invalid);
	};
};

const INVALID_OR_PAD: u8 = 255;

// Initialize a new base64 decoder stream wrapping the given [[io::handle]]
export fn decoder(alphabet: []u8, in: io::handle) decode_stream = {
	let decoder: [256]u8 = [INVALID_OR_PAD...];
	for (let i = 0z; i < len(alphabet); i += 1) {
		decoder[alphabet[i]] = i: u8;
	};
	return decode_stream {
		reader = &decodestream_reader,
		input = in,
		decoder = decoder,
		...
	};
};

// An stream interface for base64. Wraps an [[io::handle]] and does on-the-fly
// decoding with calls to read().
export type decode_stream = struct {
	io::stream,
	input: io::handle,
	buf: [4]u8,
	avail: size, // How many bytes are already decoded, but didn't fit in a previous read
	waseof: bool,
	decoder: [256]u8,
};

fn decodestream_reader(s: *io::stream, out: []u8) (size | io::EOF | io::error) = {
	assert(len(out) > 0, "zero-length buffer provided");
	let s = s : *decode_stream;
	let z = 0z;
	let decoder = s.decoder;
	let buf = s.buf;

	// We may have already decoded some bytes that couldn't be pushed out
	// in a previous call to read.
	if (s.avail > 0) {
		z += if (len(out) < s.avail) len(out) else s.avail;
		out[..z] = s.buf[..z];
		s.avail -= z;
		s.buf[..s.avail] = s.buf[z..z+s.avail];
		out = out[z..];
		if (len(out) == 0) {
			return z;
		};
	};

	if (s.waseof) {
		return io::EOF;
	};

	// If we get here, we have pushed out all cached bytes and are ready to
	// read some more. Reset the internal buffer here.
	buf = [INVALID_OR_PAD...];
	for (true) match (io::read(s.input, buf)?) {
	case size =>
		for (let i = 0z; i < 2; i += 1) {
			if (decoder[buf[i]] == INVALID_OR_PAD) {
				return errors::invalid;
			} else {
				buf[i] = decoder[buf[i]];
			};
		};

		if (decoder[buf[2]] == INVALID_OR_PAD) {
			if (buf[2] != PADDING) {
				return errors::invalid;
			};
			if (buf[3] != PADDING) {
				return errors::invalid;
			};
			s.buf[0] = buf[0] << 2 | buf[1] >> 4;
			s.avail += 1;
			// End of stream...
			let extra: []u8 = [0];
			match (io::read(s.input, extra)?) {
			case size =>
				return errors::invalid;
			case io::EOF =>
				s.waseof = true;
				if (len(out) > 0) {
					out[0] = s.buf[0];
					z += 1;
					s.avail = 0;
				};
				break;
			};
		} else {
			buf[2] = decoder[buf[2]];
		};

		if (decoder[buf[3]] == INVALID_OR_PAD) {
			if (buf[3] != PADDING) {
				return errors::invalid;
			};
			s.buf[..2] = [
				buf[0] << 2 | buf[1] >> 4,
				buf[1] << 4 | buf[2] >> 2,
			];
			s.avail += 2;
			let extra: []u8 = [0];
			match (io::read(s.input, extra)?) {
			case size =>
				return errors::invalid;
			case io::EOF =>
				let n = if (len(out) < s.avail) len(out) else s.avail;
				out[..n] = s.buf[..n];
				s.avail -= n;
				out = out[n..];
				s.buf[..s.avail] = s.buf[n..n+s.avail];
				s.waseof = true;
				z += n;
				break;
			};
		} else {
			buf[3] = decoder[buf[3]];
		};

		s.buf[..3] = [
			buf[0] << 2 | buf[1] >> 4,
			buf[1] << 4 | buf[2] >> 2,
			buf[2] << 6 | buf[3]
		];
		s.avail += 3;

		let n = if (len(out) < s.avail) len(out) else s.avail;
		out[..n] = s.buf[..n];
		s.avail -= n;
		out = out[n..];
		s.buf[..s.avail] = s.buf[n..n+s.avail];
		z += n;

		if (len(out) == 0) {
			break;
		};
	case io::EOF =>
		s.waseof = true;
		if (z == 0) {
			return io::EOF;
		};
		break;
	};
	return z;
};

@test fn decode_stream() void = {

	const cases: [](str, str) = [
		("Y2hhbmdlbQ==", "changem"),
		("Y2hhbmdlbWU=", "changeme"),
		("Y2hhbmdlbWVt", "changemem"),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		let s = cases[i].0;
		let expected = cases[i].1;

		let b = strings::toutf8(s);
		let input = bufio::fixed(b, io::mode::READ);

		let dec = decoder(standard, &input);
		defer io::close(&dec);

		let buf: [1]u8 = [0];
		let out: []u8 = [];
		defer free(out);

		for (true) match (io::read(&dec, buf)!) {
		case let z: size =>
			append(out, buf[0]);
			assert(z == 1);
		case io::EOF =>
			break;
		};

		assert(bytes::equal(out, strings::toutf8(expected)));
	};

	// Repeat of the above, but with a larger buffer
	for (let i = 0z; i < len(cases); i += 1) {
		let s = cases[i].0;
		let expected = cases[i].1;

		let b = strings::toutf8(s);
		let input = bufio::fixed(b, io::mode::READ);

		let dec = decoder(standard, &input);
		defer io::close(&dec);

		let buf: [24]u8 = [0...];
		let out: []u8 = [];
		defer free(out);

		for (true) match (io::read(&dec, buf)!) {
		case let z: size =>
			append(out, buf[..z]...);
		case io::EOF =>
			break;
		};

		assert(bytes::equal(out, strings::toutf8(expected)));
	};
};
