export type teestream = struct {
	stream,
	source: handle,
	sink: handle,
};

// Creates a reader which copies reads into a sink before forwarding them to the
// caller. This stream does not need to be closed, and closing it will not close
// the secondary streams.
export fn tee(source: handle, sink: handle) teestream = {
	return teestream {
		reader = &tee_read,
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
	case z: size =>
		yield z;
	};
	for (let n = 0z; n < z) {
		n += write(s.sink, buf[n..z])?;
	};
	return z;
};
