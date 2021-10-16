use io;
use strings;

type fixed_stream = struct {
	stream: io::stream,
	buf: []u8,
	cur: []u8,
};

// Creates a write-only string stream using the provided buffer for storage.
// The program aborts if writes would exceed the buffer's capacity.
export fn fixed(in: []u8) io::handle = {
	let s = alloc(fixed_stream {
		stream = io::stream {
			writer = &fixed_write,
			closer = &fixed_close,
			...
		},
		buf = in,
		cur = in,
	});
	return &s.stream;
};

// Returns the current contents of the buffer as a string. Aborts the program if
// invalid UTF-8 has been written to the buffer.
export fn string(in: io::handle) str = {
	let stream = match (in) {
	case io::file =>
		abort("Invalid use of strio with io::file");
	case st: *io::stream =>
		yield st;
	};

	if (stream.writer == &fixed_write) {
		let stream = stream: *fixed_stream;
		const n = len(stream.buf) - len(stream.cur);
		return strings::fromutf8(stream.buf[..n]);
	} else if (stream.writer == &dynamic_write) {
		let stream = stream: *dynamic_stream;
		return strings::fromutf8(stream.buf);
	} else {
		abort("strio::string called on non-strio stream");
	};
};

fn fixed_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let stream = s: *fixed_stream;
	if (len(stream.cur) == 0) {
		abort("strio::fixed buffer exceeded");
	};
	const n = if (len(buf) > len(stream.cur)) len(stream.cur) else len(buf);
	stream.cur[..n] = buf[..n];
	stream.cur = stream.cur[n..];
	return n;
};

fn fixed_close(s: *io::stream) void = {
	free(s);
};

@test fn fixed() void = {
	static let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	defer io::close(stream);
	io::write(stream, strings::toutf8("hello ")) as size;
	io::write(stream, strings::toutf8("world")) as size;
	assert(string(stream) == "hello world");
};
