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
	// Number of bytes available in buffer
	pending: size,
	// Number of bytes returned to the user
	readout: size,
	// User-confirmed maximum size of read buffer
	maxread: size,
};

// Creates a new [[scanner]] which will allocate and maintain a read buffer for
// efficient reading of files. The scanner will read ahead only up to maxread
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
		pending = 0,
		readout = 0,
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
		pending = 0,
		readout = 0,
	};
};

// Frees resources associated associated with a [[scanner]]. Does not close the
// underlying I/O handle.
export fn finish(scan: *scanner) void = {
	free(scan.buffer);
};

fn scan_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let scan = s: *scanner;

	// Consume previous read, if any
	scan_shift(scan);

	if (scan.pending == 0) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			return io::EOF;
		case size => void;
		};
	};

	const n = if (len(buf) > scan.pending) scan.pending else len(buf);
	buf[..n] = scan_consume(scan, n)[..];
	return n;
};

// Fills up the scanner buffer with data from the underlying I/O handle. If no
// space remains in the read buffer, it is expanded by BUFSZ (up to maxread).
// Then, one read from the underlying I/O handle is performed and scan.pending
// is updated accordingly. Returns the number of bytes which had been available
// prior to the call.
fn scan_readahead(scan: *scanner) (size | io::EOF | io::error) = {
	if (scan.pending >= len(scan.buffer)) {
		let readahead = scan.pending + BUFSZ;
		if (readahead > scan.maxread) {
			readahead = scan.maxread;
		};
		if (scan.pending >= readahead) {
			return errors::overflow;
		};
		append(scan.buffer, [0...], readahead);
	};

	const prev = scan.pending;
	match (io::read(scan.src, scan.buffer[scan.pending..])?) {
	case let z: size =>
		scan.pending += z;
		return prev;
	case io::EOF =>
		return io::EOF;
	};
};

// Shifts the buffer towards the start, discarding bytes which were read out.
fn scan_shift(scan: *scanner) void = {
	const n = scan.readout;
	if (n == 0) {
		return;
	};
	scan.buffer[..len(scan.buffer) - n] = scan.buffer[n..];
	scan.readout = 0;
	scan.pending -= n;
};

// Consumes N bytes from the buffer, updating scan.readout. User must call
// [[scan_shift]] before calling scan_consume again.
fn scan_consume(scan: *scanner, n: size) []u8 = {
	assert(len(scan.buffer) >= n && scan.readout == 0);
	scan.readout = n;
	return scan.buffer[..n];
};

// Reads one byte from a [[scanner]].
export fn scan_byte(scan: *scanner) (u8 | io::EOF | io::error) = {
	// Consume previous read, if any
	scan_shift(scan);

	if (scan.pending == 0) {
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
	scan_shift(scan);

	let i = 0z, nread = 0z;
	for (true) {
		match (bytes::index(scan.buffer[nread..scan.pending], delim)) {
		case let ix: size =>
			i = ix;
			break;
		case void => void;
		};

		match (scan_readahead(scan)?) {
		case io::EOF =>
			if (scan.pending == 0) {
				return io::EOF;
			};
			return scan_consume(scan, scan.pending);
		case let prevpending: size =>
			// No need to re-index the earlier part of the buffer
			nread = prevpending;
		};
	};

	const ndelim = match (delim) {
	case u8 =>
		yield 1z;
	case let u: []u8 =>
		yield len(u);
	};
	const nuser = nread + i, nconsume = nuser + ndelim;
	return scan_consume(scan, nconsume)[..nuser];
};

// Reads one rune from a [[scanner]].
export fn scan_rune(
	scan: *scanner,
) (rune | io::EOF | io::error | utf8::invalid) = {
	// Consume previous read, if any
	scan_shift(scan);

	if (scan.pending == 0) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			if (scan.pending == 0) {
				return io::EOF;
			};
		case size => void;
		};
	};
	const sz = utf8::utf8sz(scan.buffer[0])?;

	for (scan.pending < sz) {
		match (scan_readahead(scan)?) {
		case io::EOF =>
			return utf8::invalid;
		case size => void;
		};
	};

	const buf = scan_consume(scan, sz);
	const dec = utf8::decode(buf[..sz]);
	match (utf8::next(&dec)?) {
	case let r: rune =>
		return r;
	case void =>
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
	scan_shift(scan);
	return scan.buffer[..scan.pending];
};

fn scan_unread(scan: *scanner, buf: []u8) void = {
	if (len(buf) == 0) {
		return;
	};
	if (len(buf) <= scan.readout) {
		scan.buffer[scan.readout - len(buf)..scan.readout] = buf;
		scan.readout -= len(buf);
	} else {
		const n = len(buf) - scan.readout;
		assert(n < scan.maxread - scan.pending,
			"Attempted to unread more data than buffer has available");
		scan.buffer[n..] = scan.buffer[..len(scan.buffer) - n];
		scan.pending += n;
		scan.buffer[..len(buf)] = buf;
		scan.readout = 0;
	};
};

// Reads a single byte from an [[io::handle]].
export fn read_byte(file: io::handle) (u8 | io::EOF | io::error) = {
	let buf: [1]u8 = [0...];

	match (io::readall(file, buf)?) {
	case size =>
		return buf[0];
	case io::EOF =>
		return io::EOF;
	};
};

// Reads a slice of bytes until the delimiter. Delimiter is not included but
// it is read from the file. The return value must be freed by the caller.
export fn read_tok(file: io::handle, delim: u8...) ([]u8 | io::EOF | io::error) = {
	let buf: []u8 = [];

	for (true) {
		match (read_byte(file)?) {
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
// is not included but it is read from the file. The return value must be
// freed by the caller.
export fn read_line(file: io::handle) ([]u8 | io::EOF | io::error) =
	read_tok(file, '\n');

// Reads a rune from a UTF-8 stream.
export fn read_rune(
	file: io::handle,
) (rune | utf8::invalid | io::EOF | io::error) = {
	let b: [4]u8 = [0...];
	match (io::readall(file, b[..1])?) {
	case let n: size => void;
	case io::EOF =>
		return io::EOF;
	};

	const sz = utf8::utf8sz(b[0])?;

	if (sz == 1) {
		return b[0]: rune;
	};

	match (io::readall(file, b[1..sz])) {
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
	case void =>
		return io::EOF;
	case utf8::more =>
		return utf8::invalid;
	};
};
