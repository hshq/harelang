use strings;

type test_stream = struct {
	stream: stream,
	r: size,
	nreads: size,
	w: size,
	nwrites: size,
};

fn test_stream_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *test_stream;
	stream.r += len(buf);
	stream.nreads += 1;
	return len(buf);
};

fn test_stream_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *test_stream;
	stream.w += len(buf);
	stream.nwrites += 1;
	return len(buf);
};

fn test_stream_write_short(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *test_stream;
	stream.nwrites += 1;
	if (len(buf) > 10) {
		stream.w += len(buf) / 2;
		return len(buf) / 2;
	} else {
		stream.w += len(buf);
		return len(buf);
	};
};

fn test_stream_open() test_stream = test_stream {
	stream = stream {
		name = strings::dup("test_stream"),
		reader = &test_stream_read,
		writer = &test_stream_write,
		closer = &test_stream_close,
		...
	},
	...
};

fn test_stream_close(s: *stream) void = {
	let stream = s: *test_stream;
	free(stream.stream.name);
};
