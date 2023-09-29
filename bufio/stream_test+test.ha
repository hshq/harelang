// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use io;
use memio;
use strings;

@test fn read() void = {
	let sourcebuf: []u8 = [1, 3, 3, 7];
	let source = memio::fixed(sourcebuf);
	defer io::close(&source)!;

	let rbuf: [1024]u8 = [0...];
	let f = init(&source, rbuf, []);
	defer io::close(&f)!;

	let buf: [1024]u8 = [0...];
	assert(io::read(&f, buf[..2]) as size == 2);
	assert(source.pos == len(source.buf), "fixed stream was not fully consumed");
	assert(bytes::equal(buf[..2], [1, 3]));

	assert(io::read(&f, buf[2..]) as size == 2);
	assert(bytes::equal(buf[..4], [1, 3, 3, 7]));
	assert(io::read(&f, buf) is io::EOF);

	let sourcebuf: [32]u8 = [1, 3, 3, 7, 0...];
	let source = memio::fixed(sourcebuf);

	let rbuf: [16]u8 = [0...];
	let f = init(&source, rbuf, []);
	defer io::close(&f)!;

	let buf: [32]u8 = [0...];
	assert(io::read(&f, buf) as size == 16);
	assert(source.pos == 16);

	assert(io::read(&f, buf[16..]) as size == 16);
	assert(bytes::equal(buf, sourcebuf));
	assert(io::read(&f, buf) is io::EOF);
	assert(source.pos == len(source.buf));
};

@test fn write() void = {
	// Normal case
	let sink = memio::dynamic();
	defer io::close(&sink)!;

	let wbuf: [1024]u8 = [0...];
	let f = init(&sink, [], wbuf);
	defer io::close(&f)!;

	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(len(memio::buffer(&sink)) == 0);
	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(flush(&f) is void);
	assert(bytes::equal(memio::buffer(&sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via buffer exhaustion
	let sink = memio::dynamic();
	defer io::close(&sink)!;

	let wbuf: [4]u8 = [0...];
	let f = init(&sink, [], wbuf);

	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(len(memio::buffer(&sink)) == 0);
	assert(io::writeall(&f, [1, 3, 3, 7]) as size == 4);
	assert(bytes::equal(memio::buffer(&sink), [1, 3, 3, 7]));
	io::close(&f)!; // Should flush
	assert(bytes::equal(memio::buffer(&sink), [1, 3, 3, 7, 1, 3, 3, 7]));

	// Test flushing via flush characters
	let sink = memio::dynamic();
	defer io::close(&sink)!;

	let wbuf: [1024]u8 = [0...];
	let f = init(&sink, [], wbuf);

	assert(io::writeall(&f, strings::toutf8("hello")) as size == 5);
	assert(len(memio::buffer(&sink)) == 0);
	assert(io::writeall(&f, strings::toutf8(" world!\n")) as size == 8);
	assert(bytes::equal(memio::buffer(&sink), strings::toutf8("hello world!\n")));
};

@test fn unread() void = {
	let rbuf: [8]u8 = [0...];
	let f = init(io::zero, rbuf, []);

	let buf: [16]u8 = [42...];
	assert(io::read(&f, buf[..4]) as size == 4);
	assert(buf[0] == 0);
	assert(buf[1] == 0);
	assert(buf[2] == 0);
	assert(buf[3] == 0);
	unread(&f, [1, 2, 3, 4]);

	assert(io::read(&f, buf[..8]) as size == 8);
	assert(buf[0] == 1);
	assert(buf[1] == 2);
	assert(buf[2] == 3);
	assert(buf[3] == 4);
	assert(buf[4] == 0);
	assert(buf[5] == 0);
	assert(buf[6] == 0);
	assert(buf[7] == 0);

	assert(io::read(&f, buf) as size == 8);
	for (let i = 0z; i < 8; i += 1) {
		assert(buf[i] == 0);
	};

	let input: []u8 = [1, 2, 3, 4];
	let f = init(&memio::fixed(input), rbuf, []);

	assert(io::read(&f, buf) as size == 4);
	unread(&f, [1, 2, 3, 4]);
	assert(io::read(&f, buf) as size == 4);
	assert(io::read(&f, buf) is io::EOF);
};
