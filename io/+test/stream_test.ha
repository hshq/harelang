// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

const teststream_vtable: vtable = vtable {
	reader = &teststream_read,
	writer = &teststream_write,
	...
};

type teststream = struct {
	stream: stream,
	r: size,
	nreads: size,
	w: size,
	nwrites: size,
};

fn teststream_open() teststream = teststream {
	stream = &teststream_vtable,
	...
};

fn teststream_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *teststream;
	stream.r += len(buf);
	stream.nreads += 1;
	return len(buf);
};

fn teststream_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *teststream;
	stream.w += len(buf);
	stream.nwrites += 1;
	return len(buf);
};

fn teststream_write_short(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *teststream;
	stream.nwrites += 1;
	if (len(buf) > 10) {
		stream.w += len(buf) / 2;
		return len(buf) / 2;
	} else {
		stream.w += len(buf);
		return len(buf);
	};
};
