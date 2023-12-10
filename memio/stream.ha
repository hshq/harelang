// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::utf8;
use errors;
use io;
use strings;

export type stream = struct {
	stream: io::stream,
	buf: []u8,
	pos: size,
};

const fixed_vt: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	reader = &read,
	writer = &fixed_write,
	...
};

const dynamic_vt: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	reader = &read,
	writer = &dynamic_write,
	closer = &dynamic_close,
	...
};

// Creates a stream for a fixed, caller-supplied buffer. Seeking a stream will
// cause subsequent writes to overwrite existing contents of the buffer.
// Writes return an error if they would exceed the buffer's capacity. The
// stream doesn't have to be closed.
export fn fixed(in: []u8) stream = stream {
	stream = &fixed_vt,
	buf = in,
	pos = 0,
};

// Creates an [[io::stream]] which dynamically allocates a buffer to store
// writes into. Seeking the stream and reading will read the written data.
// Calling [[io::close]] on this stream will free the buffer. If a stream's
// data is referenced via [[buffer]], the stream shouldn't be closed as
// long as the data is used.
export fn dynamic() stream = dynamic_from([]);

// Like [[dynamic]], but takes an existing slice as input. Writes will
// overwrite the buffer and reads consume bytes from the initial buffer.
// Ownership of the provided slice is transferred to the returned [[stream]].
// Calling [[io::close]] will free the buffer.
export fn dynamic_from(in: []u8) stream = stream {
	stream = &dynamic_vt,
	buf = in,
	pos = 0,
};

// Returns a stream's buffer, up to the current cursor position.
// [[io::seek]] to the end first in order to return the entire buffer.
// The return value is borrowed from the input.
export fn buffer(in: *stream) []u8 = {
	return in.buf[..in.pos];
};

// Returns a stream's buffer, up to the current cursor position, as a string.
// [[io::seek]] to the end first in order to return the entire buffer.
// The return value is borrowed from the input.
export fn string(in: *stream) (str | utf8::invalid) = {
	return strings::fromutf8(in.buf[..in.pos]);
};

// A convenience function that sets the read-write cursor to zero, so that
// the buffer can be overwritten and reused.
export fn reset(in: *stream) void = {
	in.pos = 0;
	in.buf = in.buf[..0];
};

// Reads data from a [[dynamic]] or [[fixed]] stream and returns a slice
// borrowed from the internal buffer.
export fn borrowedread(st: *stream, amt: size) ([]u8 | io::EOF) = {
	if (len(st.buf) - st.pos < amt) {
		return io::EOF;
	};
	let buf = st.buf[st.pos..st.pos + amt];
	st.pos += len(buf);
	return buf;
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *stream;
	if (len(s.buf) == s.pos) {
		return io::EOF;
	};
	const n = if (len(s.buf) - s.pos < len(buf)) {
		yield len(s.buf) - s.pos;
	} else {
		yield len(buf);
	};
	assert(s.pos + n <= len(s.buf));
	buf[..n] = s.buf[s.pos..s.pos + n];
	s.pos += n;
	return n;
};

fn seek(
	s: *io::stream,
	off: io::off,
	w: io::whence
) (io::off | io::error) = {
	let s = s: *stream;
	let start = switch (w) {
	case io::whence::SET => yield 0z;
	case io::whence::CUR => yield s.pos;
	case io::whence::END => yield len(s.buf);
	};
	if (off < 0) {
		if (start < (-off): size) return errors::invalid;
	} else {
		if (len(s.buf) - start < off: size) return errors::invalid;
	};
	s.pos = start + off: size;
	return s.pos: io::off;
};

fn copy(dest: *io::stream, src: *io::stream) (size | io::error) = {
	if (src.reader != &read || dest.writer == null) {
		return errors::unsupported;
	};
	let src = src: *stream;
	return (dest.writer: *io::writer)(dest, src.buf[src.pos..]);
};

fn fixed_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	if (len(buf) == 0) {
		return 0z;
	};
	let s = s: *stream;
	if (s.pos >= len(s.buf)) {
		return errors::overflow;
	};
	const n = if (len(buf) > len(s.buf[s.pos..])) {
		yield len(s.buf[s.pos..]);
	} else {
		yield len(buf);
	};
	s.buf[s.pos..s.pos+n] = buf[..n];
	s.pos += n;
	return n;
};

fn dynamic_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *stream;
	let spare = len(s.buf) - s.pos;
	let bufend = if (spare < len(buf)) spare else len(buf);
	s.buf[s.pos..s.pos+bufend] = buf[..bufend];
	s.pos += bufend;
	if (bufend < len(buf)) {
		append(s.buf, buf[bufend..]...);
		s.pos += len(buf[bufend..]);
	};
	return len(buf);
};

fn dynamic_close(s: *io::stream) (void | io::error) = {
	const s = s: *stream;
	free(s.buf);
	s.buf = [];
	s.pos = 0;
};

@test fn fixed() void = {
	let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	defer io::close(&stream)!;

	let n = 0z;
	n += io::writeall(&stream, strings::toutf8("hello ")) as size;
	n += io::writeall(&stream, strings::toutf8("world")) as size;
	assert(bytes::equal(buf[..n], strings::toutf8("hello world")));
	assert(io::seek(&stream, 6, io::whence::SET) as io::off == 6: io::off);
	io::writeall(&stream, strings::toutf8("asdf")) as size;
	assert(bytes::equal(buf[..n], strings::toutf8("hello asdfd")));

	let out: [2]u8 = [0...];
	let s = fixed([1u8, 2u8]);
	defer io::close(&s)!;
	assert(io::read(&s, out[..1]) as size == 1 && out[0] == 1);
	assert(io::seek(&s, 1, io::whence::CUR) as io::off == 2: io::off);
	assert(io::read(&s, buf[..]) is io::EOF);
	assert(io::writeall(&s, [1, 2]) as io::error is errors::overflow);

	let in: [6]u8 = [0, 1, 2, 3, 4, 5];
	let out: [6]u8 = [0...];
	let source = fixed(in);
	let sink = fixed(out);
	io::copy(&sink, &source)!;
	assert(bytes::equal(in, out));

	assert(io::write(&sink, [])! == 0);

	static let buf: [1024]u8 = [0...];
	let stream = fixed(buf);
	assert(string(&stream)! == "");
	io::writeall(&stream, strings::toutf8("hello ")) as size;
	assert(string(&stream)! == "hello ");
	io::writeall(&stream, strings::toutf8("world")) as size;
	assert(string(&stream)! == "hello world");
};

@test fn dynamic() void = {
	let s = dynamic();
	defer io::close(&s)!;
	assert(io::writeall(&s, [1, 2, 3]) as size == 3);
	assert(bytes::equal(buffer(&s), [1, 2, 3]));
	assert(io::writeall(&s, [4, 5]) as size == 2);
	assert(bytes::equal(buffer(&s), [1, 2, 3, 4, 5]));
	let buf: [2]u8 = [0...];
	assert(io::seek(&s, 0, io::whence::SET) as io::off == 0: io::off);
	assert(io::read(&s, buf[..]) as size == 2 && bytes::equal(buf, [1, 2]));
	assert(io::read(&s, buf[..]) as size == 2 && bytes::equal(buf, [3, 4]));
	assert(io::read(&s, buf[..]) as size == 1 && buf[0] == 5);
	assert(io::read(&s, buf[..]) is io::EOF);
	assert(io::writeall(&s, [6, 7, 8]) as size == 3);
	assert(bytes::equal(buffer(&s), [1, 2, 3, 4, 5, 6, 7, 8]));
	reset(&s);
	assert(len(buffer(&s)) == 0);
	assert(io::writeall(&s, [1, 2, 3]) as size == 3);

	let sl: []u8 = alloc([1, 2, 3]);
	let s = dynamic_from(sl);
	defer io::close(&s)!;
	assert(io::writeall(&s, [0, 0]) as size == 2);
	assert(io::seek(&s, 0, io::whence::END) as io::off == 3: io::off);
	assert(io::writeall(&s, [4, 5, 6]) as size == 3);
	assert(bytes::equal(buffer(&s), [0, 0, 3, 4, 5, 6]));
	assert(io::read(&s, buf[..]) is io::EOF);

	sl = alloc([1, 2]);
	let s = dynamic_from(sl);
	defer io::close(&s)!;
	assert(io::read(&s, buf[..1]) as size == 1 && buf[0] == 1);
	assert(io::seek(&s, 1, io::whence::CUR) as io::off == 2: io::off);
	assert(io::read(&s, buf[..]) is io::EOF);
	assert(io::writeall(&s, [3, 4]) as size == 2 && bytes::equal(buffer(&s), [1, 2, 3, 4]));
	io::close(&s)!;
	assert(io::writeall(&s, [5, 6]) as size == 2 && bytes::equal(buffer(&s), [5, 6]));

	let in: [6]u8 = [0, 1, 2, 3, 4, 5];
	let source = dynamic_from(in);
	let sink = dynamic();
	defer io::close(&sink)!;
	io::copy(&sink, &source)!;
	assert(bytes::equal(in, buffer(&sink)));

	let in: [6]u8 = [0, 1, 2, 3, 4, 5];
	let source = dynamic_from(in);
	const borrowed = borrowedread(&source, len(in)-1) as []u8;
	assert(bytes::equal(borrowed, [0, 1, 2, 3, 4]));
	let source = dynamic_from(in);
	const borrowed = borrowedread(&source, len(in)) as []u8;
	assert(bytes::equal(borrowed, [0, 1, 2, 3, 4, 5]));
	let source = dynamic_from(in);
	assert(borrowedread(&source, len(in)+1) is io::EOF);

	let stream = dynamic();
	defer io::close(&stream)!;
	assert(string(&stream)! == "");
	io::writeall(&stream, strings::toutf8("hello ")) as size;
	assert(string(&stream)! == "hello ");
	io::writeall(&stream, strings::toutf8("world")) as size;
	assert(string(&stream)! == "hello world");
};
