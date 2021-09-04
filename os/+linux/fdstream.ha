use errors;
use io;
use rt;
use strings;

export type fdstream = struct {
	io::stream,
	fd: int,
};

// Opens a Unix file descriptor as an io::stream.
export fn fdopen(fd: int, name: str, mode: io::mode) fdstream = {
	let stream = fdstream {
		name = name,
		closer = &fd_close,
		copier = &fd_copy,
		seeker = &fd_seek,
		fd = fd,
		...
	};
	if (mode & io::mode::READ == io::mode::READ) {
		stream.reader = &fd_read;
	};
	if (mode & io::mode::WRITE == io::mode::WRITE) {
		stream.writer = &fd_write;
	};
	return stream;
};

fn is_fdstream(s: *io::stream) bool = {
	return s.reader == &fd_read
		|| s.writer == &fd_write
		|| s.closer == &fd_close
		|| s.copier == &fd_copy;
};

// Returns the file descriptor for a given [[io::stream]]. If there is no fd
// associated with this stream, void is returned.
//
// If 'unwrap' is true, the stream will be unwrapped until an fdstream is found.
// Note that many stream wrappers (such as [[io::tee]]) provide important
// functionality, and using the file descriptor directly will circumvent that
// functionality. Use with caution.
export fn streamfd(s: *io::stream, unwrap: bool) (int | void) = {
	for (unwrap && !is_fdstream(s)) {
		s = match (io::source(s)) {
			errors::unsupported => return,
			s: *io::stream  => s,
		};
	};
	if (!is_fdstream(s)) {
		return;
	};
	let stream = s: *fdstream;
	return stream.fd;
};

fn fd_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let stream = s: *fdstream;
	return match (rt::read(stream.fd, buf: *[*]u8, len(buf))) {
		err: rt::errno => errors::errno(err),
		n: size => switch (n) {
			0 => io::EOF,
			* => n,
		},
	};
};

fn fd_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let stream = s: *fdstream;
	return match (rt::write(stream.fd, buf: *const [*]u8, len(buf))) {
		err: rt::errno => errors::errno(err),
		n: size => n,
	};
};

fn fd_close(s: *io::stream) void = {
	let stream = s: *fdstream;
	rt::close(stream.fd)!;
};

def SENDFILE_MAX: size = 2147479552z;

fn fd_copy(to: *io::stream, from: *io::stream) (size | io::error) = {
	if (!is_fdstream(from)) {
		return errors::unsupported;
	};

	let to = to: *fdstream, from = from: *fdstream;
	let sum = 0z;
	for (true) {
		let n = match (rt::sendfile(to.fd, from.fd,
				null, SENDFILE_MAX)) {
			err: rt::errno => switch (err) {
				rt::EINVAL => {
					if (sum == 0) {
						return errors::unsupported;
					};
					return errors::errno(err);
				},
				* => return errors::errno(err),
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
	let stream = s: *fdstream;
	return match (rt::lseek(stream.fd, off: i64, whence: uint)) {
		err: rt::errno => errors::errno(err),
		n: i64 => n: io::off,
	};
};
