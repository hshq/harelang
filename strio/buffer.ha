use io;
use strings;

type fixed_stream = struct {
	stream: io::stream,
	buf: []u8,
	cur: []u8,
};

// Creates a write-only string stream using the provided buffer for storage.
// The buffer will not be expanded if the writes exceed its capacity.
export fn fixed(in: []u8) *io::stream = {
	let s = alloc(fixed_stream {
		stream = io::stream {
			name = "<strio::fixed>",
			writer = &fixed_write,
			...
		},
		buf = in,
		cur = in,
	});
	return &s.stream;
};

// Returns the current contents of the buffer as a string. Aborts the program if
// invalid UTF-8 has been written to the buffer.
export fn string(s: *io::stream) str = {
	assert(s.writer == &fixed_write);
	let stream = s: *fixed_stream;
	const n = len(stream.buf) - len(stream.cur);
	return strings::from_utf8(stream.buf[..n]);
};

fn fixed_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let stream = s: *fixed_stream;
	if (len(stream.cur) == 0) {
		return 0z;
	};
	const n = if (len(buf) > len(stream.cur)) len(stream.cur) else len(buf);
	stream.cur[..n] = buf[..n];
	stream.cur = stream.cur[n..];
	return n;
};

@test fn fixed() void = {
	static let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	io::write(stream, strings::to_utf8("hello ")) as size;
	io::write(stream, strings::to_utf8("world")) as size;
	assert(string(stream) == "hello world");
};
