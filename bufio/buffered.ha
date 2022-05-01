// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Byron Torres <b@torresjrjr.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use encoding::utf8;
use errors;
use io;
use strings;

const buffered_vtable_r: io::vtable = io::vtable {
	closer = &buffered_close_static,
	reader = &buffered_read,
	...
};

const buffered_vtable_w: io::vtable = io::vtable {
	closer = &buffered_close_static,
	writer = &buffered_write,
	...
};

const buffered_vtable_rw: io::vtable = io::vtable {
	closer = &buffered_close_static,
	reader = &buffered_read,
	writer = &buffered_write,
	...
};

export type bufstream = struct {
	stream: io::stream,
	source: io::handle,
	rbuffer: []u8,
	wbuffer: []u8,
	ravail: size,
	wavail: size,
	flush: []u8,
};

// Creates a stream which buffers reads and writes for the underlying stream.
// This is generally used to improve performance of small reads/writes for
// sources where I/O operations are costly, such as if they invoke a syscall or
// take place over the network.
//
// The caller should supply one or both of a read and write buffer as a slice of
// the desired buffer, or empty slices if read or write functionality is
// disabled. The same buffer may not be used for both reads and writes.
//
// The caller is responsible for closing the underlying stream, and freeing the
// provided buffers if necessary, after the buffered stream is closed.
//
// 	let rbuf: [os::BUFSIZ]u8 = [0...];
// 	let wbuf: [os::BUFSIZ]u8 = [0...];
// 	let buffered = bufio::buffered(source, rbuf, wbuf);
export fn buffered(
	src: io::handle,
	rbuf: []u8,
	wbuf: []u8,
) bufstream = {
	static let flush_default = ['\n': u8];
	let s = bufstream {
		source = src,
		rbuffer = rbuf,
		wbuffer = wbuf,
		flush = flush_default,
		...
	};
	if (len(rbuf) != 0 && len(wbuf) != 0) {
		assert(rbuf: *[*]u8 != wbuf: *[*]u8,
			"Cannot use bufio::buffered with same buffer for reads and writes");
		s.stream = &buffered_vtable_rw;
	} else if (len(rbuf) != 0) {
		s.stream = &buffered_vtable_r;
	} else if (len(wbuf) != 0) {
		s.stream = &buffered_vtable_w;
	} else abort("Must provide at least one buffer to bufio::buffered");
	return s;
};

// Flushes pending writes to the underlying stream.
export fn flush(s: *bufstream) (io::error | void) = {
	if (s.wavail == 0) {
		return;
	};
	io::writeall(s.source, s.wbuffer[..s.wavail])?;
	s.wavail = 0;
	return;
};

// Sets the list of bytes which will cause the stream to flush when written. By
// default, the stream will flush when a newline (\n) is written.
export fn setflush(s: *bufstream, b: []u8) void = {
	s.flush = b;
};

// "Unreads" a slice of bytes, such that the next call to "read" will return
// these bytes before reading any new data from the underlying source. The
// unread data must fit into the read buffer's available space. The amount of
// data which can be unread before the user makes any reads from a buffered
// stream is equal to the length of the read buffer, and otherwise it is equal
// to the length of the return value of the last call to [[io::read]] using this
// buffered stream. Attempting to unread more data than can fit into the read
// buffer will abort the program.
export fn unread(s: *bufstream, buf: []u8) void = {
	assert(len(s.rbuffer) - s.ravail >= len(buf),
		"Attempted to unread more data than buffer has available");
	let sl = s.rbuffer[..s.ravail];
	static insert(sl[0], buf...);
};

// Unreads a rune; see [[unread]].
export fn unreadrune(s: *bufstream, rn: rune) void = {
	const buf = utf8::encoderune(rn);
	unread(s, buf);
};

// Returns true if an [[io::handle]] is a [[buffered]] stream.
export fn isbuffered(in: io::handle) bool = {
	match (in) {
	case io::file =>
		return false;
	case let st: *io::stream =>
		return st.reader == &buffered_read || st.writer == &buffered_write;
	};
};

fn buffered_close_static(s: *io::stream) (void | io::error) = {
	assert(s.closer == &buffered_close_static);
	if (s.writer != null) {
		flush(s: *bufstream)?;
	};
};

fn buffered_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s.reader == &buffered_read);
	let s = s: *bufstream;
	let n = if (len(buf) < len(s.rbuffer)) len(buf) else len(s.rbuffer);
	if (n > s.ravail) {
		let z = match (io::read(s.source, s.rbuffer[s.ravail..])) {
		case let err: io::error =>
			return err;
		case io::EOF =>
			if (s.ravail == 0) {
				return io::EOF;
			};
			yield 0z;
		case let z: size =>
			yield z;
		};
		s.ravail += z;
		n = if (n > s.ravail) s.ravail else n;
		assert(n != 0);
	};

	buf[..n] = s.rbuffer[..n];
	s.rbuffer[..len(s.rbuffer) - n] = s.rbuffer[n..];
	s.ravail -= n;
	return n;
};

fn buffered_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	assert(s.writer == &buffered_write);
	let s = s: *bufstream;
	let buf = buf;

	let doflush = false;
	for (let i = 0z; i < len(buf); i += 1) {
		for (let j = 0z; j < len(s.flush); j += 1) {
			if (buf[i] == s.flush[j]) {
				doflush = true;
				break;
			};
		};
	};

	let z = 0z;
	for (len(buf) > 0) {
		let avail = len(s.wbuffer) - s.wavail;
		if (avail == 0) {
			flush(s)?;
			avail = len(s.wbuffer);
		};

		const n = if (avail < len(buf)) avail else len(buf);
		s.wbuffer[s.wavail..s.wavail + n] = buf[..n];
		buf = buf[n..];
		s.wavail += n;
		z += n;
	};

	if (doflush) {
		flush(s)?;
	};

	return z;
};

@test fn buffered_read() void = {
	let sourcebuf: []u8 = [1, 3, 3, 7];
	let source = fixed(sourcebuf, io::mode::READ);
	defer io::close(&source)!;

	let rbuf: [1024]u8 = [0...];
	let f = buffered(&source, rbuf, []);
	defer io::close(&f)!;

	let buf: [1024]u8 = [0...];
	assert(io::read(&f, buf[..2]) as size == 2);
	assert(source.pos == len(source.buf), "fixed stream was not fully consumed");
	assert(bytes::equal(buf[..2], [1, 3]));

	assert(io::read(&f, buf[2..]) as size == 2);
	assert(bytes::equal(buf[..4], [1, 3, 3, 7]));
	assert(io::read(&f, buf) is io::EOF);

	let sourcebuf: [32]u8 = [1, 3, 3, 7, 0...];
	let source = fixed(sourcebuf, io::mode::READ);

	let rbuf: [16]u8 = [0...];
	let f = buffered(&source, rbuf, []);
	defer io::close(&f)!;

	let buf: [32]u8 = [0...];
	assert(io::read(&f, buf) as size == 16);
	assert(source.pos == 16);

	assert(io::read(&f, buf[16..]) as size == 16);
	assert(bytes::equal(buf, sourcebuf));
	assert(io::read(&f, buf) is io::EOF);
	assert(source.pos == len(source.buf));
};

@test fn buffered_write() void = {
	// Normal case
	let sink = dynamic(io::mode::WRITE);
	defer io::close(&sink)!;

	let wbuf: [1024]u8 = [0...];
	let f = buffered(&sink, [], wbuf);
	defer io::close(&f)!;

	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(len(buffer(&sink)) == 0);
	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(flush(&f) is void);
	assert(bytes::equal(buffer(&sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via buffer exhaustion
	let sink = dynamic(io::mode::WRITE);
	defer io::close(&sink)!;

	let wbuf: [4]u8 = [0...];
	let f = buffered(&sink, [], wbuf);

	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(len(buffer(&sink)) == 0);
	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(bytes::equal(buffer(&sink), [1, 3, 3, 7]));
	io::close(&f)!; // Should flush
	assert(bytes::equal(buffer(&sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via flush characters
	let sink = dynamic(io::mode::WRITE);
	defer io::close(&sink)!;

	let wbuf: [1024]u8 = [0...];
	let f = buffered(&sink, [], wbuf);

	assert(io::writeall(&f, strings::toutf8("hello")) as size == 5);
	assert(len(buffer(&sink)) == 0);
	assert(io::writeall(&f, strings::toutf8(" world!\n")) as size == 8);
	assert(bytes::equal(buffer(&sink), strings::toutf8("hello world!\n")));
};

@test fn unread() void = {
	let rbuf: [8]u8 = [0...];
	let f = buffered(io::zero, rbuf, []);

	let buf: [16]u8 = [42...];
	assert(io::read(&f, buf[..4]) as size == 4);
	assert(buf[0] == 0);
	assert(buf[1] == 0);
	assert(buf[2] == 0);
	assert(buf[3] == 0);
	unread(&f, [1, 2, 3, 4]);

	assert(io::read(&f, buf[..8]) as size == 8);
	assert(buf[0] == 1);
	assert(buf[1] == 2);
	assert(buf[2] == 3);
	assert(buf[3] == 4);
	assert(buf[4] == 0);
	assert(buf[5] == 0);
	assert(buf[6] == 0);
	assert(buf[7] == 0);

	assert(io::read(&f, buf) as size == 8);
	for (let i = 0z; i < 8; i += 1) {
		assert(buf[i] == 0);
	};
};
