// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use bytes;
use errors;
use io;
use math::{bit_size_u8};
use os;
use strings;
use time::chrono;
use time::date;
use types;


def TAGMASK: u8 = 0x1f;
def MAX_CONS_DEPTH: size = 32;

// Each DER entry starts with an header that describes the content.
export type head = struct {

	// Tells whether the data is constructed and encapsulates multiple
	// other data fields; or primitive and the value follows.
	cons: bool,

	// Class info
	class: class,

	// Tag id of the data
	tagid: u32,

	// Start position in stream
	start: size,

	// Start position of data in stream
	data: size,

	// End position in stream
	end: size,

	implicit: bool,
};

fn head_endpos(d: head) size = d.end;

// Size of current element (header size + data size)
export fn sz(d: head) size = d.end - d.start;

// Size of the encoded data.
export fn dsz(d: head) size = d.end - d.data;

export type decoder = struct {
	src: io::handle,
	pos: size,
	cstack: [MAX_CONS_DEPTH]head,
	cstackp: size,
	next: (void | head),
	cur: (void | head),
	unbuf: [3]u8,
	unbufn: u8,
	implicit: bool,
};

// Creates a new DER decoder that reads from 'src'. A buffered stream (see
// [[bufio]]) is recommended for efficiency, as the decoder performs mostly
// short reads.
//
// Each entry must be read in its entirety before the next one is attended to.
// The user must call [[finish]] when finished with the decoder to ensure that
// the entire input was read correctly.
export fn derdecoder(src: io::handle) decoder = {
	return decoder {
		src = src,
		pos = 0,
		cstackp = 0,
		cur = void,
		next = void,
		implicit = false,
		...
	};
};

// Verifies that the entire input to the decoder was read.
export fn finish(d: *decoder) (void | error) = {
	if (d.cstackp != 0 || d.next is head) return invalid;
	match (d.cur) {
	case void =>
		return;
	case let h: head =>
		if (h.end != d.pos) return invalid;
	};
};

// Returns last opened cons or void if none is open.
fn curcons(d: *decoder) (void | head) = {
	if (d.cstackp == 0) {
		return;
	};
	return d.cstack[d.cstackp-1];
};

// Peeks the header of the next data field. Fails with [[badformat]] if no data
// follows.
export fn peek(d: *decoder) (head | error) = {
	match (trypeek(d)?) {
	case io::EOF =>
		return badformat;
	case let h: head =>
		return h;
	};
};

// Tries to peek the header of the next data field, or returns EOF if none
// exists.
export fn trypeek(d: *decoder) (head | error | io::EOF) = {
	if (!(d.next is void)) {
		return d.next: head;
	};

	if (is_endofcons(d)) return io::EOF;

	match (parse_header(d)?) {
	case io::EOF =>
		const unreaddata = d.unbufn > 0;
		if (d.cstackp != 0 || unreaddata) {
			return badformat;
		};
		return io::EOF;
	case let dh: head =>
		d.next = dh;
		return dh;
	};
};

// Cons is open and end is reached.
fn is_endofcons(d: *decoder) bool = {
	match (curcons(d)) {
	case void =>
		return false;
	case let cur: head =>
		return d.pos == head_endpos(cur);
	};
};

// Returns the next data element, or [[badformat]] on EOF.
fn next(d: *decoder) (head | error) = {
	match (trynext(d)?) {
	case io::EOF =>
		return badformat;
	case let dh: head =>
		return dh;
	};
};

fn trynext(d: *decoder) (head | error | io::EOF) = {
	if (d.next is head) {
		let dh = d.next: head;
		d.cur = dh;
		d.next = void;
		dh.implicit = d.implicit;
		d.implicit = false;
		return dh;
	};

	if (is_endofcons(d)) return io::EOF;

	let dh = match (parse_header(d)?) {
	case io::EOF =>
		return io::EOF;
	case let dh: head =>
		yield dh;
	};

	d.cur = dh;
	dh.implicit = d.implicit;
	d.implicit = false;
	return dh;
};

fn parse_header(d: *decoder) (head | error | io::EOF) = {
	const consend = match (curcons(d)) {
	case void =>
		yield types::SIZE_MAX;
	case let h: head =>
		yield h.end;
	};

	if (d.pos == consend) return invalid;

	const epos = d.pos;
	const id = match (tryscan_byte(d)?) {
	case io::EOF =>
		d.cur = void;
		return io::EOF;
	case let id: u8 =>
		yield id;
	};

	const class = ((id & 0xc0) >> 6): class;

	let tagid: u32 = id & TAGMASK;
	if (tagid == TAGMASK) {
		tagid = parse_longtag(d, consend - d.pos)?;
	};
	const l = parse_len(d, consend - d.pos)?;
	const hl = d.pos - epos;

	const end = epos + hl + l;
	if (end > consend) return invalid;

	return head {
		class = class,
		cons = ((id >> 5) & 1) == 1,
		tagid = tagid,
		start = epos,
		data = epos + hl,
		end = end,
		implicit = d.implicit,
		...
	};
};

fn tryscan_byte(d: *decoder) (u8 | io::EOF | error) = {
	let buf: [1]u8 = [0...];
	match (io::readall(d.src, buf)?) {
	case io::EOF =>
		return io::EOF;
	case size =>
		d.pos += 1;
		return buf[0];
	};
};

fn scan_byte(d: *decoder) (u8 | error) = {
	match (tryscan_byte(d)?) {
	case io::EOF =>
		return truncated;
	case let b: u8 =>
		return b;
	};
};

// Reads data of current entry and advances pointer. Data must have been opened
// using [[next]] or [[trynext]]. [[io::EOF]] is returned on end of data.
fn dataread(d: *decoder, buf: []u8) (size | io::EOF | io::error) = {
	let cur = match (d.cur) {
	case void =>
		abort("primitive must be opened with [[next]] or [[trynext]]");
	case let dh: head =>
		yield dh;
	};

	const dataleft = head_endpos(cur) - d.pos + d.unbufn;
	if (dataleft == 0) {
		return io::EOF;
	};

	let n = 0z;
	if (d.unbufn > 0) {
		const max = if (d.unbufn > len(buf)) len(buf): u8 else d.unbufn;
		buf[..max] = d.unbuf[..max];
		d.unbufn -= max;
		n += max;
	};

	const max = if (dataleft < len(buf) - n) dataleft else len(buf) - n;

	match (io::read(d.src, buf[n..n + max])?) {
	case io::EOF =>
		// there should be data left
		return wrap_err(truncated);
	case let sz: size =>
		d.pos += sz;
		return n + sz;
	};
};

// unread incomplete utf8 runes.
fn dataunread(d: *decoder, buf: []u8) void = {
	assert(len(buf) + d.unbufn <= len(d.unbuf));

	d.unbuf[d.unbufn..d.unbufn + len(buf)] = buf;
	d.unbufn += len(buf): u8;
};

fn dataeof(d: *decoder) bool = {
	match (d.cur) {
	case void =>
		return true;
	case let h: head =>
		return d.pos + d.unbufn == head_endpos(h);
	};
};

fn parse_longtag(p: *decoder, max: size) (u32 | error) = {
	// XXX: u32 too much?
	let tag: u32 = 0;
	let maxbits = size(u32) * 8;
	let nbits = 0z;

	for (let i = 0z; i < max; i += 1) {
		let b = scan_byte(p)?;
		const part = b & 0x7f;

		nbits += if (tag == 0) bit_size_u8(part) else 7;
		if (nbits > maxbits) {
			// overflows u32
			return invalid;
		};

		tag = (tag << 7) + part;
		if (tag == 0) {
			// first tag part must not be 0
			return invalid;
		};

		if ((b >> 7) == 0) {
			return tag;
		};
	};
	return invalid; // max has been reached
};

fn parse_len(p: *decoder, max: size) (size | error) = {
	if (max == 0) return invalid;

	const b = scan_byte(p)?;
	if (b == 0xff) {
		return invalid;
	};
	if (b >> 7 == 0) {
		// short form
		return b: size;
	};

	let l = 0z;
	const n = b & 0x7f;
	if (n == 0) {
		// Indefinite encoding is not supported in DER.
		return invalid;
	};

	if (n > size(size)) {
		// would cause a size overflow
		return invalid;
	};

	if (n + 1 > max) return invalid;

	for (let i = 0z; i < n; i += 1) {
		const b = scan_byte(p)?;
		l = (l << 8) + b;
		if (l == 0) {
			// Leading zeroes means minimum number of bytes for
			// length encoding has not been used.
			return invalid;
		};
	};

	if (l <= 0x7f) {
		// Could've used short form.
		return invalid;
	};

	return l;
};

// Expects an IMPLICIT defined data field having class 'c' and tag 'tag'.
// If the requirements are met, a read call (i.e. one of the "read_" or "reader"
// functions) must follow to read the actual data as stored.
export fn expect_implicit(d: *decoder, c: class, tag: u32) (void | error) = {
	let h = peek(d)?;
	expect_tag(h, c, tag)?;
	d.implicit = true;
};

// Opens an EXPLICIT encoded field of given class 'c' and 'tag'. The user must
// call [[close_explicit]] after containing data has been read.
export fn open_explicit(d: *decoder, c: class, tag: u32) (void | error) =
	open_cons(d, c, tag);

// Closes an EXPLICIT encoded field.
export fn close_explicit(d: *decoder) (void | badformat) = close_cons(d);


// Opens a constructed value of given 'class' and 'tagid'. Fails if not a
// constructed value or the encoded value has an unexpected tag.
fn open_cons(d: *decoder, class: class, tagid: u32) (void | error) = {
	let dh = next(d)?;
	if (!dh.cons) {
		return invalid;
	};

	expect_tag(dh, class, tagid)?;

	if (d.cstackp == len(d.cstack)) {
		return badformat;
	};

	d.cstack[d.cstackp] = dh;
	d.cstackp += 1;
};

// Closes current constructed value. badformat is returend, if not all data has
// been read.
fn close_cons(d: *decoder) (void | badformat) = {
	if (d.implicit) {
		// a datafield marked implicit has not been read
		return badformat;
	};

	match (curcons(d)) {
	case void =>
		abort("No constructed value open");
	case let h: head =>
		if (d.pos != head_endpos(h) || d.unbufn > 0) {
			// All data must have been read before closing the seq
			return badformat;
		};
	};

	d.cstackp -= 1;
};

// Opens a sequence. Call [[close_seq]] after reading.
export fn open_seq(d: *decoder) (void | error) =
	open_cons(d, class::UNIVERSAL, utag::SEQUENCE: u32)?;

// Closes the current sequence. If the caller has not read all of the data
// present in the encoded seqeunce, [[badformat]] is returned.
export fn close_seq(d: *decoder) (void | badformat) = close_cons(d);

// Opens a set. Note that sets must be ordered according to DER, but this module
// does not validate this constraint. Call [[close_set]] after reading.
export fn open_set(d: *decoder) (void | error) =
	open_cons(d, class::UNIVERSAL, utag::SET: u32)?;

// Closes the current set. If the caller has not read all of the data present in
// the encoded seqeunce, [[badformat]] is returned.
export fn close_set(d: *decoder) (void | badformat) = close_cons(d);

fn expect_tag(h: head, class: class, tagid: u32) (void | invalid | badformat) = {
	if (class == class::UNIVERSAL && (tagid == utag::SEQUENCE
			|| tagid == utag::SET) && !h.cons) {
		return invalid;
	};

	if (h.implicit) {
		return;
	};

	if (h.class != class || h.tagid != tagid) {
		return badformat;
	};
};

fn expect_utag(dh: head, tag: utag) (void | invalid | badformat) =
	expect_tag(dh, class::UNIVERSAL, tag: u32);

fn read_bytes(d: *decoder, buf: []u8) (size | error) = {
	match (dataread(d, buf)) {
	case io::EOF =>
		return 0z;
	case let n: size =>
		if (!dataeof(d)) {
			return badformat;
		};
		return n;
	};
};

fn read_nbytes(d: *decoder, buf: []u8) (size | error) = {
	const n = read_bytes(d, buf)?;
	if (n != len(buf)) {
		return badformat;
	};
	return n;
};

// Reads a boolean value.
export fn read_bool(d: *decoder) (bool | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::BOOLEAN)?;
	if (dsz(dh) != 1) {
		return invalid;
	};

	let b = scan_byte(d)?;

	if (b != 0x00 && b != 0xff) {
		return invalid;
	};

	return b == 0xff;
};

fn validate_intprefix(i: []u8) (void | error) = {
	switch (len(i)) {
	case 0 =>
		return invalid;
	case 1 =>
		return;
	case =>
		// An int must be encoded using the minimal number of bytes
		// possible as defined in X.690 s8.3.2
		if ((i[0] == 0x00 && i[1] >> 7 == 0)
			|| (i[0] == 0xff && i[1] >> 7 == 1)) {
			return invalid;
		};
	};
};

// Reads an arbitrary-length integer into 'buf' and returns its length in bytes.
// Fails if the encoded integer size exceeds the buffer size. The integer is
// stored in big endian, and negative values are stored with two's compliment.
// The minimum integer size is one byte.
export fn read_int(d: *decoder, buf: []u8) (size | error) = {
	assert(len(buf) > 0);

	let dh = next(d)?;
	expect_utag(dh, utag::INTEGER)?;
	const n = read_bytes(d, buf)?;
	validate_intprefix(buf[..n])?;
	return n;
};

// Similar to [[read_int]], but returns [[badformat]] if the encoded value is
// signed. Discards the most significant zero bytes.
export fn read_uint(d: *decoder, buf: []u8) (size | error) = {
	let s = read_int(d, buf)?;
	if (buf[0] & 0x80 == 0x80) {
		return badformat;
	};
	if (buf[0] == 0) {
		buf[..s-1] = buf[1..s];
		s -= 1;
	};
	return s;
};

fn read_ux(d: *decoder, x: u8) (u64 | error) = {
	assert(x <= 8);
	let b: [9]u8 = [0...];
	const n = read_int(d, b[..x+1])?;

	if (b[0] & 0x80 != 0) {
		// sign bit is set
		return invalid;
	};

	const s = if (b[0] == 0x00) 1u8 else 0u8;
	if (n - s > x) {
		return invalid;
	};

	let r = 0u64;
	for (let i = s; i < n; i += 1) {
		r <<= 8;
		r += b[i];
	};
	return r;
};

// Reads an integer that is expected to fit into u8.
export fn read_u8(d: *decoder) (u8 | error) = read_ux(d, 1)?: u8;

// Reads an integer that is expected to fit into u16.
export fn read_u16(d: *decoder) (u16 | error) = read_ux(d, 2)?: u16;

// Reads an integer that is expected to fit into u32.
export fn read_u32(d: *decoder) (u32 | error) = read_ux(d, 4)?: u32;

// Reads an integer that is expected to fit into u64.
export fn read_u64(d: *decoder) (u64 | error) = read_ux(d, 8)?;

// Reads a bitstring value. The result tuple contains the bitstring and the
// number of unused bits in the last byte. The [[bitstr_isset]] function may be
// used to check for set bits.
export fn read_bitstr(d: *decoder, buf: []u8) (([]u8, u8) | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::BITSTRING)?;

	let unused: [1]u8 = [0...];
	match (dataread(d, unused)?) {
	case io::EOF =>
		return invalid;
	case let n: size =>
		if (n != 1) {
			return invalid;
		};
	};
	const unused = unused[0];
	if (unused > 7) {
		return invalid;
	};

	const n = read_bytes(d, buf)?;
	const mask = (1 << unused) - 1;
	if (n > 0 && buf[n-1] & mask != 0) {
		// unused bits must be zero
		return invalid;
	};
	return (buf[..n], unused);
};

// Checks whether bit at 'pos' is set in given bitstring. 'pos' starts from 0,
// which is the highest order bit in the first byte.
export fn bitstr_isset(bitstr: ([]u8, u8), pos: size) (bool | invalid) = {
	const i = pos / 8;
	if (i >= len(bitstr.0)) {
		return false;
	};
	let b = bitstr.0[i];

	const j = pos - i * 8;
	if (i == len(bitstr.0) - 1 && j >= (8 - bitstr.1)) {
		return invalid;
	};
	const mask = (1 << (7 - j));
	return mask & b == mask;
};

// Returns an [[io::reader]] for octet string data.
export fn octetstrreader(d: *decoder) (bytestream | error) = {
	// TODO add limit?
	let dh = next(d)?;
	expect_utag(dh, utag::OCTET_STRING)?;
	return newbytereader(d);
};

// Read an octet string into 'buf', returning its length. Returns [[badformat]]
// if 'buf' is too small.
export fn read_octetstr(d: *decoder, buf: []u8) (size | error) = {
	assert(len(buf) > 0);

	let dh = next(d)?;
	expect_utag(dh, utag::OCTET_STRING)?;
	return read_bytes(d, buf);
};

// Reads a null entry.
export fn read_null(d: *decoder) (void | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::NULL)?;
	if (dsz(dh) != 0) {
		return invalid;
	};
};

export type bytestream = struct {
	stream: io::stream,
	d: *decoder,
};

fn newbytereader(d: *decoder) bytestream = {
	return bytestream {
		stream = &bytestream_vtable,
		d = d,
		...
	};
};

const bytestream_vtable: io::vtable = io::vtable {
	reader = &bytestream_reader,
	...
};

fn bytestream_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) =
	dataread((s: *bytestream).d, buf);

// Returns an [[io::reader]] that reads raw data (in its ASN.1 encoded form)
// from a [[decoder]]. Note that this reader will not perform any kind of
// validation.
export fn bytereader(d: *decoder, c: class, tagid: u32) (bytestream | error) = {
	let dh = next(d)?;
	expect_tag(dh, c, tagid)?;
	return newbytereader(d);
};

// Reads an UTC time. Since the stored date only has a two digit year, 'maxyear'
// is required to define the epoch. For example 'maxyear' = 2046 causes all
// encoded years <= 46 to be after 2000 and all values > 46 will have 1900 as
// the century.
export fn read_utctime(d: *decoder, maxyear: u16) (date::date | error) = {
	assert(maxyear > 100);

	let dh = next(d)?;
	expect_utag(dh, utag::UTC_TIME)?;

	let time: [13]u8 = [0...];
	read_nbytes(d, time[..])?;

	if (time[len(time)-1] != 'Z') {
		return invalid;
	};

	let year: u16 = (time[0] - 0x30): u16 * 10 + (time[1] - 0x30): u16;
	let cent = maxyear - (maxyear % 100);
	if (year > maxyear % 100) {
		cent -= 100;
	};

	let v = date::newvirtual();
	v.vloc = chrono::UTC;
	v.year = (year + cent): int;
	v.zoff = 0;
	v.nanosecond = 0;

	let datestr = strings::fromutf8(time[2..])!;
	if (!(date::parse(&v, "%m%d%H%M%S%Z", datestr) is void)) {
		return invalid;
	};

	let dt = match (date::realize(v)) {
	case let dt: date::date =>
		yield dt;
	case let e: (date::insufficient | date::invalid) =>
		return invalid;
	};

	return dt;
};

// Reads a generalized datetime value.
export fn read_gtime(d: *decoder) (date::date | error) = {
	let dh = next(d)?;
	expect_utag(dh, utag::GENERALIZED_TIME)?;

	// The date begins with the encoded datetime
	def DATESZ = 14z;
	// followed by optional fractional seconds separated by '.'
	def NANOSZ = 10z;
	def NANOSEPPOS = 14;
	// and ends with the zone info 'Z'
	def ZONESZ = 1z;

	let time: [DATESZ + NANOSZ + ZONESZ]u8 = [0...];
	let n = read_bytes(d, time[..])?;

	// zone info and seconds must always be present
	if (time[n-1] != 'Z' || n < DATESZ + ZONESZ) {
		return invalid;
	};

	// validate fractional seconds
	if (n > DATESZ + ZONESZ) {
		// fractional seconds must not be empty
		if (time[NANOSEPPOS] != '.' || n == DATESZ + ZONESZ + 1) {
			return invalid;
		};
		// fractional seconds must not end with 0 and must be > 0
		if (time[n-2] == '0') return invalid;
	};

	// right pad fractional seconds to make them valid nanoseconds
	time[n-1..] = ['0'...];
	time[NANOSEPPOS] = '.';

	match (date::from_str("%Y%m%d%H%M%S.%N", strings::fromutf8(time)!)) {
	case let d: date::date =>
		return d;
	case =>
		return invalid;
	};
};

// Skips an element and returns the size of the data that has been skipped.
// Returns an error if the skipped data is invalid.
//
// Presently only supports BOOLEAN, INTEGER, NULL, OCTET_STRING, and BITSTRING
// utags, and will abort when attempting to skip anything else.
export fn skip(d: *decoder, tag: utag, max: size) (size | error) = {
	static let buf: [os::BUFSZ]u8 = [0...];
	let s = 0z;
	switch (tag) {
	case utag::BOOLEAN =>
		read_bool(d)?;
		return 1z;
	case utag::INTEGER =>
		let br = bytereader(d, class::UNIVERSAL, utag::INTEGER)?;
		let n = match (io::read(&br, buf)?) {
		case let n: size =>
			yield n;
		case io::EOF =>
			return invalid;
		};
		validate_intprefix(buf[..n])?;
		n += streamskip(&br, max, buf)?;
		return n;
	case utag::NULL =>
		read_null(d)?;
		return 0z;
	case utag::OCTET_STRING =>
		let r = octetstrreader(d)?;
		return streamskip(&r, max, buf)?;
	case utag::BITSTRING =>
		assert(max <= len(buf));
		let buf = buf[..max];
		let p = read_bitstr(d, buf)?;
		bytes::zero(p.0);
		return len(p.0) + 1;
	case =>
		abort("skip for given utag not implemented");
	};
};

fn streamskip(r: io::handle, max: size, buf: []u8) (size | error) = {
	defer bytes::zero(buf);
	let buf = if (max < len(buf)) buf[..max] else buf[..];
	let s = 0z;
	for (true) {
		match (io::read(r, buf)?) {
		case let n: size =>
			s += n;
		case io::EOF =>
			return s;
		};

		if (s > max) {
			return badformat;
		};
	};
};
