use bufio;
use bytes;
use errors;
use io;
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
	let runes = strings::runes(alphabet);
	assert(len(runes) == 32);
	defer free(runes);
	for (let i: u8 = 0; i < 32; i += 1) {
		let ch = runes[i]: u32: u8;
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

export type decoder = struct {
	io::stream,
	in: io::handle,
	enc: *encoding,
	avail: []u8, // leftover decoded output
	pad: bool, // if padding was seen in a previous read
	state: (void | io::EOF | io::error),
};

// Creates a stream that decodes base-32 input from a secondary stream. This
// stream does not need to be closed, and closing it will not close the
// underlying stream.
export fn new_decoder(
	in: io::handle,
	enc: *encoding,
) decoder = {
	return decoder {
		reader = &decode_reader,
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
	static let obuf: [os::BUFSIZ / 8 * 5]u8 = [0...];
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
	for (let i = nr: i64 - 1; i >= 0; i -= 1) {
		const ch = buf[i];
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
	for (let i = n; i < n + rem; i += 1) {
		out[i] = obuf[i - n];
	};
	s.avail = obuf[rem..navl];
	return n + rem;
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
		let in = bufio::fixed(strings::toutf8(cases[i].0), io::mode::READ);
		let dec = new_decoder(&in, cases[i].2);
		let buf: [1]u8 = [0];
		let out: []u8 = [];
		defer free(out);
		for (true) match (io::read(&dec, buf)!) {
		case let z: size =>
			if (z > 0) {
				append(out, buf[0]);
			};
		case io::EOF =>
			break;
		};
		assert(bytes::equal(out, strings::toutf8(cases[i].1)));
	};
	// Repeat of the above, but with a larger buffer
	for (let i = 0z; i < len(cases); i += 1) {
		let in = bufio::fixed(strings::toutf8(cases[i].0), io::mode::READ);
		let dec = new_decoder(&in, cases[i].2);
		let buf: [1024]u8 = [0...];
		let out: []u8 = [];
		defer free(out);
		for (true) match (io::read(&dec, buf)!) {
		case let z: size =>
			if (z > 0) {
				append(out, buf[..z]...);
			};
		case io::EOF =>
			break;
		};
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
		let in = bufio::fixed(strings::toutf8(invalid[i].0), io::mode::READ);
		let dec = new_decoder(&in, invalid[i].1);
		let buf: [1]u8 = [0...];
		let valid = false;
		for (true) match(io::read(&dec, buf)) {
		case errors::invalid=>
			break;
		case size =>
			valid = true;
		case io::EOF =>
			break;
		};
		assert(valid == false, "valid is not false");
	};
};

export type encoder = struct {
	io::stream,
	out: io::handle,
	enc: *encoding,
	buf: [4]u8, // leftover input
	avail: size, // bytes available in buf
	err: (void | io::error),
};

// Creates a stream that encodes data into base-32 and writes to a secondary
// stream. This stream needs to be closed to flush out unwritten bytes, as
// base-32 encoding operates in 5-byte blocks. Closing this stream will not
// close the underlying stream.
export fn new_encoder(
	out: io::handle,
	enc: *encoding,
) encoder = {
	return encoder {
		writer = &encode_writer,
		closer = &encode_closer,
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
	let n = 0z; // number of bytes processed
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
		case size =>
			yield;
		};
		n += 5;
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
	return n;
};

fn encode_closer(s: *io::stream) void = {
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
	io::write(s.out, encb)!; // TODO https://todo.sr.ht/~sircmpwn/hare/568
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
		let out = bufio::dynamic(io::mode::RDWR);
		let enc = new_encoder(&out, &std_encoding);
		io::write(&enc, in[..i]) as size;
		io::close(&enc);
		let outb = bufio::buffer(&out);
		assert(bytes::equal(outb, strings::toutf8(expect[i])));
		free(outb);

		out = bufio::dynamic(io::mode::RDWR);
		enc = new_encoder(&out, &hex_encoding);
		io::write(&enc, in[..i]) as size;
		io::close(&enc);
		outb = bufio::buffer(&out);
		assert(bytes::equal(outb, strings::toutf8(expect_hex[i])));
		free(outb);
	};
};