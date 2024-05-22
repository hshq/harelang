// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bytes;
use errors;
use fmt;
use io;
use memio;
use os;
use strconv;
use strings;

export type encoder = struct {
	stream: io::stream,
	out: io::handle,
	err: (void | io::error),
};

const encoder_vtable: io::vtable = io::vtable {
	writer = &encode_writer,
	...
};

// Creates a stream that encodes writes as lowercase hexadecimal before writing
// them to a secondary stream. Closing this stream will not close the underlying
// stream.
export fn newencoder(out: io::handle) encoder = {
	return encoder {
		stream = &encoder_vtable,
		out = out,
		err = void,
	};
};

fn encode_writer(s: *io::stream, in: const []u8) (size | io::error) = {
	const s = s: *encoder;
	match(s.err) {
	case let err: io::error =>
		return err;
	case void => void;
	};
	let z = 0z;
	for (let i = 0z; i < len(in); i += 1) {
		const r = strconv::u8tos(in[i], strconv::base::HEX_LOWER);
		if (len(r) == 1) {
			match(fmt::fprint(s.out, "0")) {
			case let b: size =>
				z += b;
			case let err: io::error =>
				s.err = err;
				return err;
			};
		};
		match(fmt::fprint(s.out, r)) {
		case let b: size =>
			z += b;
		case let err: io::error =>
			s.err = err;
			return err;
		};
	};
	return z;
};

// Encodes a byte slice as a hexadecimal string and returns it. The caller must
// free the return value.
export fn encodestr(in: []u8) str = {
	const out = memio::dynamic();
	const enc = newencoder(&out);
	io::writeall(&enc, in)!;
	return memio::string(&out)!;
};

@test fn encodestr() void = {
	let in: [_]u8 = [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D];
	let s = encodestr(in);
	defer free(s);
	assert(s == "cafebabedeadf00d");
};

// Encodes a byte slice as a hexadecimal string and writes it to an
// [[io::handle]].
export fn encode(out: io::handle, in: []u8) (size | io::error) = {
	const enc = newencoder(out);
	return io::writeall(&enc, in);
};

@test fn encode() void = {
	const in: [_]u8 = [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D];

	let out = memio::dynamic();
	defer io::close(&out)!;

	encode(&out, in)!;
	assert(memio::string(&out)! == "cafebabedeadf00d");
};

export type decoder = struct {
	stream: io::stream,
	in: io::handle,
	state: (void | io::EOF | io::error),
};

const decoder_vtable: io::vtable = io::vtable {
	reader = &decode_reader,
	...
};

// Creates a stream that reads and decodes hexadecimal data from a secondary
// stream.  This stream does not need to be closed, and closing it will not
// close the underlying stream.
export fn newdecoder(in: io::handle) decoder = {
	return decoder {
		stream = &decoder_vtable,
		in = in,
		state = void,
		...
	};
};

fn decode_reader(s: *io::stream, out: []u8) (size | io::EOF | io::error) = {
	const s = s: *decoder;
	match(s.state) {
	case let err: (io::EOF | io::error) =>
		return err;
	case void => void;
	};
	static let buf: [os::BUFSZ]u8 = [0...];
	let n = len(out) * 2;
	if (n > os::BUFSZ) {
		n = os::BUFSZ;
	};
	let nr = 0z;
	for (nr < n) {
		match(io::read(s.in, buf[nr..n])) {
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
	if (nr % 2 != 0) {
		s.state = errors::invalid;
		return errors::invalid;
	};
	const l = nr / 2;
	for (let i = 0z; i < l; i += 1) {
		const oct = strings::fromutf8_unsafe(buf[i * 2..i * 2 + 2]);
		const u = match (strconv::stou8(oct, 16)) {
		case (strconv::invalid | strconv::overflow) =>
			s.state = errors::invalid;
			return errors::invalid;
		case let u: u8 =>
			yield u;
		};
		out[i] = u;
	};
	return l;
};

// Decodes a string of hexadecimal bytes into a byte slice. The caller must free
// the return value.
export fn decodestr(s: str) ([]u8 | io::error) = {
	let s = strings::toutf8(s);
	const in = memio::fixed(s);
	const decoder = newdecoder(&in);
	const out = memio::dynamic();
	match(io::copy(&out, &decoder)) {
	case size =>
		return memio::buffer(&out);
	case let err: io::error =>
		return err;
	};
};

@test fn decode() void = {
	let s = decodestr("cafebabedeadf00d") as []u8;
	defer free(s);
	assert(bytes::equal(s, [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D]));

	decodestr("this is not hex") as io::error as errors::invalid: void;
};

// Outputs a dump of hex data alongside the offset and an ASCII representation
// (if applicable).
//
// Example output:
//
// 	00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
// 	00000010  03 00 3e 00 01 00 00 00  80 70 01 00 00 00 00 00  |..>......p......|
//
// If the addr parameter is provided, the address column will start from this
// address (but the data slice will still be printed from index 0).
export fn dump(out: io::handle, data: []u8, addr: u64 = 0) (void | io::error) = {
	let datalen = len(data): u64;

	for (let off = 0u64; off < datalen; off += 16) {
		fmt::fprintf(out, "{:.8x}  ", addr + off)?;

		let toff = 0z;
		for (let i = 0u64; i < 16 && off + i < datalen; i += 1) {
			let val = data[off + i];
			toff += fmt::fprintf(out, "{}{:.2x} ",
				if (i == 8) " " else "", val)?;
		};

		// Align ASCII representation, max width of hex part (48) +
		// spacing around it
		for (toff < 50; toff += 1) {
			fmt::fprint(out, " ")?;
		};

		fmt::fprint(out, "|")?;
		for (let i = 0u64; i < 16 && off + i < datalen; i += 1) {
			let r = data[off + i]: rune;

			fmt::fprint(out, if (ascii::isprint(r)) r else '.')?;
		};
		fmt::fprint(out, "|\n")?;
	};
};

@test fn dump() void = {
	let in: [_]u8 = [
		0x7F, 0x45, 0x4c, 0x46, 0x02, 0x01, 0x01, 0x00, 0xCA, 0xFE,
		0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D, 0xCE, 0xFE, 0xBA, 0xBE,
		0xDE, 0xAD, 0xF0, 0x0D
	];

	let sink = memio::dynamic();
	defer io::close(&sink)!;
	dump(&sink, in) as void;

	let s = memio::string(&sink)!;
	assert(s ==
		"00000000  7f 45 4c 46 02 01 01 00  ca fe ba be de ad f0 0d  |.ELF............|\n"
		"00000010  ce fe ba be de ad f0 0d                           |........|\n");
};
