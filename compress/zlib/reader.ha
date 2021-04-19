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

type reader = struct {
	stream: io::stream,
	source: *io::stream,
	flate: *io::stream,
	hash: *hash::hash,
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
	decompress_err::HEADER => "Invalid zlib header",
	decompress_err::CHECKSUM => "Invalid zlib checksum",
	decompress_err::EOF => "Unexpected EOF",
	decompress_err::DICT => "Invalid dictionary",
	* => abort(),
};

fn wraperror(err: decompress_err) errors::opaque = {
	static assert(size(decompress_err) <= size(error::opaque_data));
	let wrapped = errors::opaque { strerror = &opaque_strerror, ... };
	let myptr = &wrapped.data: *decompress_err;
	*myptr = err;
	return wrapped;
};

fn verifysum(s: *reader) (io::EOF | io::error) = {
	let hash: [4]u8 = [0...];
	for (let n = 0z; n < len(hash)) {
		match (io::read(s.source, hash[n..])?) {
			io::EOF => return wraperror(decompress_err::EOF),
			z: size => n += z,
		};
	};
	let checksum = hash::sum(s.hash);
	defer free(checksum);
	return if (bytes::equal(checksum, hash)) io::EOF
		else wraperror(decompress_err::CHECKSUM);
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *reader;
	match (io::read(s.flate, buf)?) {
		io::EOF => return verifysum(s),
		z: size => buf = buf[..z],
	};
	hash::write(s.hash, buf);
};

fn close(s: *io::stream) void = {
	const s = s: *reader;
	io::close(s.flate);
	hash::close(s.hash);
};

// Creates a stream which decompresses zlib (RFC 1950) data.
export fn decompress(s: *io::stream) (*io::stream | io::error) = {
	let buf: [2]u8 = [0...];
	for (let n = 0z; n < len(buf)) {
		match (io::read(s, buf[n..])?) {
			io::EOF => return wraperror(decompress_err::EOF),
			z: size => n += z,
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
	return alloc(reader {
		stream = io::stream {
			reader = &read,
			closer = &close,
			...
		},
		source = s,
		flate = flate::inflate(s),
		hash = adler32::adler32(),
		...
	}): *io::stream;
};

@test fn decompress() void = {
	for (let i = 1z; i < len(vectors); i += 1) {
		let in = bufio::fixed(*vectors[i].1, io::mode::READ);
		let out = bufio::dynamic(io::mode::WRITE);
		let d = match (decompress(in)) {
			s: *io::stream => s,
			e: io::error => {
				fmt::errorln(io::strerror(e));
				abort();
			},
		};
		match (io::copy(out, d)) {
			_: size => void,
			e: io::error => {
				fmt::errorfln("vector {}: {}", i, io::strerror(e));
				abort();
			},
		};
		let s = bufio::finish(out);
		assert(bytes::equal(s, *vectors[i].0));
	};
};
