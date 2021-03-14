use bytes;
use io;

export type bufstream = struct {
	stream: io::stream,
	source: *io::stream,
	rbuffer: []u8,
	wbuffer: []u8,
	rfilled: []u8,
	wfilled: []u8,
	flush: []u8,
};

export fn static_buffered(
	src: *io::stream,
	rbuf: []u8,
	wbuf: []u8,
	s: *bufstream,
) *io::stream = {
	*s = bufstream {
		stream = io::stream {
			name = src.name,
			closer = &buffered_close,
			unwrap = &buffered_unwrap,
		},
		source = src,
		rbuffer = rbuf,
		wbuffer = wbuf,
		flush   = ['\n': u32: u8],
		...
	};
	if (len(rbuf) != 0) {
		s.rfilled = rbuf[..0];
		s.stream.reader = &buffered_read;
	};
	if (len(wbuf) != 0) {
		s.wfilled = wbuf[..0];
		s.stream.writer = &buffered_write;
	};
	if (len(rbuf) != 0 && len(wbuf) != 0) {
		assert(rbuf: *[*]u8 != wbuf: *[*]u8,
			"Cannot use bufio::buffered with same buffer for reads and writes");
	};
	return &s.stream;
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
// When the buffered stream is closed, the underlying stream is also closed. The
// provided buffers are not freed.
export fn buffered(
	src: *io::stream,
	rbuf: []u8,
	wbuf: []u8,
) *io::stream = {
	let s = alloc(bufstream { ... });
	return static_buffered(src, rbuf, wbuf, s);
};

// Flushes pending writes to the underlying stream.
export fn flush(s: *io::stream) void = {
	assert(s.closer == &buffered_close,
		"bufio::flushed used on non-buffered stream");
	let s = s: *bufstream;
	abort(); // TODO
};

// Sets the list of bytes which will cause the stream to flush when written. By
// default, the stream will flush when a newline (\n) is written.
export fn set_flush_bytes(s: *io::stream, b: []u8) void = {
	assert(s.closer == &buffered_close,
		"bufio::set_flush_bytes used on non-buffered stream");
	let s = s: *bufstream;
	s.flush = b;
};

fn buffered_close(s: *io::stream) void = {
	assert(s.closer == &buffered_close);
	let s = s: *bufstream;
	io::close(s.source);
	free(s);
};

fn buffered_unwrap(s: *io::stream) *io::stream = {
	assert(s.unwrap == &buffered_unwrap);
	let s = s: *bufstream;
	return s.source;
};

fn buffered_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s.reader == &buffered_read);
	let s = s: *bufstream;

	let n = if (len(buf) < len(s.rbuffer)) len(buf) else len(s.rbuffer);
	if (n > len(s.rfilled)) {
		let z = match (io::read(s.source, s.rbuffer[len(s.rfilled)..])) {
			err: io::error => return err,
			io::EOF => {
				if (len(s.rfilled) == 0) {
					return io::EOF;
				};
				0z;
			},
			z: size => z,
		};
		s.rfilled = s.rbuffer[..len(s.rfilled) + z];
		n = if (n > len(s.rfilled)) len(s.rfilled) else n;
		assert(n != 0);
	};

	buf[..n] = s.rfilled[..n];
	s.rbuffer[..len(s.rbuffer) - n] = s.rbuffer[n..];
	s.rfilled = s.rfilled[n..];
	return n;
};

fn buffered_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	assert(s.writer == &buffered_write);
	return io::unsupported; // TODO
};

@test fn buffered_read() void = {
	let sourcebuf: []u8 = [1, 3, 3, 7];
	let source = fixed(sourcebuf, io::mode::READ);
	let fb = source: *fixed_stream;
	defer io::close(source);

	let rbuf: [1024]u8 = [0...];
	let f = buffered(source, rbuf, []);
	defer io::close(f);

	let buf: [1024]u8 = [0...];
	assert(io::read(f, buf[..2]) as size == 2);
	assert(len(fb.buf) == 0, "fixed stream was not fully consumed");
	assert(bytes::equal(buf[..2], [1, 3]));

	assert(io::read(f, buf[2..]) as size == 2);
	assert(bytes::equal(buf[..4], [1, 3, 3, 7]));
	assert(io::read(f, buf) is io::EOF);

	let sourcebuf: [32]u8 = [1, 3, 3, 7, 0...];
	sourcebuf[32..36] = [7, 3, 3, 1];
	let source = fixed(sourcebuf, io::mode::READ);
	let fb = source: *fixed_stream;
	defer io::close(source);

	let rbuf: [16]u8 = [0...];
	let f = buffered(source, rbuf, []);
	defer io::close(f);

	let buf: [32]u8 = [0...];
	assert(io::read(f, buf) as size == 16);
	assert(len(fb.buf) == 16);

	assert(io::read(f, buf[16..]) as size == 16);
	assert(bytes::equal(buf, sourcebuf));
	assert(io::read(f, buf) is io::EOF);
	assert(len(fb.buf) == 0);
};
