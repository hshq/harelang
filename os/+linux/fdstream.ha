use io;
use rt;

type fd_stream = struct {
	stream: io::stream,
	fd: int,
};

// Opens a Unix file descriptor as an io::stream. If 'name' is an empty string,
// a name will be generated based on the file descriptor number.
export fn fdopen(fd: int, name: str) *io::stream = {
	// TODO: strings::dup the name, and if empty, generate a name from the
	// file descriptor number.
	//
	// Also TODO: consider making the caller specify what subset of
	// operations should be supported
	let stream = alloc(*fd_stream, struct {
		stream: io::stream = struct {
			name: str = name,
			reader: nullable *io::reader = &fd_read,
			writer: nullable *io::writer = &fd_write,
			closer: nullable *io::closer = &fd_close,
		},
		fd: int = fd,
	});
	return &stream.stream;
};

fn fd_read(s: *io::stream, buf: []u8) (size | io::error) = {
	let stream = s: *fd_stream;
	let r = rt::read(stream.fd, (&buf: *types::slice).data: *[*]u8, len(buf));
	return match (rt::wrap_return(r)) {
		err: rt::errno => errno_to_io(err),
		n: size => {
			switch (n) {
				0z => io::closed: io::error,
				*  => n,
			};
		},
	};
};

fn fd_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let stream = s: *fd_stream;
	let r = rt::write(stream.fd,
		(&buf: *types::slice).data: *const [*]u8, len(buf));
	return match (rt::wrap_return(r)) {
		err: rt::errno => errno_to_io(err),
		n: size => n,
	};
};

fn fd_close(s: *io::stream) void = {
	let stream = s: *fd_stream;
	rt::close(stream.fd);
	free(stream);
};

fn static_fdopen(fd: int, name: str, stream: *fd_stream) void = {
	stream.stream = struct {
		name: str = name,
		reader: nullable *io::reader = &fd_read,
		writer: nullable *io::writer = &fd_write,
		closer: nullable *io::closer = &fd_close,
	};
	stream.fd = fd;
};

// Returns the file descriptor for a given [io::stream]. If there is no fd
// associated with this stream, void is returned.
export fn streamfd(s: *io::stream) (int | void) = {
	if (s.reader != &fd_read) {
		return void;
	};
	let stream = s: *fd_stream;
	return stream.fd;
};
