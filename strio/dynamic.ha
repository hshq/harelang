use errors;
use io;
use strings;

type dynamic_stream = struct {
	stream: io::stream,
	buf: []u8,
};

// Creates a write-only string stream using an allocated buffer for storage, for
// efficiently building strings.
//
// Calling [io::close] on this stream will free the buffer. Call [strio::finish]
// instead to free up resources associated with the stream, but transfer
// ownership of the buffer to the caller.
export fn dynamic() *io::stream = {
	let s = alloc(dynamic_stream {
		stream = io::stream {
			name = "<strio::dynamic>",
			writer = &dynamic_write,
			closer = &dynamic_close,
			...
		},
		buf = [],
	});
	return &s.stream;
};

// Closes the stream without freeing the buffer, instead transferring ownership
// of it to the caller.
export fn finish(s: *io::stream) str = {
	assert(s.writer == &dynamic_write,
		"strio::finish called on non-strio stream");
	let s = s: *dynamic_stream;
	let buf = s.buf;
	free(s);
	return strings::fromutf8(buf);
};

// Resets the buffer's length to zero, but keeps the allocated memory around for
// future writes.
export fn reset(s: *io::stream) (void | errors::unsupported) = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		return errors::unsupported;
	};
	const s = s: *dynamic_stream;
	s.buf = s.buf[..0];
};

// Truncates the buffer, freeing memory associated with it and setting its
// length to zero.
export fn truncate(s: *io::stream) (void | errors::unsupported) = {
	if (s.writer != &dynamic_write || s.closer != &dynamic_close) {
		return errors::unsupported;
	};
	let s = s: *dynamic_stream;
	delete(s.buf[..]);
};

fn dynamic_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *dynamic_stream;
	append(s.buf, buf...);
	return len(buf);
};

fn dynamic_close(s: *io::stream) void = {
	const s = s: *dynamic_stream;
	free(s.buf);
	free(s);
};

@test fn dynamic() void = {
	let stream = dynamic();
	io::write(stream, strings::toutf8("hello ")) as size;
	io::write(stream, strings::toutf8("world")) as size;
	assert(string(stream) == "hello world");
	let s = finish(stream);
	assert(s == "hello world");
	free(s);
};
