// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use endian;
use io;
use memio;
use strconv;
use types::c;

export type reader = struct {
	src: io::handle,
	name: [255]u8,
};

// Creates a new reader for a tar file. Use [[next]] to iterate through entries
// present in the tar file.
export fn read(src: io::handle) reader = {
	return reader {
		src = src,
		...
	};
};

// Returns the next entry from a tar [[reader]]. Parts of this structure
// (specifically the file name) are borrowed from the reader itself and will not
// be valid after subsequent calls.
//
// If the return value is a file (i.e. entry.etype == entry_type::FILE), the
// caller must either call [[io::read]] using the return value until it returns
// [[io::EOF]], or call [[skip]] to seek to the next entry in the archive.
//
// Note that reading from the header will modify the file size.
export fn next(rd: *reader) (entry | error | io::EOF) = {
	static let buf: [BLOCKSZ]u8 = [0...];
	io::readall(rd.src, buf)?;

	if (zeroed(buf)) {
		io::readall(rd.src, buf)?;
		if (!zeroed(buf)) {
			return invalid;
		};
		return io::EOF;
	};

	const reader = memio::fixed(buf);
	const name = readstr(&reader, 100);
	const mode = readoct(&reader, 8)?;
	const uid = readoct(&reader, 8)?;
	const gid = readoct(&reader, 8)?;
	const fsize = readsize(&reader, 12)?;
	const mtime = readoct(&reader, 12)?;
	const checksum = readoct(&reader, 8)?;
	const etype = readoct(&reader, 1)?: entry_type;
	const link = readstr(&reader, 100);

	let ent = entry {
		vtable = if (etype == entry_type::FILE) &file_vtable
			else &nonfile_vtable,
		src = rd.src,
		orig = fsize,
		remain = fsize,
		name = name,
		mode = mode,
		uid = uid,
		gid = gid,
		fsize = fsize,
		mtime = mtime,
		checksum = checksum,
		etype = etype,
		link = link,
		...
	};

	const ustar = readstr(&reader, 6);
	if (ustar != "ustar") {
		ent.name = name;
		return ent;
	};

	const version = readstr(&reader, 2);
	// XXX: We could check the version here
	ent.uname = readstr(&reader, 32);
	ent.gname = readstr(&reader, 32);
	ent.devmajor = readoct(&reader, 8)?;
	ent.devminor = readoct(&reader, 8)?;
	const prefix = readstr(&reader, 155);
	let writer = memio::fixed(rd.name);
	memio::join(&writer, prefix, name)!;
	ent.name = memio::string(&writer)!;
	return ent;
};

// Seeks the underlying tar file to the entry following this one.
export fn skip(ent: *entry) (void | io::error) = {
	let amt = ent.remain;
	if (amt % BLOCKSZ != 0) {
		amt += BLOCKSZ - (amt % BLOCKSZ);
	};
	match (io::seek(ent.src, amt: io::off, io::whence::CUR)) {
	case io::off =>
		return;
	case io::error => void;
	};
	io::copy(io::empty, ent)?;
};

const file_vtable: io::vtable = io::vtable {
	reader = &file_read,
	seeker = &file_seek,
	...
};

const nonfile_vtable: io::vtable = io::vtable { ... };

fn file_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let ent = s: *ent_reader;
	assert(ent.vtable == &file_vtable);
	if (ent.remain == 0) {
		return io::EOF;
	};

	let z = len(buf);
	if (z > ent.remain) {
		z = ent.remain;
	};
	z = match (io::read(ent.src, buf[..z])?) {
	case let z: size =>
		yield z;
	case io::EOF =>
		// TODO: Truncated flag
		return io::EOF;
	};
	ent.remain -= z;

	// Read until we reach the block size
	if (ent.remain == 0 && ent.orig % BLOCKSZ != 0) {
		static let buf: [BLOCKSZ]u8 = [0...];
		io::readall(ent.src, buf[..BLOCKSZ - (ent.orig % BLOCKSZ)])?;
	};

	return z;
};

fn file_seek(
	s: *io::stream,
	off: io::off,
	w: io::whence,
) (io::off | io::error) = {
	let ent = s: *ent_reader;
	assert(ent.vtable == &file_vtable);

	const orig = ent.orig: io::off;
	const cur = (ent.orig - ent.remain): io::off;
	let new = switch (w) {
	case io::whence::SET =>
		yield off;
	case io::whence::CUR =>
		yield cur + off;
	case io::whence::END =>
		yield orig + off;
	};

	if (new < 0) {
		new = 0;
	} else if (new > orig) {
		new = orig;
	};

	const rel = new - cur;
	io::seek(ent.src, rel, io::whence::CUR)?;

	ent.remain = (orig - new): size;
	return new;
};

fn readstr(rd: *memio::stream, ln: size) str = {
	const buf = match (memio::borrowedread(rd, ln)) {
	case let buf: []u8 =>
		assert(len(buf) == ln);
		yield buf;
	case io::EOF =>
		abort();
	};
	return c::tostr(buf: *[*]u8: *const c::char)!;
};

fn readoct(rd: *memio::stream, ln: size) (uint | invalid) = {
	const string = readstr(rd, ln);
	match (strconv::stou(string, strconv::base::OCT)) {
	case let u: uint =>
		return u;
	case =>
		return invalid;
	};
};

fn readsize(rd: *memio::stream, ln: size) (size | invalid) = {
	const string = readstr(rd, ln);
	match (strconv::stoz(string, strconv::base::OCT)) {
	case let z: size =>
		return z;
	case =>
		return invalid;
	};
};

fn zeroed(buf: []u8) bool = {
	for (let i = 0z; i < len(buf); i += 1) {
		if (buf[i] != 0) {
			return false;
		};
	};
	return true;
};
