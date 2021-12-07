use bufio;
use bytes;
use endian;
use errors;
use fmt;
use io;

def BUFSIZE: size = 1 << 16;
def MAXBITS: size = 15;
def MAXCODES: size = 288;

const fixed_len: huffman = huffman {
	counts = [0...],
	symbols = [0...],
};

const fixed_dist: huffman = huffman {
	counts = [0...],
	symbols = [0...],
};

export type huffman = struct {
	counts: [MAXBITS]u16,
	symbols: [MAXCODES]u16,
};

type inflate_err = enum u8 {
	EOF,
	BTYPE,
	LEN,
	DISTANCE,
	CODE,
	HUFFMAN,
	TABLE,
};

export type decompressor = struct {
	io::stream,
	in: io::handle,
	bitbuf: u32,
	cnt: u32,
	final: bool,
	state: *fn(d: *decompressor) (void | io::EOF | io::error),
	left: size,
	hl: huffman,
	hd: huffman,

	// History ring buffer
	hist: []u8,
	head: size,

	// Output buffer
	buf: []u8,
	bufstart: []u8,
};

@init fn init_fixed() void = {
	// See section 3.2.6 of RFC 1951
	let lens: [288]u16 = [0...];
	let i = 0z;
	for (i < 144; i += 1) {
		lens[i] = 8;
	};
	for (i < 256; i += 1) {
		lens[i] = 9;
	};
	for (i < 280; i += 1) {
		lens[i] = 7;
	};
	for (i < 288; i += 1) {
		lens[i] = 8;
	};
	construct(&fixed_len, lens[..]) as void;

	let dists: [30]u16 = [5...];
	construct(&fixed_dist, dists[..]) as void;
};

// Creates a stream which decompresses Deflate (RFC 1951) data.
export fn inflate(src: io::handle) decompressor = decompressor {
	reader = &read,
	closer = &close,
	in = src,
	bitbuf = 0,
	cnt = 0,
	final = false,
	state = &uncompressed_read,
	left = 0,

	hist = [],
	head = 0,

	buf = [],
	bufstart = [],
	...
};

// Read [[want]] bits from the decompressor
fn bits(d: *decompressor, want: u32) (u32 | io::error) = {
	assert(want <= 32);
	let val = d.bitbuf;
	for (d.cnt < want) {
		let buf: [_]u8 = [0];
		match (io::read(d.in, buf)?) {
		case io::EOF =>
			return wraperror(inflate_err::EOF);
		case let z: size =>
			if (z < 1) {
				continue; // Short read, retry
			};
		};
		val |= buf[0] << d.cnt;
		d.cnt += 8;
	};
	d.bitbuf = val >> want;
	d.cnt -= want;
	assert(d.cnt <= 7);
	return val & (1 << want) - 1;
};

fn put(d: *decompressor, b: u8...) void = {
	assert(len(d.buf) == 0 || d.buf: *[*]u8 == d.bufstart: *[*]u8);
	assert(len(d.hist) <= BUFSIZE);
	if (len(d.buf) == 0) {
		d.bufstart = d.bufstart[..0];
	};
	append(d.bufstart, b...);
	d.buf = d.bufstart;
	let n = BUFSIZE - len(d.hist);
	if (n > len(b)) {
		n = len(b);
	};
	append(d.hist, b[..n]...);
	b = b[n..];
	d.head += n;
	for (let s = b; len(s) != 0) {
		assert(len(d.buf) == BUFSIZE);
		const toput = if (d.head + len(s) > len(d.hist))
			len(d.hist) - d.head else len(s);
		d.hist[d.head..d.head + toput] = s[..toput];
		d.head = (d.head + toput) % BUFSIZE;
		s = s[toput..];
	};
};

fn copy(d: *decompressor, back: size, n: size) (void | io::error) = {
	if (len(d.hist) < back) {
		return wraperror(inflate_err::DISTANCE);
	};
	for (let i = 0z; i < n; i += 1) {
		put(d, d.hist[(d.head - back + BUFSIZE) % BUFSIZE]);
	};
};

fn decode(d: *decompressor, h: huffman) (u16 | io::error) = {
	let code = 0u32, index = 0u32, first = 0u32;
	for (let i = 1z; i < MAXBITS; i += 1) {
		code |= bits(d, 1)?;
		if (code < first + h.counts[i]) {
			return h.symbols[index + (code - first)];
		};
		index += h.counts[i];
		first += h.counts[i];
		first <<= 1;
		code <<= 1;
	};
	return wraperror(inflate_err::CODE);
};

fn construct(h: *huffman, lens: []u16) (void | io::error) = {
	h.counts = [0...];
	for (let i = 0z; i < len(lens); i += 1) {
		h.counts[lens[i]] += 1;
	};
	if (h.counts[0] == len(lens)) return;

	for (let left = 1z, i = 1z; i < MAXBITS; i += 1) {
		left <<= 1;
		left -= h.counts[i];
		if (left < 0) return wraperror(inflate_err::HUFFMAN);
	};

	let offs: [MAXBITS + 1]u16 = [0...];
	for (let i = 1z; i < MAXBITS; i += 1) {
		offs[i + 1] = offs[i] + h.counts[i];
	};

	for (let i = 0u16; i < len(lens); i += 1) if (lens[i] != 0) {
		let off = offs[lens[i]];
		offs[lens[i]] += 1;
		h.symbols[off] = i;
	};
};

fn compressed_read(d: *decompressor) (void | io::EOF | io::error) = {
	static const lbases: [_]u32 = [
		3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43,
		51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
	];
	static const lexts: [_]u32 = [
		0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3,
		4, 4, 4, 4, 5, 5, 5, 5, 0,
	];
	static const dbases: [_]u32 = [
		1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257,
		385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289,
		16385, 24577,
	];
	static const dexts: [_]u32 = [
		0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9,
		9, 10, 10, 11, 11, 12, 12, 13, 13,
	];

	let c = decode(d, d.hl)?;
	if (c < 256) {
		put(d, c: u8);
		return;
	};
	if (c == 256) {
		d.left = 0;
		return;
	};

	const n = lbases[c - 257] + bits(d, lexts[c - 257])?;
	c = decode(d, d.hd)?;
	const back = dbases[c] + bits(d, dexts[c])?;
	copy(d, back, n)?;
};

fn uncompressed_read(d: *decompressor) (void | io::EOF | io::error) = {
	static let _buf: [1024]u8 = [0...];
	let buf = if (len(_buf) > d.left: size) _buf[..d.left] else _buf[..];
	let z = match (io::read(d.in, buf)?) {
	case let z: size =>
		d.left -= z;
		yield z;
	case io::EOF =>
		return wraperror(inflate_err::EOF);
	};
	put(d, buf[..z]...);
};

fn opaque_strerror(
	data: *errors::opaque_data
) const str = switch (*(data: *inflate_err)) {
case inflate_err::EOF =>
	yield "Unexpected EOF";
case inflate_err::BTYPE =>
	yield "Invalid block type";
case inflate_err::LEN =>
	yield "Invalid block length";
case inflate_err::DISTANCE =>
	yield "Invalid distance";
case inflate_err::CODE =>
	yield "Invalid Huffman code";
case inflate_err::HUFFMAN =>
	yield "Oversubscribed Huffman code";
case inflate_err::TABLE =>
	yield "Invalid dynamic Huffman code table";
};

fn wraperror(err: inflate_err) errors::opaque = {
	static assert(size(inflate_err) <= size(errors::opaque_data));
	let wrapped = errors::opaque { strerror = &opaque_strerror, ... };
	let myptr = &wrapped.data: *inflate_err;
	*myptr = err;
	return wrapped;
};

fn dynamic(d: *decompressor) (void | io::EOF | io::error) = {
	const hlit = bits(d, 5)? + 257;
	const hdist = bits(d, 5)? + 1;
	const hclen = bits(d, 4)? + 4;

	if (hlit > 286 || hdist > 30) return wraperror(inflate_err::TABLE);
	let codes: [19]u16 = [0...];
	static const order = [
		16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1,
		15,
	];
	for (let i = 0z; i < hclen; i += 1) {
		codes[order[i]] = bits(d, 3)?: u16;
	};
	let hcl = huffman {
		counts = [0...],
		symbols = [0...],
	};
	construct(&hcl, codes[..])?;
	let lens: []u16 = [];
	defer free(lens);
	for (len(lens) < hlit + hdist) {
		let c = decode(d, hcl)?;
		if (c < 16) {
			append(lens, c);
			continue;
		};
		let n = 0u16;
		let times = switch (c) {
		case 16 =>
			if (len(lens) == 0) {
				return wraperror(inflate_err::TABLE);
			};
			n = lens[len(lens) - 1];
			yield 3 + bits(d, 2)?;
		case 17 =>
			yield 3 + bits(d, 3)?;
		case 18 =>
			yield 11 + bits(d, 7)?;
		case =>
			abort();
		};
		for (times > 0; times -= 1) {
			append(lens, n);
		};
	};
	if (len(lens) < 256 || lens[256] == 0) {
		return wraperror(inflate_err::TABLE);
	};
	construct(&d.hl, lens[..hlit])?;
	construct(&d.hd, lens[hlit..hlit + hdist])?;
	d.state = &compressed_read;
	d.left = 1;
};

fn next(d: *decompressor) (void | io::EOF | io::error) = {
	if (d.final) {
		return io::EOF;
	};
	if (bits(d, 1)? == 1) {
		d.final = true;
	};
	switch (bits(d, 2)?) {
	case 0b00 =>
		// Skip to next byte boundary
		d.cnt = 0;
		d.bitbuf = 0;
		let buf: [4]u8 = [0...];
		for (let n = 0z; n < 4) {
			match (io::read(d.in, buf[n..])?) {
			case io::EOF =>
				return wraperror(inflate_err::EOF);
			case let z: size =>
				n += z;
			};
		};
		const length = endian::legetu16(buf[..2]);
		if (length != ~endian::legetu16(buf[2..])) {
			return wraperror(inflate_err::LEN);
		};
		d.state = &uncompressed_read;
		d.left = length;
	case 0b01 =>
		d.hl = fixed_len;
		d.hd = fixed_dist;
		d.state = &compressed_read;
		d.left = 1;
	case 0b10 =>
		return dynamic(d);
	case 0b11 =>
		return wraperror(inflate_err::BTYPE);
	case =>
		abort();
	};
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	const s = s: *decompressor;
	let n = 0z;
	let a = buf;
	for (n < len(buf)) {
		if (len(s.buf) == 0) {
			if (s.left == 0) match (next(s)?) {
			case void => void;
			case io::EOF =>
				return if (n == 0) io::EOF else n;
			};
			match (s.state(s)?) {
			case void => void;
			case io::EOF =>
				return if (n == 0) io::EOF else n;
			};
		};
		const toread =
			if (len(s.buf) > len(buf)) len(buf) else len(s.buf);
		buf[..toread] = s.buf[..toread];
		s.buf = s.buf[toread..];
		buf = buf[toread..];
		n += toread;
	};
	return n;
};

fn close(s: *io::stream) void = {
	const s = s: *decompressor;
	free(s.bufstart);
	free(s.hist);
};

// Further testing is done in compress::zlib
@test fn inflate() void = {
	const in: []u8 = [
		// Non-final block, uncompressed
		0b00000000,
		// 4 bytes long
		0b00000100,
		0b00000000,
		// ~LEN
		0b11111011,
		0b11111111,
		// Data
		0xDE, 0xAD, 0xBE, 0xEF,
		// Final block, uncompressed
		0b00000001,
		// 2 bytes long
		0b00000010,
		0b00000000,
		// ~LEN
		0b11111101,
		0b11111111,
		// Data
		0x42, 0x69,
	];
	let expected: []u8 = [0xDE, 0xAD, 0xBE, 0xEF, 0x42, 0x69];

	let ins = bufio::fixed(in, io::mode::READ);
	let outs = bufio::dynamic(io::mode::WRITE);
	let s = inflate(ins);
	defer io::close(&s);
	match (io::copy(outs, &s)) {
	case size => void;
	case let e: io::error =>
		fmt::errorln(io::strerror(e))!;
		abort();
	};
	let out = bufio::finish(outs);
	defer free(out);
	assert(bytes::equal(expected, out));
};
