use strings;

type test_stream = struct {
	stream: stream,
	n: size,
};

fn test_stream_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *test_stream;
	stream.n = len(buf);
	return len(buf);
};

fn test_stream_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *test_stream;
	stream.n = len(buf);
	return len(buf);
};

fn test_stream_open() test_stream = test_stream {
	stream = stream {
		name = strings::dup("test_stream"),
		reader = &test_stream_read,
		writer = &test_stream_write,
		closer = &test_stream_close,
		...
	},
	n = 0z,
};

fn test_stream_close(s: *stream) void = {
	let stream = s: *test_stream;
	free(stream.stream.name);
};
