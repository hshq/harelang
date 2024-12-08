// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use endian;
use errors;
use io;
use memio;
use strings;
use types;

export type table_reader = struct {
	src: *memio::stream,
	orig_length: size,
	length: size,
	is64: bool,
};

// Creates a new DWARF table reader.
//
// If "read_length" is true, this function will read the length from the start
// of the table. Returns [[io::EOF]] immediately if there is insufficient data
// available in the provided I/O handle.
//
// The reader will return [[io::underread]] if the DWARF table is truncated.
fn new_table_reader(
	in: *memio::stream,
	read_length: bool,
) (table_reader | io::EOF | io::error) = {
	let rd = table_reader {
		src = in,
		orig_length = types::SIZE_MAX,
		length = types::SIZE_MAX,
		is64 = false,
	};

	if (read_length) {
		const word = match (read_uword(&rd)) {
		case let uw: u32 =>
			yield uw;
		case io::underread =>
			return io::EOF;
		case let err: io::error =>
			return err;
		};

		if (word == 0xffffffff) {
			rd.is64 = true;
			const long = match (read_ulong(&rd)) {
			case let ul: u64 =>
				yield ul;
			case let err: io::error =>
				if (err is io::underread) {
					return io::EOF;
				};
				return err;
			};
			rd.length = long: size;
		} else if (word >= 0xfffffff0) {
			// Reserved value
			return errors::invalid;
		} else {
			rd.length = word: size;
		};
	};

	rd.orig_length = rd.length;
	return rd;
};

fn read_iseof(rd: *table_reader) bool = rd.length == 0;

fn read_advance(rd: *table_reader, nbyte: size) (void | io::error) = {
	if (rd.length < nbyte) {
		return 0: io::underread;
	};
	rd.length -= nbyte;
};

// Aligns the reader on a given alignment. This function is needed because both
// binutils and LLVM inexplicably add padding to .debug_aranges to align the
// first tuple on the address size * 2, despite the fact that this is mentioned
// nowhere in the DWARF specification and in fact section 7.25 specifically
// states that DWARF data is not aligned. It took me 6 hours to figure this out.
fn read_align(rd: *table_reader, alignment: size) (void | io::error) = {
	let cur = rd.orig_length - rd.length + size(u32);
	if (rd.is64) {
		cur += size(u64);
	};

	const offs = alignment - (cur % alignment);
	if (offs == 0) {
		return;
	};
	let buf: [128]u8 = [0...];
	io::readall(rd.src, buf[..offs])?;
	rd.length -= offs;
};

// Returns the current location of the reader from the start of the section.
fn read_tell(rd: *table_reader) size = {
	const offs = rd.orig_length - rd.length;
	if (rd.is64) {
		return offs + size(u32) + size(u64);
	} else {
		return offs + size(u32);
	};
};

fn read_sbyte(rd: *table_reader) (i8 | io::error) = {
	read_advance(rd, size(i8))?;

	match (bufio::read_byte(rd.src)?) {
	case let byte: u8 =>
		return byte: i8;
	case io::EOF =>
		return 0: io::underread;
	};
};

fn read_ubyte(rd: *table_reader) (u8 | io::error) = {
	read_advance(rd, size(u8))?;

	match (bufio::read_byte(rd.src)?) {
	case let byte: u8 =>
		return byte;
	case io::EOF =>
		return 0: io::underread;
	};
};

fn read_uhalf(rd: *table_reader) (u16 | io::error) = {
	read_advance(rd, size(u16))?;

	let buf: [size(u16)]u8 = [0...];
	match (io::readall(rd.src, buf)?) {
	case io::EOF =>
		return 0: io::underread;
	case size =>
		return endian::host.getu16(buf);
	};
};

fn read_uword(rd: *table_reader) (u32 | io::error) = {
	read_advance(rd, size(u32))?;

	let buf: [size(u32)]u8 = [0...];
	match (io::readall(rd.src, buf)?) {
	case io::EOF =>
		return 0: io::underread;
	case size =>
		return endian::host.getu32(buf);
	};
};

fn read_ulong(rd: *table_reader) (u64 | io::error) = {
	read_advance(rd, size(u64))?;

	let buf: [size(u64)]u8 = [0...];
	match (io::readall(rd.src, buf)?) {
	case io::EOF =>
		return 0u64: io::underread: io::error;
	case size =>
		return endian::host.getu64(buf);
	};
};

fn read_secword(rd: *table_reader) (u64 | io::error) = {
	if (rd.is64) {
		return read_ulong(rd)?;
	} else {
		return read_uword(rd)?: u64;
	};
};

fn read_uleb128(rd: *table_reader) (u64 | io::error) = {
	let bits = 0u64, val = 0u64;
	for (true) {
		const x = read_ubyte(rd)?;
		val |= (x & ~0x80) << bits;
		if (x & 0x80 == 0) break;
		bits += 7;
	};
	return val;
};

fn read_sleb128(rd: *table_reader) (i64 | io::error) = {
	let bits = 0u64, uval = 0u64;
	for (true) {
		const x = read_ubyte(rd)?;
		uval |= (x & ~0x80) << bits;
		bits += 7;
		if (x & 0x80 == 0) break;
	};
	let val = uval: i64;
	let bits = bits: i64;
	if (val & (1 << (bits-1)) != 0) {
		val |= -1 << bits;
	};
	return val;
};

// Borrowed from underlying source
fn read_slice(rd: *table_reader, amt: size) ([]u8 | io::error) = {
	match (memio::borrowedread(rd.src, amt)) {
	case let sl: []u8 =>
		rd.length -= len(sl);
		return sl;
	case io::EOF =>
		return 0: io::underread;
	};
};

// Borrowed from underlying source
fn read_string(rd: *table_reader) (const str | io::error) = {
	// XXX: Leaks, should probably borrow from memio
	match (bufio::read_tok(rd.src, 0)?) {
	case let data: []u8 =>
		rd.length -= len(data) + 1;
		return strings::fromutf8(data)!;
	case io::EOF =>
		return 0: io::underread;
	};
};
