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
// Calling [[io::close]] on this stream will free the buffer. Call [[strio::finish]]
// instead to free up resources associated with the stream, but transfer
// ownership of the buffer to the caller.
export fn dynamic() io::handle = {
	let s = alloc(dynamic_stream {
		stream = io::stream {
			writer = &dynamic_write,
			closer = &dynamic_close,
			...
		},
		buf = [],
	});
	return &s.stream;
};

fn get_dynamic_stream(in: io::handle) *dynamic_stream = {
	match (in) {
	case io::file =>
		abort("Invalid use of strio on io::file");
	case st: *io::stream =>
		assert(st.writer == &dynamic_write,
			"Invalid use of strio on non-strio I/O stream");
		return st: *dynamic_stream;
	};
};

// Closes the stream without freeing the buffer, instead transferring ownership
// of it to the caller.
export fn finish(in: io::handle) str = {
	let s = get_dynamic_stream(in);
	let buf = s.buf;
	free(s);
	return strings::fromutf8(buf);
};

// Resets the buffer's length to zero, but keeps the allocated memory around for
// future writes.
export fn reset(in: io::handle) void = {
	const s = get_dynamic_stream(in);
	s.buf = s.buf[..0];
};

// Truncates the buffer, freeing memory associated with it and setting its
// length to zero.
export fn truncate(in: io::handle) void = {
	let s = get_dynamic_stream(in);
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
