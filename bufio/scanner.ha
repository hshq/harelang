// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::utf8;
use errors;
use io;
use strings;
use types;

def BUFSZ: size = 4096;

const scanner_vtable = io::vtable {
	reader = &scan_read,
	...
};

export type scanner = struct {
	stream: io::stream,
	src: io::handle,
	buffer: []u8,
	// Index of start of pending bytes in buffer
	start: size,
	// Sub-slice with pending bytes in buffer
	pending: []u8,
	// User-confirmed maximum size of read buffer
	maxread: size,
};

// Creates a new [[scanner]] which will allocate and maintain a read buffer for
// efficient reading of a handle. The scanner will read ahead only up to maxread
// bytes, which defaults to [[types::SIZE_MAX]] if no limit is required. The
// user must free resources associated with the scanner using [[finish]] after
// use.
//
// Reads from the scanner will return [[errors::overflow]] if maxread is
// reached.
export fn newscanner(
	src: io::handle,
	maxread: size = types::SIZE_MAX,
) scanner = {
	return scanner {
		stream = &scanner_vtable,
		src = src,
		buffer = alloc([0...], BUFSZ),
		maxread = maxread,
		start = 0,
		pending = [],
	};
};

// Creates a new [[scanner]] using a user-provided buffer. The scanner will
// return [[errors::overflow]] if the buffer length is reached, but will not
// perform any allocations. The user should not call [[finish]] after use unless
// they wish to free the underlying buffer through bufio.
export fn newscanner_static(src: io::handle, buffer: []u8) scanner = {
	return scanner {
		stream = &scanner_vtable,
		src = src,
		buffer = buffer,
		maxread = len(buffer),
		start = 0,
		pending = [],
	};
};

// Frees resources associated with a [[scanner]]. Does not close the underlying
// I/O handle.
export fn finish(scan: *scanner) void = {
	free(scan.buffer);
};

fn scan_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let scan = s: *scanner;

	if (len(scan.pending) == 0) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			return io::EOF;
		case size => void;
		};
	};

	const n = if (len(buf) > len(scan.pending)) len(scan.pending) else len(buf);
	buf[..n] = scan_consume(scan, n)[..];
	return n;
};

// Fills up the scanner buffer with data from the underlying I/O handle. If no
// space remains in the read buffer, it is expanded by BUFSZ (up to maxread).
// Then, one read from the underlying I/O handle is performed and scan.pending
// is updated accordingly. Returns the number of bytes which had been available
// prior to the call.
fn scan_readahead(scan: *scanner) (size | io::EOF | io::error) = {
	let start = scan.start;
	const pending = len(scan.pending);

	if (start + pending == len(scan.buffer)) {
		if (start > 0) {
			// Shift buffer to the left to free space at the end
			scan.buffer[..len(scan.buffer) - start] = scan.buffer[start..];
			scan.pending = scan.buffer[..pending];
			start = 0;
			scan.start = 0;
		} else {
			// Buffer is full, expand it
			let readahead = pending + BUFSZ;
			if (readahead > scan.maxread) {
				readahead = scan.maxread;
			};
			if (pending >= readahead) {
				return errors::overflow;
			};
			append(scan.buffer, [0...], readahead);
		};
	};

	match (io::read(scan.src, scan.buffer[start + pending..])?) {
	case let z: size =>
		scan.pending = scan.buffer[start..start + pending + z];
		return pending;
	case io::EOF =>
		return io::EOF;
	};
};

// Consumes N bytes from the buffer.
fn scan_consume(scan: *scanner, n: size) []u8 = {
	assert(len(scan.pending) >= n);
	scan.start += n;
	defer scan.pending = scan.pending[n..];
	return scan.pending[..n];
};

// Reads one byte from a [[scanner]].
export fn scan_byte(scan: *scanner) (u8 | io::EOF | io::error) = {
	if (len(scan.pending) == 0) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			return io::EOF;
		case size => void;
		};
	};

	return scan_consume(scan, 1)[0];
};

// Reads the next token from a [[scanner]], delimited by delim. The delimiter is
// read from the source handle but not included in the returned slice. The
// return value is borrowed from the internal scanner buffer, which is
// invalidated during subsequent operations which use this scanner.
export fn scan_bytes(
	scan: *scanner,
	delim: (u8 | []u8),
) ([]u8 | io::EOF | io::error) = {
	let i = 0z;
	for (true) {
		match (bytes::index(scan.pending[i..], delim)) {
		case let ix: size =>
			i += ix;
			break;
		case void => void;
		};

		match (scan_readahead(scan)?) {
		case io::EOF =>
			if (len(scan.pending) == 0) {
				return io::EOF;
			};
			return scan_consume(scan, len(scan.pending));
		case let prevpending: size =>
			// No need to re-index the earlier part of the buffer
			i = prevpending;
		};
	};

	const ndelim = match (delim) {
	case u8 =>
		yield 1z;
	case let u: []u8 =>
		yield len(u);
	};
	const nconsume = i + ndelim;
	return scan_consume(scan, nconsume)[..i];
};

// Reads one rune from a [[scanner]].
export fn scan_rune(
	scan: *scanner,
) (rune | io::EOF | io::error | utf8::invalid) = {
	if (len(scan.pending) < 4) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			if (len(scan.pending) == 0) {
				return io::EOF;
			};
		case size => void;
		};
	};
	const sz = utf8::utf8sz(scan.pending[0])?;
	if (len(scan.pending) < sz) {
		return utf8::invalid;
	};
	const buf = scan_consume(scan, sz);
	const dec = utf8::decode(buf[..sz]);
	match (utf8::next(&dec)?) {
	case let r: rune =>
		return r;
	case done =>
		return io::EOF;
	case utf8::more =>
		return utf8::invalid;
	};
};

// Scans a string of text from a [[scanner]] up to some delimiter. The delimiter
// is read from the source handle but not included in the returned string. The
// return value is borrowed from the internal scanner buffer, which is
// invalidated during subsequent operations which use this scanner.
export fn scan_string(
	scan: *scanner,
	delim: str,
) (const str | io::EOF | io::error | utf8::invalid) = {
	const token = match (scan_bytes(scan, strings::toutf8(delim))?) {
	case let token: []u8 =>
		yield token;
	case io::EOF =>
		return io::EOF;
	};
	return strings::fromutf8(token)?;
};

// Scans the next line of text from a [[scanner]]. The return value is borrowed
// from the internal scanner buffer, which is invalidated during subsequent
// operations which use this scanner.
export fn scan_line(
	scan: *scanner,
) (const str | io::EOF | io::error | utf8::invalid) = {
	return scan_string(scan, "\n");
};

// Returns the internal scanner buffer, which contains all bytes read ahead by
// the scanner up to this point.
export fn scan_buffer(scan: *scanner) []u8 = {
	return scan.pending[..];
};

fn scan_unread(scan: *scanner, buf: []u8) void = {
	if (len(buf) == 0) {
		return;
	};
	if (len(buf) <= scan.start) {
		const pending_end = scan.start + len(scan.pending);
		scan.buffer[scan.start - len(buf)..scan.start] = buf;
		scan.start -= len(buf);
		scan.pending = scan.buffer[scan.start..pending_end];
	} else {
		assert(len(buf) <= len(scan.buffer) - len(scan.pending),
			"Attempted to unread more data than buffer has available");
		// Shift buffer to the right to free space at the beginning
		scan.buffer[len(buf)..len(buf) + len(scan.pending)] =
			scan.buffer[scan.start..scan.start + len(scan.pending)];
		scan.buffer[..len(buf)] = buf;
		scan.pending = scan.buffer[..len(scan.pending) + len(buf)];
		scan.start = 0;
	};
};

// Reads a single byte from an [[io::handle]].
export fn read_byte(h: io::handle) (u8 | io::EOF | io::error) = {
	let buf: [1]u8 = [0...];

	match (io::readall(h, buf)?) {
	case size =>
		return buf[0];
	case io::EOF =>
		return io::EOF;
	};
};

// Reads a slice of bytes until the delimiter. Delimiter is not included but
// it is read from the handle. The return value must be freed by the caller.
export fn read_tok(h: io::handle, delim: u8...) ([]u8 | io::EOF | io::error) = {
	let buf: []u8 = [];

	for (true) {
		match (read_byte(h)?) {
		case let res: u8 =>
			if (bytes::contains(delim, res)) {
				break;
			};
			append(buf, res);
		case io::EOF =>
			if (len(buf) == 0) {
				return io::EOF;
			};
			break;
		};
	};

	return buf;
};

// Reads a slice of bytes until a newline character (\n, 0x0A). Newline itself
// is not included but it is read from the handle. The return value must be
// freed by the caller.
export fn read_line(h: io::handle) ([]u8 | io::EOF | io::error) =
	read_tok(h, '\n');

// Reads a rune from a UTF-8 stream.
export fn read_rune(
	h: io::handle,
) (rune | utf8::invalid | io::EOF | io::error) = {
	let b: [4]u8 = [0...];
	match (io::readall(h, b[..1])?) {
	case let n: size => void;
	case io::EOF =>
		return io::EOF;
	};

	const sz = utf8::utf8sz(b[0])?;

	if (sz == 1) {
		return b[0]: rune;
	};

	match (io::readall(h, b[1..sz])) {
	case let n: size => void;
	case io::EOF =>
		return io::EOF;
	case let err: io::error =>
		return if (err is io::underread) utf8::invalid else err;
	};

	let dec = utf8::decode(b[..sz]);
	match (utf8::next(&dec)?) {
	case let r: rune =>
		return r;
	case done =>
		return io::EOF;
	case utf8::more =>
		return utf8::invalid;
	};
};
