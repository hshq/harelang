// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type teestream = struct {
	vtable: stream,
	h: handle,
	sink: handle,
};

const tee_vtable: vtable = vtable {
	reader = &tee_read,
	writer = &tee_write,
	...
};

// Creates a stream which copies writes and reads into 'sink' after forwarding
// them to the handle 'h'. This stream does not need to be closed, and closing
// it will not close the secondary stream.
export fn tee(h: handle, sink: handle) teestream = {
	return teestream {
		vtable = &tee_vtable,
		h = h,
		sink = sink,
		...
	};
};

fn tee_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let s = s: *teestream;
	let z = match (read(s.h, buf)?) {
	case EOF =>
		return EOF;
	case let z: size =>
		yield z;
	};
	writeall(s.sink, buf[..z])?;
	return z;
};

fn tee_write(s: *stream, buf: const []u8) (size | error) = {
	let s = s: *teestream;
	const z = write(s.h, buf)?;
	writeall(s.sink, buf[..z])?;
	return z;
};
