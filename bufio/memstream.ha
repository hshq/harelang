// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use io;
use strings;
use errors;

export type memstream = struct {
	stream: io::stream,
	buf: []u8,
	pos: size,
};

const memstream_vt_r: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	reader = &read,
	...
};

const fixed_vt_w: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	writer = &fixed_write,
	...
};

const fixed_vt_rw: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	reader = &read,
	writer = &fixed_write,
	...
};

// Creates a stream for a fixed, caller-supplied buffer. All fixed streams are
// seekable; seeking a write stream will cause subsequent writes to overwrite
// existing contents of the buffer. The program aborts if writes would exceed
// the buffer's capacity. The stream doesn't have to be closed.
export fn fixed(in: []u8, mode: io::mode) memstream = {
	let s = memstream {
		stream = &memstream_vt_r,
		buf = in,
		pos = 0,
	};
	if (mode & io::mode::RDWR == io::mode::RDWR) {
		s.stream = &fixed_vt_rw;
	} else if (mode & io::mode::WRITE == io::mode::WRITE) {
		s.stream = &fixed_vt_w;
	} else if (mode & io::mode::READ == io::mode::READ) {
		s.stream = &memstream_vt_r;
	};
	return s;
};

fn fixed_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	if (len(buf) == 0) {
		return 0z;
	};
	let s = s: *memstream;
	if (s.pos >= len(s.buf)) {
		abort("bufio::fixed buffer exceeded");
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

const dynamic_vt_w: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	writer = &dynamic_write,
	...
};

const dynamic_vt_rw: io::vtable = io::vtable {
	seeker = &seek,
	copier = &copy,
	reader = &read,
	writer = &dynamic_write,
	...
};

// Creates an [[io::stream]] which dynamically allocates a buffer to store
// writes into. Subsequent reads will consume the buffered data. Upon failure to
// allocate sufficient memory to store writes, the program aborts.
//
// Calling [[io::close]] on this stream will free the buffer. If a stream's data
// is transferred via [[buffer]], the stream shouldn't be closed as long as the
// data is freed.
export fn dynamic(mode: io::mode) memstream = dynamic_from([], mode);

// Like [[dynamic]], but takes an existing slice as input. Writes are appended
// to it and reads consume bytes from the initial buffer, plus any additional
// writes. Like [[dynamic]], calling [[io::close]] will free the buffer.
export fn dynamic_from(in: []u8, mode: io::mode) memstream = {
	let s = memstream {
		stream = &memstream_vt_r,
		buf = in,
		pos = 0,
	};
	if (mode & io::mode::RDWR == io::mode::RDWR) {
		s.stream = &dynamic_vt_rw;
	} else if (mode & io::mode::WRITE == io::mode::WRITE) {
		s.stream = &dynamic_vt_w;
	} else if (mode & io::mode::READ == io::mode::READ) {
		s.stream = &memstream_vt_r;
	};
	return s;
};

// Returns the current buffer of a [[fixed]] or [[dynamic]] stream.
export fn buffer(in: *memstream) []u8 = {
	return in.buf;
};

// Resets the dynamic buffer's length to zero, but keeps the allocated memory
// around for future writes.
export fn reset(in: *memstream) void = {
	in.pos = 0;
	in.buf = in.buf[..0];
};

// Truncates the dynamic buffer, freeing memory associated with it and setting
// its length to zero.
export fn truncate(in: *memstream) (void | errors::unsupported) = {
	in.pos = 0;
	delete(in.buf[..]);
};

// Reads data from a [[dynamic]] or [[fixed]] stream and returns a slice
// borrowed from the internal buffer.
export fn borrowedread(st: *memstream, amt: size) ([]u8 | io::EOF) = {
	if (len(st.buf) - st.pos <= amt) {
		return io::EOF;
	};
	let buf = st.buf[st.pos..st.pos + amt];
	st.pos += len(buf);
	return buf;
};

fn dynamic_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *memstream;
	insert(s.buf[s.pos], buf...);
	s.pos += len(buf);
	return len(buf);
};

fn dynamic_close(s: *io::stream) (void | io::error) = {
	const s = s: *memstream;
	free(s.buf);
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *memstream;
	if (len(s.buf) == s.pos && len(buf) != 0) {
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
	let s = s: *memstream;
	switch (w) {
	case io::whence::SET =>
		if (len(s.buf) < off: size) {
			abort("invalid offset");
		};
		s.pos = off: size;
	case io::whence::CUR =>
		if (s.pos + off: size > len(s.buf)) {
			abort("invalid offset");
		};
		s.pos += off: size;
	case io::whence::END =>
		if (len(s.buf) - (-off): size < len(s.buf)) {
			abort("invalid offset");
		};
		s.pos = len(s.buf) - (-off): size;
	};
	return s.pos: io::off;
};

fn copy(dest: *io::stream, src: *io::stream) (io::error | size) = {
	if (src.reader != &read || src.writer == null) {
		return errors::unsupported;
	};
	let src = src: *memstream;
	return (dest.writer: *io::writer)(dest, src.buf[src.pos..]);
};

@test fn dynamic() void = {
	let s = dynamic(io::mode::RDWR);
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
	assert(truncate(&s) is void);
	assert(len(buffer(&s)) == 0);

	let sl: []u8 = alloc([1, 2, 3]);
	let s = dynamic_from(sl, io::mode::WRITE);
	assert(io::writeall(&s, [0, 0]) as size == 2);
	assert(io::seek(&s, 0, io::whence::END) as io::off == 5: io::off);
	assert(io::writeall(&s, [4, 5, 6]) as size == 3);
	assert(bytes::equal(buffer(&s), [0, 0, 1, 2, 3, 4, 5, 6]));
	assert(io::read(&s, buf[..]) as io::error is errors::unsupported);
	io::close(&s)!;

	sl = alloc([1, 2]);
	let s = dynamic_from(sl, io::mode::READ);
	assert(io::read(&s, buf[..1]) as size == 1 && buf[0] == 1);
	assert(io::seek(&s, 1, io::whence::CUR) as io::off == 2: io::off);
	assert(io::read(&s, buf[..]) is io::EOF);
	assert(io::write(&s, [1, 2]) as io::error is errors::unsupported);
	io::close(&s)!;
	assert(io::writeall(&s, [1, 2]) as io::error is errors::unsupported);
	io::close(&s)!;

	let in: [6]u8 = [0, 1, 2, 3, 4, 5];
	let source = dynamic_from(in, io::mode::READ);
	let sink = dynamic(io::mode::WRITE);
	io::copy(&sink, &source)!;
	assert(bytes::equal(in, buffer(&sink)));
};

@test fn fixed() void = {
	let buf: [1024]u8 = [0...];
	let stream = fixed(buf, io::mode::WRITE);
	defer io::close(&stream)!;

	let n = 0z;
	n += io::writeall(&stream, strings::toutf8("hello ")) as size;
	n += io::writeall(&stream, strings::toutf8("world")) as size;
	assert(bytes::equal(buf[..n], strings::toutf8("hello world")));
	assert(io::seek(&stream, 6, io::whence::SET) as io::off == 6: io::off);
	io::writeall(&stream, strings::toutf8("asdf")) as size;
	assert(bytes::equal(buf[..n], strings::toutf8("hello asdfd")));

	let out: [2]u8 = [0...];
	let s = fixed([1u8, 2u8], io::mode::READ);
	defer io::close(&s)!;
	assert(io::read(&s, out[..1]) as size == 1 && out[0] == 1);
	assert(io::seek(&s, 1, io::whence::CUR) as io::off == 2: io::off);
	assert(io::read(&s, buf[..]) is io::EOF);
	assert(io::writeall(&s, [1, 2]) as io::error is errors::unsupported);

	let in: [6]u8 = [0, 1, 2, 3, 4, 5];
	let out: [6]u8 = [0...];
	let source = fixed(in, io::mode::READ);
	let sink = fixed(out, io::mode::WRITE);
	io::copy(&sink, &source)!;
	assert(bytes::equal(in, out));

	assert(io::write(&sink, [])! == 0);
};
