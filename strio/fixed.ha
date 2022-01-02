use io;
use strings;

export type fixed_stream = struct {
	stream: io::stream,
	buf: []u8,
	cur: []u8,
};

// Creates a write-only string stream using the provided buffer for storage.
// The program aborts if writes would exceed the buffer's capacity. The stream
// doesn't need to be closed.
export fn fixed(in: []u8) fixed_stream = {
	return fixed_stream {
		stream = io::stream {
			writer = &fixed_write,
			...
		},
		buf = in,
		cur = in,
	};
};

// Returns the current contents of the buffer as a string. Aborts the program if
// invalid UTF-8 has been written to the buffer.
export fn string(in: (*fixed_stream | *dynamic_stream)) str = {
	match (in) {
	case let s: *fixed_stream =>
		const n = len(s.buf) - len(s.cur);
		return strings::fromutf8(s.buf[..n]);
	case let s: *dynamic_stream =>
		return strings::fromutf8(s.buf);
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

@test fn fixed() void = {
	static let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	io::write(&stream, strings::toutf8("hello ")) as size;
	io::write(&stream, strings::toutf8("world")) as size;
	assert(string(&stream) == "hello world");
};
