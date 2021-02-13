use io;
use rt;

// XXX: All of this is temporary
export type fixed_stream = struct {
	stream: io::stream,
	buf: []u8,
};

export fn fixed(in: []u8) *io::stream = {
	let s = alloc(*fixed_stream, fixed_stream {
		stream = io::stream {
			name = "<bufio::fixed>",
			reader = &fixed_read,
			...
		},
		buf = in,
	});
	return &s.stream;
};

fn fixed_read(s: *io::stream, buf: []u8) (size | io::error | io::EOF) = {
	let stream = s: *fixed_stream;
	if (len(stream.buf) == 0) {
		return io::EOF;
	};
	const n = if (len(buf) > len(stream.buf)) len(stream.buf) else len(buf);
	// TODO: Fix me up once slice copying is in
	rt::memcpy(buf: *[*]u8, stream.buf: *[*]u8, n);
	stream.buf = stream.buf[n..];
	return n;
};
