use bufio;
use bytes;
use crypto::random;
use endian;
use fmt;
use io;
use strconv;
use strings;
use strio;

// A UUID.
export type uuid = [16]u8;

// The length of a UUID in bytes.
export def UUID_LEN: size = 16;

// The length of a UUID in runes when encoded as a string.
export def UUID_STRLEN: size = 36;

// The length of the return value of [[uri]] in runes.
export def UUID_URILEN: size = 45;

// The "nil" UUID, with all bits set to zero.
export const nil: uuid = [0...];

// Returned from [[decode]] if an invalid UUID is observed.
export type invalid = !void;

// Octet offsets of various fields as defined by the RFC.
def TIME_LOW: size = 0;
def TIME_MID: size = 4;
def TIME_HI_AND_VERSION: size = 6;
def CLOCK_SEQ_HI_AND_RESERVED: size = 8;
def CLOCK_SEQ_LOW: size = 9;
def NODE: size = 10;

// Generates a new version 4 UUID.
export fn generate() uuid = {
	let id: uuid = [0...];
	random::buffer(id[..]);
	let buf = id[CLOCK_SEQ_HI_AND_RESERVED..CLOCK_SEQ_HI_AND_RESERVED + 2];
	let clock = (endian::begetu16(buf) & 0x3FFF) | 0x8000;
	endian::beputu16(buf, clock);
	let buf = id[TIME_HI_AND_VERSION..TIME_HI_AND_VERSION + 2];
	let version = (endian::begetu16(buf) & 0x0FFF) | 0x4000;
	endian::beputu16(buf, version);
	return id;
};

// Returns true if two UUIDs are equal.
export fn compare(a: uuid, b: uuid) bool = bytes::equal(a, b);

// Encodes a UUID as a string and writes it to a stream.
export fn encode(out: *io::stream, in: uuid) (size | io::error) = {
	let z = 0z;
	for (let i = TIME_LOW; i < TIME_LOW + 4; i += 1) {
		z += fmt::fprintf(out, "{:02x}", in[i])?;
	};
	z += fmt::fprintf(out, "-")?;
	for (let i = TIME_MID; i < TIME_MID + 2; i += 1) {
		z += fmt::fprintf(out, "{:02x}", in[i])?;
	};
	z += fmt::fprintf(out, "-")?;
	for (let i = TIME_HI_AND_VERSION; i < TIME_HI_AND_VERSION + 2; i += 1) {
		z += fmt::fprintf(out, "{:02x}", in[i])?;
	};
	z += fmt::fprintf(out, "-{:02x}{:02x}-",
		in[CLOCK_SEQ_HI_AND_RESERVED], in[CLOCK_SEQ_LOW])?;
	for (let i = NODE; i < NODE + 6; i += 1) {
		z += fmt::fprintf(out, "{:02x}", in[i])?;
	};
	return z;
};

// Encodes a UUID as a URI and writes it to a stream.
export fn uri(out: *io::stream, in: uuid) (size | io::error) = {
	return fmt::fprintf(out, "urn:uuid:")? + encode(out, in)?;
};

// Encodes a UUID as a string. The return value is statically allocated, the
// caller must use [[strings::dup]] to extend its lifetime.
export fn encodestr(in: uuid) str = {
	static let buf: [UUID_STRLEN]u8 = [0...];
	let sink = strio::fixed(buf);
	defer io::close(sink);
	encode(sink, in) as size;
	return strio::string(sink);
};

// Encodes a UUID as a string. The return value is statically allocated, the
// caller must use [[strings::dup]] to extend its lifetime.
export fn encodeuri(in: uuid) str = {
	static let buf: [UUID_URILEN]u8 = [0...];
	let sink = strio::fixed(buf);
	defer io::close(sink);
	uri(sink, in) as size;
	return strio::string(sink);
};

// Decodes a UUID as a string from an [[io::stream]].
export fn decode(in: *io::stream) (uuid | invalid | io::error) = {
	let u: uuid = [0...];
	for (let i = 0z; i < len(u); i += 1) {
		let buf: [2]u8 = [0...];
		match (io::read(in, buf)?) {
			io::EOF => return invalid,
			z: size => assert(z == len(buf)),
		};
		u[i] = match (strconv::stou8b(
				strings::fromutf8_unsafe(buf),
				strconv::base::HEX)) {
			strconv::overflow => abort(),
			strconv::invalid => return invalid,
			u: u8 => u,
		};
		if (i + 1 == TIME_MID
				|| i + 1 == TIME_HI_AND_VERSION
				|| i + 1 == CLOCK_SEQ_HI_AND_RESERVED
				|| i + 1 == NODE) {
			match (io::read(in, buf[..1])?) {
				io::EOF => return invalid,
				z: size => assert(z == 1),
			};
			if (buf[0] != '-': u32: u8) {
				return invalid;
			};
		};
	};
	return u;
};

// Decodes a UUID from a string.
export fn decodestr(in: str) (uuid | invalid) = {
	let buf = bufio::fixed(strings::toutf8(in), io::mode::READ);
	defer io::close(buf);
	return match (decode(buf)) {
		err: io::error => abort(),
		invalid => invalid,
		u: uuid => u,
	};
};
