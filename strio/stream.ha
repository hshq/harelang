// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use io;
use slices;
use strings;

const fixed_vtable: io::vtable = io::vtable {
	writer = &fixed_write,
	...
};

export type stream = struct {
	stream: io::stream,
	buf: []u8,
};

// Returns the current contents of the buffer as a string. Aborts the program if
// invalid UTF-8 has been written to the buffer. The return value is borrowed
// from the stream, and will be freed when the stream is closed. Use
// [[strings::dup]] to extend its lifetime.
export fn string(in: *stream) str = {
	return strings::fromutf8(in.buf)!;
};

// Resets the buffer's length to zero, but does not attempt to deallocate its
// backing memory. Suitable for use both with fixed and dynamic streams.
export fn reset(in: *stream) void = {
	in.buf = in.buf[..0];
};

// Creates a write-only string stream using the provided buffer for storage.
// The program aborts if writes would exceed the buffer's capacity. The stream
// doesn't need to be closed.
export fn fixed(in: []u8) stream = {
	return stream {
		stream = &fixed_vtable,
		buf = in[..0],
	};
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
	io::writeall(&stream, strings::toutf8("hello ")) as size;
	io::writeall(&stream, strings::toutf8("world")) as size;
	assert(string(&stream) == "hello world");
};

const dynamic_vtable: io::vtable = io::vtable {
	writer = &dynamic_write,
	closer = &dynamic_close,
	...
};

// Creates a write-only string stream using an allocated buffer for storage, for
// efficiently building strings.
//
// Calling [[io::close]] on this stream will free the buffer.
export fn dynamic() stream = {
	return stream {
		stream = &dynamic_vtable,
		buf = [],
	};
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

fn dynamic_close(s: *io::stream) (void | io::error) = {
	const s = s: *stream;
	free(s.buf);
};

@test fn dynamic() void = {
	let stream = dynamic();
	defer io::close(&stream)!;
	io::writeall(&stream, strings::toutf8("hello ")) as size;
	io::writeall(&stream, strings::toutf8("world")) as size;
	assert(string(&stream) == "hello world");
};
