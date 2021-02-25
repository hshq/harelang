use bytes;
use io;

type dynamic_stream = struct {
	stream: io::stream,
	buf: []u8,
};

// Creates an [io::stream] which dynamically allocates a buffer to store writes
// into. Subsequent reads will consume the buffered data. Upon failure to
// allocate sufficient memory to store writes, the program aborts.
//
// Calling [io::close] on this stream will free the buffer. Call [bufio::finish]
// instead to free up resources associated with the stream, but transfer
// ownership of the buffer to the caller.
export fn dynamic() *io::stream = alloc(dynamic_stream {
	stream = io::stream {
		writer = &dynamic_write,
		closer = &dynamic_close,
		reader = &dynamic_read,
		...
	},
	buf = [],
}): *io::stream;

fn dynamic_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *dynamic_stream;
	append(s.buf, ...buf);
	return len(buf);
};

fn dynamic_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *dynamic_stream;
	const sz = if (len(buf) > len(s.buf)) len(s.buf) else len(buf);
	buf[..sz] = s.buf[..sz];
	delete(s.buf[..sz]);
	return if (sz == 0) io::EOF else sz;
};

fn dynamic_close(s: *io::stream) void = {
	const s = s: *dynamic_stream;
	free(s.buf);
	free(s);
};

// Closes the stream without freeing the buffer, instead transferring ownership
// of it to the caller.
export fn finish(s: *io::stream) []u8 = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		abort("bufio::finish called on non-bufio stream");
	};
	let s = s: *dynamic_stream;
	let buf = s.buf;
	free(s);
	return buf;
};

// Returns the current buffer.
export fn buffer(s: *io::stream) ([]u8 | io::unsupported) = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		abort("bufio::buffer called on non-bufio stream");
	};
	let s = s: *dynamic_stream;
	return s.buf;
};

// Resets the buffer's length to zero, but keeps the allocated memory around for
// future writes.
export fn reset(s: *io::stream) (void | io::unsupported) = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		return io::unsupported;
	};
	const s = s: *dynamic_stream;
	s.buf = s.buf[..0];
};

// Truncates the buffer, freeing memory associated with it and setting its
// length to zero.
export fn truncate(s: *io::stream) (void | io::unsupported) = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		return io::unsupported;
	};
	let s = s: *dynamic_stream;
	delete(s.buf[..]);
};

@test fn dynamic() void = {
	// TODO: slice/array equality
	let s = dynamic();
	assert(io::write(s, [1, 2, 3]) as size == 3);
	assert(bytes::equal(buffer(s) as []u8, [1, 2, 3]));
	assert(io::write(s, [4, 5]) as size == 2);
	assert(bytes::equal(buffer(s) as []u8, [1, 2, 3, 4, 5]));
	let buf: [2]u8 = [0...];
	assert(io::read(s, buf[..]) as size == 2 && bytes::equal(buf, [1, 2]));
	assert(io::read(s, buf[..]) as size == 2 && bytes::equal(buf, [3, 4]));
	assert(io::read(s, buf[..]) as size == 1 && buf[0] == 5);
	assert(io::read(s, buf[..]) is io::EOF);
	assert(io::write(s, [1, 2, 3]) as size == 3);
	assert(reset(s) is void);
	assert(len(buffer(s) as []u8) == 0);
	assert(io::write(s, [1, 2, 3]) as size == 3);
	assert(truncate(s) is void);
	assert(len(buffer(s) as []u8) == 0);
};
