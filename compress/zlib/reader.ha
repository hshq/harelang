use bufio;
use bytes;
use compress::flate;
use endian;
use errors;
use fmt;
use hash::adler32;
use hash;
use io;

def CM: u8     = 0b00001111;
def CINFO: u8  = 0b11110000;

def FCHECK: u8 = 0b00011111;
def FDICT: u8  = 0b00100000;
def FLEVEL: u8 = 0b11000000;

export type reader = struct {
	io::stream,
	source: *io::stream,
	flate: flate::decompressor,
	hash: adler32::state,
};

type decompress_err = enum {
	HEADER,
	CHECKSUM,
	EOF,
	DICT,
};

fn opaque_strerror(
	data: *errors::opaque_data
) const str = switch (*(data: *decompress_err)) {
case decompress_err::HEADER =>
	yield "Invalid zlib header";
case decompress_err::CHECKSUM =>
	yield "Invalid zlib checksum";
case decompress_err::EOF =>
	yield "Unexpected EOF";
case decompress_err::DICT =>
	yield "Invalid dictionary";
case =>
	abort();
};

fn wraperror(err: decompress_err) errors::opaque = {
	static assert(size(decompress_err) <= size(error::opaque_data));
	let wrapped = errors::opaque { strerror = &opaque_strerror, ... };
	let myptr = &wrapped.data: *decompress_err;
	*myptr = err;
	return wrapped;
};

fn verifysum(s: *reader) (io::EOF | io::error) = {
	let hash: [adler32::SIZE]u8 = [0...];

	for (let n = 0z; n < len(hash)) {
		match (io::read(s.source, hash[n..])?) {
		case io::EOF =>
			return wraperror(decompress_err::EOF);
		case z: size =>
			n += z;
		};
	};

	return if (adler32::sum32(&s.hash) == endian::begetu32(hash)) io::EOF
		else wraperror(decompress_err::CHECKSUM);
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *reader;
	match (io::read(&s.flate, buf)?) {
	case io::EOF =>
		return verifysum(s);
	case z: size =>
		buf = buf[..z];
	};
	return hash::write(&s.hash, buf);
};

fn close(s: *io::stream) void = {
	const s = s: *reader;
	io::close(&s.flate);
};

// Creates a stream which decompresses zlib (RFC 1950) data.
export fn decompress(s: *io::stream) (reader | io::error) = {
	let buf: [2]u8 = [0...];
	for (let n = 0z; n < len(buf)) {
		match (io::read(s, buf[n..])?) {
		case io::EOF =>
			return wraperror(decompress_err::EOF);
		case z: size =>
			n += z;
		};
	};
	if (buf[0] & CM != 8) {
		return wraperror(decompress_err::HEADER);
	};
	// XXX: Should we tell compress::flate to allocate a smaller buffer on
	// CINFO < 7?
	if ((buf[0] & CINFO) >> 4 > 7) {
		return wraperror(decompress_err::HEADER);
	};
	if ((buf[0] << 8 | buf[1]) % 31 != 0) {
		// Invalid FCHECK
		return wraperror(decompress_err::HEADER);
	};
	if ((buf[1] & FDICT == 1)) {
		// TODO: Allow the caller to pass in a list of dictionaries to
		// be tried
		return wraperror(decompress_err::DICT);
	};
	return reader {
		reader = &read,
		closer = &close,
		source = s,
		flate = flate::inflate(s),
		hash = adler32::adler32(),
		...
	};
};

@test fn decompress() void = {
	for (let i = 1z; i < len(vectors); i += 1) {
		let in = bufio::fixed(*vectors[i].1, io::mode::READ);
		let out = bufio::dynamic(io::mode::WRITE);
		let d = match (decompress(in)) {
		case s: reader =>
			yield s;
		case e: io::error =>
			fmt::errorln(io::strerror(e))!;
			abort();
		};
		match (io::copy(out, &d)) {
		case size => void;
		case e: io::error =>
			fmt::errorfln("vector {}: {}", i, io::strerror(e))!;
			abort();
		};
		let s = bufio::finish(out);
		assert(bytes::equal(s, *vectors[i].0));
	};
};
