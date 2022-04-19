// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use errors;
use io;
use strings;

export type stream = struct {
	stream: io::stream,
	buf: []u8,
};

// Creates a write-only string stream using an allocated buffer for storage, for
// efficiently building strings.
//
// Calling [[io::close]] on this stream will free the buffer. If stream's data
// is transfered via [[string]], it shouldn't be closed as long if the data is
// freed.
export fn dynamic() stream = {
	return stream {
		stream = io::stream {
			writer = &dynamic_write,
			closer = &dynamic_close,
			...
		},
		buf = [],
	};
};

// Resets the buffer's length to zero, but keeps the allocated memory around for
// future writes.
export fn reset(in: *stream) void = {
	in.buf = in.buf[..0];
};

// Truncates the buffer, freeing memory associated with it and setting its
// length to zero.
export fn truncate(in: *stream) void = {
	delete(in.buf[..]);
};

fn dynamic_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *stream;
	append(s.buf, buf...);
	return len(buf);
};

fn dynamic_close(s: *io::stream) void = {
	const s = s: *stream;
	free(s.buf);
};

@test fn dynamic() void = {
	let stream = dynamic();
	defer io::close(&stream);
	io::write(&stream, strings::toutf8("hello ")) as size;
	io::write(&stream, strings::toutf8("world")) as size;
	assert(string(&stream) == "hello world");
};
