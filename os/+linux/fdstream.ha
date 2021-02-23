use io;
use rt;
use strings;

type fd_stream = struct {
	stream: io::stream,
	fd: int,
};

fn static_fdopen(
	fd: int, name: str, mode: io::mode, stream: *fd_stream,
) *io::stream = {
	*stream = fd_stream {
		stream = io::stream {
			name   = name,
			closer = &fd_close_static,
			copier = &fd_copy,
			seeker = &fd_seek,
			...
		},
		fd = fd,
	};
	if (mode == io::mode::RDONLY || mode == io::mode::RDWR) {
		stream.stream.reader = &fd_read;
	};
	if (mode == io::mode::WRONLY || mode == io::mode::RDWR) {
		stream.stream.writer = &fd_write;
	};
	return &stream.stream;
};

// Opens a Unix file descriptor as an io::stream.
export fn fdopen(fd: int, name: str, mode: io::mode) *io::stream = {
	let stream = alloc(fd_stream { ... });
	static_fdopen(fd, strings::dup(name), mode, stream);
	stream.stream.closer = &fd_close;
	return &stream.stream;
};

fn is_fdstream(s: *io::stream) bool = {
	return s.reader == &fd_read
		|| s.writer == &fd_write
		|| s.closer == &fd_close
		|| s.closer == &fd_close_static
		|| s.copier == &fd_copy;
};

// Returns the file descriptor for a given [io::stream]. If there is no fd
// associated with this stream, void is returned.
export fn streamfd(s: *io::stream) (int | void) = {
	if (!is_fdstream(s)) {
		return;
	};
	let stream = s: *fd_stream;
	return stream.fd;
};

fn fd_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let stream = s: *fd_stream;
	return match (rt::read(stream.fd, buf: *[*]u8, len(buf))) {
		err: rt::errno => errno_to_io(err),
		n: size => switch (n) {
			0 => io::EOF,
			* => n,
		},
	};
};

fn fd_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let stream = s: *fd_stream;
	return match (rt::write(stream.fd, buf: *const [*]u8, len(buf))) {
		err: rt::errno => errno_to_io(err),
		n: size => n,
	};
};

fn fd_close(s: *io::stream) void = {
	let stream = s: *fd_stream;
	rt::close(stream.fd);
	free(s.name);
	free(stream);
};

fn fd_close_static(s: *io::stream) void = {
	let stream = s: *fd_stream;
	rt::close(stream.fd);
	free(stream);
};

def SENDFILE_MAX: size = 2147479552z;

fn fd_copy(_to: *io::stream, _from: *io::stream) (size | io::error) = {
	if (!is_fdstream(_from)) {
		return io::unsupported;
	};

	let to = _to: *fd_stream, from = _from: *fd_stream;
	let sum = 0z;
	for (true) {
		let n = match (rt::sendfile(to.fd, from.fd,
				null, SENDFILE_MAX)) {
			err: rt::errno => switch (err) {
				rt::EINVAL => {
					if (sum == 0) {
						return io::unsupported;
					};
					return errno_to_io(err);
				},
				* => return errno_to_io(err),
			},
			n: size => switch (n) {
				0 => return sum,
				* => n,
			},
		};
		sum += n;
	};
	return sum;
};

fn fd_seek(
	s: *io::stream,
	off: io::off,
	whence: io::whence,
) (io::off | io::error) = {
	let stream = s: *fd_stream;
	return match (rt::lseek(stream.fd, off: i64, whence: uint)) {
		err: rt::errno => errno_to_io(err),
		n: i64 => n: io::off,
	};
};
