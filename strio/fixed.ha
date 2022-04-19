// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use io;
use slices;
use strings;

// Creates a write-only string stream using the provided buffer for storage.
// The program aborts if writes would exceed the buffer's capacity. The stream
// doesn't need to be closed.
export fn fixed(in: []u8) stream = {
	return stream {
		stream = io::stream {
			writer = &fixed_write,
			...
		},
		buf = in[..0],
	};
};

// Returns the current contents of the buffer as a string. Aborts the program if
// invalid UTF-8 has been written to the buffer.
export fn string(in: *stream) str = {
	let in = in: *stream;
	return strings::fromutf8(in.buf);
};

fn fixed_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *stream;
	let cap = slices::cap(s.buf);
	if (cap == len(s.buf)) {
		abort("strio::fixed buffer exceeded");
	};
	let n = if (cap - len(s.buf) < len(buf)) cap - len(s.buf) else len(buf);
	static append(s.buf, buf[..n]...);
	return n;
};

@test fn fixed() void = {
	static let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	io::write(&stream, strings::toutf8("hello ")) as size;
	io::write(&stream, strings::toutf8("world")) as size;
	assert(string(&stream) == "hello world");
};
