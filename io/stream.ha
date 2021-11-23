use errors;

// A stream of bytes which supports some subset of read, write, close, seek, or
// copy operations. To create a custom stream, embed this type as the first
// member of a struct with user-specific data and fill out these fields as
// appropriate.
//
//	export type my_stream = struct {
//		io::stream,
//		fd: int,
//	};
//
//	export fn open(path: str) my_stream = {
//		let fd = // ...
//		return my_stream {
//			reader = &my_stream_read,
//			writer = &my_stream_write,
//			closer = null,
//			fd = fd,
//			...
//		});
//	};
//
//	let stream = open("example");
//	io::read(&stream, buf)!;
export type stream = struct {
	reader: nullable *reader,
	writer: nullable *writer,
	closer: nullable *closer,
	seeker: nullable *seeker,
	copier: nullable *copier,
};

fn st_read(s: *stream, buf: []u8) (size | EOF | error) = {
	match (s.reader) {
	case null =>
		return errors::unsupported;
	case r: *reader =>
		return r(s, buf);
	};
};

fn st_write(s: *stream, buf: const []u8) (size | error) = {
	match (s.writer) {
	case null =>
		return errors::unsupported;
	case w: *writer =>
		return w(s, buf);
	};
};

fn st_close(s: *stream) void = {
	match (s.closer) {
	case null => void;
	case c: *closer =>
		c(s);
	};
};

fn st_seek(s: *stream, off: off, w: whence) (off | error) = {
	match (s.seeker) {
	case null =>
		return errors::unsupported;
	case sk: *seeker =>
		return sk(s, off, w);
	};
};
