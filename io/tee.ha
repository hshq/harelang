export type teestream = struct {
	stream,
	source: *stream,
	sink: *stream,
};

// Creates a reader which copies reads into a sink before forwarding them to the
// caller. This stream does not need to be closed, and closing it will not close
// the secondary streams.
export fn tee(source: *stream, sink: *stream) teestream = {
	return teestream {
		reader = &tee_read,
		unwrap = &tee_unwrap,
		source = source,
		sink = sink,
		...
	};
};

fn tee_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let s = s: *teestream;
	let z = match (read(s.source, buf)) {
		err: error => return err,
		EOF => return EOF,
		z: size => z,
	};
	for (let n = 0z; n < z) {
		n += write(s.sink, buf[n..z])?;
	};
	return z;
};

fn tee_unwrap(s: *stream) *io::stream = {
	assert(s.unwrap == &tee_unwrap);
	let s = s: *teestream;
	return s.source;
};
