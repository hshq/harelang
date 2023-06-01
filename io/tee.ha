// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

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
	for (let n = 0z; n < z) {
		n += write(s.sink, buf[n..z])?;
	};
	return z;
};

fn tee_write(s: *stream, buf: const []u8) (size | error) = {
	let s = s: *teestream;
	const z = write(s.h, buf)?;
	for (let n = 0z; n < z) {
		n += write(s.sink, buf[n..z])?;
	};
	return z;
};
