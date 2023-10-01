// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use rt;

let _stream_vt: io::vtable = io::vtable {
	reader = &rand_reader,
	...
};

const _stream: io::stream = &_stream_vt;

// An [[io::handle]] which returns cryptographically random data on reads. Be
// aware, it may return less than you asked for!
export let stream: *io::stream = &_stream;

@test fn buffer() void = {
	let buf: [4096]u8 = [0...];
	buffer(buf[..]);

	let sum = 0z;
	for (let i = 0z; i < len(buf); i += 1) {
		sum += buf[i];
	};
	let avg = sum / len(buf);
	assert(avg < 0xA0 && avg > 0x60);
};

@test fn reader() void = {
	let buf: [4096]u8 = [0...];
	let test: []u8 = [];
	match (io::readall(stream, buf[..])) {
	case (io::error | io::EOF) =>
		abort();
	case let n: size =>
		test = buf[..n];
	};

	assert(len(test) > 0);

	let sum = 0z;
	for (let i = 0z; i < len(test); i += 1) {
		sum += test[i];
	};
	let avg = sum / len(test);
	assert(avg < 0xA0 && avg > 0x60);
};
