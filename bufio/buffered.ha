use bytes;
use encoding::utf8;
use errors;
use io;
use strings;

export type bufstream = struct {
	stream: io::stream,
	source: io::handle,
	rbuffer: []u8,
	wbuffer: []u8,
	ravail: size,
	wavail: size,
	flush: []u8,
	unread: []u8,
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
) io::handle = {
	let s = alloc(bufstream { ... });
	let st = static_buffered(src, rbuf, wbuf, s);
	st.closer = &buffered_close;
	return st;
};

export fn static_buffered(
	src: io::handle,
	rbuf: []u8,
	wbuf: []u8,
	s: *bufstream,
) *io::stream = {
	static let flush_default = ['\n': u32: u8];
	*s = bufstream {
		stream = io::stream {
			closer = &buffered_close_static,
			...
		},
		source = src,
		rbuffer = rbuf,
		wbuffer = wbuf,
		flush = flush_default,
		...
	};
	if (len(rbuf) != 0) {
		s.stream.reader = &buffered_read;
	};
	if (len(wbuf) != 0) {
		s.stream.writer = &buffered_write;
	};
	if (len(rbuf) != 0 && len(wbuf) != 0) {
		assert(rbuf: *[*]u8 != wbuf: *[*]u8,
			"Cannot use bufio::buffered with same buffer for reads and writes");
	};
	return &s.stream;
};

fn getstream(in: io::handle) *bufstream = {
	assert(isbuffered(in), "Attempted to use bufio on unbuffered stream");
	return in as *io::stream: *bufstream;
};

// Flushes pending writes to the underlying stream.
export fn flush(s: io::handle) (io::error | void) = {
	let s = getstream(s);
	if (s.wavail == 0) {
		return;
	};
	io::write(s.source, s.wbuffer[..s.wavail])?;
	s.wavail = 0;
	return;
};

// Sets the list of bytes which will cause the stream to flush when written. By
// default, the stream will flush when a newline (\n) is written.
export fn setflush(s: io::handle, b: []u8) void = {
	let s = getstream(s);
	s.flush = b;
};

// Unreads a slice of bytes. The next read calls on this buffer will consume the
// un-read data before consuming further data from the underlying source, or any
// buffered data.
export fn unread(s: io::handle, buf: []u8) void = {
	let s = getstream(s);
	append(s.unread, buf...);
};

// Unreads a rune; see [[unread]].
export fn unreadrune(s: io::handle, rn: rune) void = {
	let s = getstream(s);
	const buf = utf8::encoderune(rn);
	insert(s.unread[0], buf...);
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

fn buffered_close(s: *io::stream) void = {
	assert(s.closer == &buffered_close);
	if (s.writer != null) {
		flush(s)!;
	};
	free(s);
};

fn buffered_close_static(s: *io::stream) void = {
	assert(s.closer == &buffered_close_static);
	if (s.writer != null) {
		flush(s)!;
	};
};

fn buffered_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s.reader == &buffered_read);
	let s = s: *bufstream;
	if (len(s.unread) != 0) {
		let n = if (len(buf) < len(s.unread)) len(buf) else len(s.unread);
		buf[..n] = s.unread[..n];
		delete(s.unread[..n]);
		return n;
	};

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
			flush(&s.stream)?;
			avail = len(s.wbuffer);
		};

		const n = if (avail < len(buf)) avail else len(buf);
		s.wbuffer[s.wavail..s.wavail + n] = buf[..n];
		buf = buf[n..];
		s.wavail += n;
		z += n;
	};

	if (doflush) {
		flush(&s.stream)?;
	};

	return z;
};

@test fn buffered_read() void = {
	let sourcebuf: []u8 = [1, 3, 3, 7];
	let source = fixed(sourcebuf, io::mode::READ);
	let fb = source: *memstream;
	defer io::close(source);

	let rbuf: [1024]u8 = [0...];
	let f = buffered(source, rbuf, []);
	defer io::close(f);

	let buf: [1024]u8 = [0...];
	assert(io::read(f, buf[..2]) as size == 2);
	assert(fb.pos == len(fb.buf), "fixed stream was not fully consumed");
	assert(bytes::equal(buf[..2], [1, 3]));

	assert(io::read(f, buf[2..]) as size == 2);
	assert(bytes::equal(buf[..4], [1, 3, 3, 7]));
	assert(io::read(f, buf) is io::EOF);

	let sourcebuf: [32]u8 = [1, 3, 3, 7, 0...];
	let source = fixed(sourcebuf, io::mode::READ);
	let fb = source: *memstream;
	defer io::close(source);

	let rbuf: [16]u8 = [0...];
	let f = buffered(source, rbuf, []);
	defer io::close(f);

	let buf: [32]u8 = [0...];
	assert(io::read(f, buf) as size == 16);
	assert(fb.pos == 16);

	assert(io::read(f, buf[16..]) as size == 16);
	assert(bytes::equal(buf, sourcebuf));
	assert(io::read(f, buf) is io::EOF);
	assert(fb.pos == len(fb.buf));
};

@test fn buffered_write() void = {
	// Normal case
	let sink = dynamic(io::mode::WRITE);
	defer io::close(sink);

	let wbuf: [1024]u8 = [0...];
	let f = buffered(sink, [], wbuf);
	defer io::close(f);

	assert(io::write(f, [1, 3, 3, 7]) as size == 4);
	assert(len(buffer(sink)) == 0);
	assert(io::write(f, [1, 3, 3, 7]) as size == 4);
	assert(flush(f) is void);
	assert(bytes::equal(buffer(sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via buffer exhaustion
	let sink = dynamic(io::mode::WRITE);
	defer io::close(sink);

	let wbuf: [4]u8 = [0...];
	let f = buffered(sink, [], wbuf);

	assert(io::write(f, [1, 3, 3, 7]) as size == 4);
	assert(len(buffer(sink)) == 0);
	assert(io::write(f, [1, 3, 3, 7]) as size == 4);
	assert(bytes::equal(buffer(sink), [1, 3, 3, 7]));
	io::close(f); // Should flush
	assert(bytes::equal(buffer(sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via flush characters
	let sink = dynamic(io::mode::WRITE);
	defer io::close(sink);

	let wbuf: [1024]u8 = [0...];
	let f = buffered(sink, [], wbuf);

	assert(io::write(f, strings::toutf8("hello")) as size == 5);
	assert(len(buffer(sink)) == 0);
	assert(io::write(f, strings::toutf8(" world!\n")) as size == 8);
	assert(bytes::equal(buffer(sink), strings::toutf8("hello world!\n")));
};
