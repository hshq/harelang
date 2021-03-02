use io;

type bufstream = struct {
	stream: io::stream,
	source: *io::stream,
	rbuffer: []u8,
	wbuffer: []u8,
	rfilled: []u8,
	wfilled: []u8,
	flush: []u8,
};

// Creates a stream which buffers reads and writes for the underlying stream.
// This is generally used to improve performance of small reads/writes for
// sources where I/O operations are costly, such as if they invoke a syscall or
// take place over the network.
//
// The caller should supply one or both of a read and write buffer as a slice of
// the desired buffer slice, or empty slices if read or write functionality is
// disabled (in which case the 'mode' argument must be set accordingly).
//
// When the buffered stream is closed, the underlying stream is also closed. The
// provided buffers are not freed.
export fn buffered(
	src: *io::stream,
	rbuf: []u8,
	wbuf: []u8,
	mode: io::mode,
) *io::stream = {
	let s = alloc(bufstream {
		stream = io::stream {
			name = src.name,
			closer = &buffered_close,
		},
		source = src,
		rbuffer = rbuf,
		wbuffer = wbuf,
		rfilled = rbuf[..0],
		wfilled = wbuf[..0],
		flush  = ['\n': u32: u8],
	}): *io::stream;
	if (mode & io::mode::READ == io::mode::READ) {
		assert(len(rbuf) != 0);
		s.reader = &buffered_read;
	};
	if (mode & io::mode::WRITE == io::mode::WRITE) {
		assert(len(wbuf) != 0);
		s.writer = &buffered_write;
	};
	return s;
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

fn buffered_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s.reader == &buffered_read);
	return io::unsupported; // TODO
};

fn buffered_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	assert(s.writer == &buffered_write);
	return io::unsupported; // TODO
};
