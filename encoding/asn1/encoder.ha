// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use bytes;
use endian;
use errors;
use io;
use math::{bit_size_u8,bit_size_u32};
use memio;
use strings;
use time::date;
use types;


export type datasz = u32; // XXX: might want to use size here
let szput = &endian::beputu32;
let szget = &endian::begetu32;
def DATASZ_MAX = types::U32_MAX;

// The maximum header size possible for u32 tag ids.
export def MAXHEADSZ = 1 + 5 + 1 + size(datasz);

// The maximum header size possible for entries of [[utag]].
export def MAXUTAGHEADSZ = 1 + 1 + size(datasz);

export type encoder = struct {
	mem: *memio::stream,
	start: io::off,
	pos: size,
	bt: [MAX_CONS_DEPTH](size, datasz),
	btn: size,

	cur_dpos: size,
	cur_prim: bool,
	cur_fixed: bool,

	parent: nullable *bytewstream,
};

// Creates a new DER encoder. The user must provide a [[memio::stream]] for
// buffering data before it's encoded. The user may provide a dynamic or fixed
// stream at their discretion; fixed may be preferred if the user knows the
// required buffer size in advance.
//
// To encode DER data, the user must call one of the "create_" functions (e.g.
// [[create_explicit]]), followed by the appropriate "write_" functions (e.g.
// [[write_int]]). These operations will be buffered into the provided memio
// buffer, and the encoded form may be finalized and retrieved via [[encode]] or
// [[encodeto]].
//
// To determine the required buffer size for a fixed buffer, consider the
// maximum length of the input data (e.g. integer, string, etc length) plus the
// necessary overhead, which is given by [[MAXUTAGHEADSZ]] if only using the
// provided encoder functions (e.g. "write_" functions), or [[MAXHEADSZ]] if
// using custom tag IDs.
//
// The encoder does not close the provided [[memio::stream]] after use; the
// caller should manage its lifetime accordingly.
export fn derencoder(mem: *memio::stream) encoder = encoder {
	mem = mem,
	start = io::tell(mem)!,
	...
};

// Creates a DER encoder nested within another DER entry, using the buffer of
// the parent.
export fn derencoder_nested(b: *bytewstream) encoder = encoder {
	mem = b.e.mem,
	start = io::tell(b.e.mem)!,
	parent = b,
	...
};

fn write(e: *encoder, buf: []u8) (void | overflow) = {
	if (len(buf) > (DATASZ_MAX - e.pos)) return overflow;

	match (io::write(e.mem, buf)) {
	case let n: size =>
		if (n < len(buf)) {
			// short writes happen, if a fixed e.mem reaches its end
			return overflow;
		};
	case errors::overflow =>
		return overflow;
	case =>
		 // writing to mem does not throw any other errors
		abort();
	};
	e.pos += len(buf);
};

fn write_id(e: *encoder, c: class, t: u32, cons: bool) (void | overflow) = {
	let head: u8 = c << 6;
	if (cons) {
		head |= (1 << 5);
	};

	if (t < 31) {
		bt_add_sz(e, 1);
		return write(e, [head | t: u8]);
	};

	write(e, [head | 0x1f])?;

	const bsz = bit_size_u32(t);
	const n = ((bsz + 6) / 7) - 1;
	for (let i = 0z; i < n; i += 1) {
		write(e, [0x80 | (t >> ((n - i) * 7)): u8])?;
	};
	write(e, [t: u8 & 0x7f])?;
};

fn write_fixedprim(e: *encoder, c: class, t: u32, b: []u8) (void | overflow) = {
	if (e.cur_prim) {
		finish_prim(e);
	};

	e.cur_prim = true;
	e.cur_fixed = true;
	write_id(e, c, t, false)?;

	write(e, encode_dsz(len(b)))?;
	write(e, b)?;

	bt_add_dsz(e, len(b): datasz);
};

fn create_prim(e: *encoder, class: class, tag: u32) (void | overflow) = {
	if (e.cur_prim) {
		finish_prim(e);
	};

	e.cur_prim = true;
	e.cur_fixed = false;

	write_id(e, class, tag, false)?;

	// write size placeholder
	const placehsz = 0x80 | size(datasz): u8;
	let lbuf: [1 + size(datasz)]u8 = [placehsz, 0...];
	write(e, lbuf)?;

	e.cur_dpos = e.pos;
};

fn finish_prim(e: *encoder) void = {
	e.cur_prim = false;
	if (e.pos == 0 || e.cur_fixed) {
		return;
	};

	const pos = io::tell(e.mem)!;
	defer io::seek(e.mem, pos, io::whence::SET)!;

	// write back size to placeholder
	const dszpos = e.start: size + e.cur_dpos - size(datasz);
	const dsz = e.pos - e.cur_dpos;
	let dszbuf: [size(datasz)]u8 = [0...];
	szput(dszbuf, dsz: datasz);

	io::seek(e.mem, dszpos: io::off, io::whence::SET)!;
	io::write(e.mem, dszbuf)!;

	bt_add_dsz(e, dsz: datasz);
};

// Push n empty size value to backtrace stack
fn push_bt(e: *encoder, pos: size) (void | overflow) = {
	if (e.btn + 1 >= len(e.bt)) return overflow;

	e.bt[e.btn] = (pos, 0);
	e.btn += 1;
};

// Add 'sz' to the current value of the backtrack stack
fn bt_add_sz(e: *encoder, sz: size) void = {
	if (e.btn == 0) return;
	const csz = e.bt[e.btn - 1].1;
	e.bt[e.btn - 1].1 = csz + sz: datasz;
};

// Add data size 'sz' + size length to current value of the backtrack stack
fn bt_add_dsz(e: *encoder, sz: datasz) void = {
	if (e.btn == 0) return;
	const lsz = lensz(sz);
	return bt_add_sz(e, lsz + sz);
};

// Pop current backtrace value from stack
fn pop_bt(e: *encoder) (size, datasz) = {
	e.btn -= 1;
	let x = e.bt[e.btn];
	e.bt[e.btn] = (0, 0);
	return x;
};

fn lensz(l: datasz) u8 = if (l < 128) 1: u8 else (1 + (bit_size_u32(l) + 7) / 8);

fn encode_dsz(sz: size) []u8 = {
	static let buf: [size(datasz) + 1]u8 = [0...];
	if (sz < 128) {
		buf[0] = sz: u8;
		return buf[..1];
	};

	let n = lensz(sz: datasz);
	buf[0] = (n - 1) | 0x80;
	for (let i: size = n - 1; sz > 0; i -= 1) {
		buf[i] = sz: u8;
		sz >>= 8;
	};

	return buf[..n];
};

// Creates an explicit constructed entry. The user must call [[finish_explicit]]
// to close the associated DER entry.
export fn create_explicit(e: *encoder, c: class, tag: u32) (void | overflow) =
	create_cons(e, c, tag);

// Finishes an explicit constructed entry.
export fn finish_explicit(e: *encoder) void = finish_cons(e);

fn create_cons(e: *encoder, class: class, tagid: u32) (void | overflow) = {
	if (e.cur_prim) {
		finish_prim(e);
	};
	write_id(e, class, tagid, true)?;

	const placehsz = 0x80 | size(datasz): u8;
	let lbuf: [1 + size(datasz)]u8 = [placehsz, 0...];
	write(e, lbuf)?;

	push_bt(e, e.pos - size(datasz))?;
	return;
};

fn finish_cons(e: *encoder) void = {
	if (e.cur_prim) {
		finish_prim(e);
	};

	let (dszpos, sz) = pop_bt(e);
	let lbuf: [size(datasz)]u8 = [0...];
	szput(lbuf, sz);

	const pos = io::tell(e.mem)!;
	defer io::seek(e.mem, pos, io::whence::SET)!;

	dszpos += e.start: size;
	io::seek(e.mem, dszpos: io::off, io::whence::SET)!;
	io::write(e.mem, lbuf)!;
	bt_add_dsz(e, sz);
};

// Creates a sequence. The user must call [[finish_seq]] to close the associated
// DER entry.
export fn create_seq(e: *encoder) (void | overflow) =
	return create_cons(e, class::UNIVERSAL, utag::SEQUENCE);

// Finishes a sequence.
export fn finish_seq(e: *encoder) void = finish_cons(e);

// Writes a boolean.
export fn write_bool(e: *encoder, b: bool) (void | overflow) = {
	let v: u8 = if (b) 0xff else 0x00;
	write_fixedprim(e, class::UNIVERSAL, utag::BOOLEAN, [v])?;
};

// Writes a null value.
export fn write_null(e: *encoder) (void | overflow) = {
	write_fixedprim(e, class::UNIVERSAL, utag::NULL, [])?;
};

export type bytewstream = struct {
	stream: io::stream,
	e: *encoder,
};

fn bytewriter(e: *encoder, c: class, tagid: u32) (bytewstream | overflow) = {
	create_prim(e, c, tagid)?;
	return bytewstream {
		stream = &bytewriter_vtable,
		e = e,
		...
	};
};

const bytewriter_vtable = io::vtable {
	writer = &bytewriter_write,
	...
};

fn bytewriter_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let w = s: *bytewstream;
	if (write(w.e, buf) is overflow) {
		return wrap_err(overflow);
	};
	return len(buf);
};

// Creates an [[io::writer]] that encodes data written to it as an OctetString.
export fn octetstrwriter(e: *encoder) (bytewstream | overflow) = {
	return bytewriter(e, class::UNIVERSAL, utag::OCTET_STRING);
};

// Writes an integer. 'n' must be stored in big endian order. The highest bit of
// the first byte marks the sign.
export fn write_int(e: *encoder, n: []u8) (void | overflow) = {
	const neg = n[0] & 0x80 == 0x80;

	// compact according to X.690 Chapt. 8.3.2
	let i = 0z;
	for (i < len(n) - 1; i += 1) {
		if (neg && (n[i] != 0xff || n[i+1] & 0x80 != 0x80)) {
			break;
		};

		if (!neg && (n[i] != 0x00 || n[i+1] & 0x80 == 0x80)) {
			break;
		};
	};

	write_fixedprim(e, class::UNIVERSAL, utag::INTEGER, n[i..])?;
};

// Writes an integer asuming 'n' is unsigned.
export fn write_uint(e: *encoder, n: []u8) (void | overflow) = {
	if (n[0] & 0x80 == 0) {
		return write_int(e, n);
	};

	// prepend 0 so that the highest valued bit is not interpreted as sign
	create_prim(e, class::UNIVERSAL, utag::INTEGER)?;
	write(e, [0])?;
	write(e, n)?;
	finish_prim(e);
};

// Writes 's' as Utf8String.
export fn write_utf8str(e: *encoder, s: str) (void | overflow) =
	write_fixedprim(e, class::UNIVERSAL, utag::UTF8_STRING,
		strings::toutf8(s))?;

// Encodes all buffered data in the [[encoder]] and returns a slice representing
// the encoded entry, borrowed from the encoder's buffer.
export fn encode(e: *encoder) ([]u8 | io::error) = {
	assert(e.btn == 0);
	assert(e.start >= 0);

	if (e.cur_prim) {
		finish_prim(e);
	};

	let n = 0z;
	let buf = memio::buffer(e.mem)[e.start..];

	// iterate entries to minify tag ids and data sizes. 't' is the write
	// index and 'i' is the read index.
	let t = 0z;
	for (let i = 0z; i < e.pos) { // TODO cast seems off
		// encode id
		const id = buf[i];
		buf[t] = id;
		t += 1;
		i += 1;

		const cons = (id >> 5) & 1 == 1;
		if ((id & 0b11111) == 0b11111) {
			// id spans multiple bytes
			let id: u8 = 0x80;
			for (id & 0x80 == 0x80) {
				id = buf[i];
				buf[t] = id;
				t += 1;
				i += 1;
			};
		};

		// encode dsz
		let dsz: datasz = 0;
		let l = buf[i];
		i += 1;
		if (l < 128) {
			// data size fits in a single byte
			dsz = l;
			buf[t] = l;
			t += 1;
		} else {
			// decode multibyte size and minimize, since not all
			// placeholder bytes may have been used.
			const dn = l & 0x7f;
			for (let j = 0z; j < dn; j += 1) {
				dsz <<= 8;
				dsz |= buf[i];
				i += 1;
			};

			let dszbuf = encode_dsz(dsz);
			buf[t..t + len(dszbuf)] = dszbuf;
			t += len(dszbuf);
		};

		if (cons) {
			continue;
		};

		// write data of primitive fields
		buf[t..t+dsz] = buf[i..i+dsz];
		t += dsz;
		i += dsz;
	};

	bytes::zero(buf[t..]);
	match (e.parent) {
	case null => void;
	case let s: *bytewstream =>
		s.e.pos += t;
	};
	return buf[..t];
};

// Encodes all buffered data in the [[encoder]] and writes it to the provided
// [[io::handle]].
export fn encodeto(e: *encoder, dest: io::handle) (size | io::error) = {
	const buf = encode(e)?;
	return io::writeall(dest, buf)?;
};
