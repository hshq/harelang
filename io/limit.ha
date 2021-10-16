use strings;

export type limitstream = struct {
	stream,
	source: handle,
	limit: size,
};

fn limitstream_create(source: handle, limit: size) limitstream = {
	return limitstream {
		source = source,
		limit = limit,
		...
	};
};

// Create an overlay stream that only allows a limited amount of bytes to be
// read from the underlying stream. This stream does not need to be closed, and
// closing it does not close the underlying stream.
export fn limitreader(source: *stream, limit: size) limitstream = {
	let stream = limitstream_create(source, limit);
	stream.reader = &limit_read;
	return stream;
};

// Create an overlay stream that only allows a limited amount of bytes to be
// written to the underlying stream. This stream does not need to be closed, and
// closing it does not close the underlying stream.
export fn limitwriter(source: *stream, limit: size) limitstream = {
	let stream = limitstream_create(source, limit);
	stream.writer = &limit_write;
	return stream;
};

fn limit_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *limitstream;
	if (len(buf) > stream.limit) {
		buf = buf[..stream.limit];
	};
	stream.limit -= len(buf);
	return read(stream.source, buf);
};

fn limit_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *limitstream;
	let slice = if (len(buf) > stream.limit) {
		yield buf[..stream.limit];
	} else {
		yield buf[..];
	};
	stream.limit -= len(slice);
	return write(stream.source, slice);
};
