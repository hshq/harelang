// A stream of bytes which supports some subset of read, write, close, or seek
// operations. To create a custom stream, embed this type as the first member of
// a struct with user-specific data and fill out these fields as appropriate.
//
//	type my_stream = struct {
//		io::stream,
//		fd: int,
//	};
//
//	fn open(path: str) *io::stream = {
//		let fd = // ...
//		let stream = alloc(*my_stream, my_stream {
//			name   = strings::dup(path),
//			reader = &my_stream_read,
//			writer = &my_stream_write,
//			closer = null,
//			fd: fd,
//			...
//		});
//		return &stream.stream;
//	};
export type stream = struct {
	name:   str,
	reader: nullable *reader,
	writer: nullable *writer,
	closer: nullable *closer,
	copier: nullable *copier,
	seeker: nullable *seeker,
};

// Reads up to len(buf) bytes from the reader into the given buffer, returning
// the number of bytes read.
export fn read(s: *stream, buf: []u8) (size | EOF | error) = {
	return match (s.reader) {
		null => unsupported,
		r: *reader => r(s, buf),
	};
};

// Writes up to len(buf) bytes to the stream from the given buffer, returning
// the number of bytes written.
export fn write(s: *stream, buf: const []u8) (size | error) = {
	return match (s.writer) {
		null => unsupported,
		w: *writer => w(s, buf),
	};
};

// Closes the stream.
export fn close(s: *stream) (error | void) = {
	return match (s.closer) {
		null => unsupported,
		c: *closer => c(s),
	};
};

// Sets the offset within the stream.
export fn seek(s: *stream, off: off, w: whence) (off | error) = {
	return match (s.seeker) {
		null => unsupported,
		sk: *seeker => sk(s, off, w),
	};
};

// Returns the current offset within the stream.
export fn tell(s: *stream) (off | error) = {
	return match (s.seeker) {
		null => unsupported,
		sk: *seeker => sk(s, 0, whence::CUR),
	};
};

// A [stream] which always reads EOF and discards any writes.
export let empty: *io::stream = null: *io::stream;

// TODO: This can be removed when globals can reference other globals
@init fn init() void = {
	static let s = io::stream { ...  };
	s.reader = &empty_read;
	s.writer = &empty_write;
	empty = &s;
};

fn empty_read(s: *stream, buf: []u8) (size | EOF | error) = EOF;

fn empty_write(s: *stream, buf: const []u8) (size | error) = len(buf);
