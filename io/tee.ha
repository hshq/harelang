// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

export type teestream = struct {
	vtable: stream,
	source: handle,
	sink: handle,
};

const tee_vtable: vtable = vtable {
	reader = &tee_read,
	...
};

// Creates a reader which copies reads into a sink before forwarding them to the
// caller. This stream does not need to be closed, and closing it will not close
// the secondary streams.
export fn tee(source: handle, sink: handle) teestream = {
	return teestream {
		vtable = &tee_vtable,
		source = source,
		sink = sink,
		...
	};
};

fn tee_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let s = s: *teestream;
	let z = match (read(s.source, buf)?) {
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
