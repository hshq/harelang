use errors;
use rt;
use strings;

// This is an opaque type which encloses an OS-level file handle resource (on
// Unix, a file descriptor, or "fd") within a stream. It can be used as an
// [[stream]] in most situations, but there are some APIs which require an
// [[file]] with some OS-level handle backing it - this type is used for such
// APIs.
export type file = struct {
	stream,
	fd: int,
};

// Opens a Unix file descriptor as a file. This is a low-level interface, to
// open files most programs will use something like [[os::open]]. This function
// is not portable.
export fn fdopen(fd: int, name: str, mode: mode) file = {
	let stream = file {
		name = name,
		closer = &fd_close_static,
		copier = &fd_copy,
		seeker = &fd_seek,
		fd = fd,
		...
	};
	if (mode & mode::READ == mode::READ) {
		stream.reader = &fd_read;
	};
	if (mode & mode::WRITE == mode::WRITE) {
		stream.writer = &fd_write;
	};
	return stream;
};

// Similar to [[fdopen]], but heap-allocates the file. Closing the stream will
// free the associated resources.
export fn fdalloc(fd: int, name: str, mode: mode) *file = {
	let file = alloc(fdopen(fd, strings::dup(name), mode));
	file.closer = &fd_close;
	return file;
};

export fn is_file(s: *stream) bool = {
	return s.reader == &fd_read
		|| s.writer == &fd_write
		|| s.closer == &fd_close
		|| s.copier == &fd_copy;
};

// Returns the file descriptor for a given [[file]] or [[stream]]. In the latter
// case, a non-file input will cause the program to abort. This function is not
// portable.
export fn fd(f: (*file | *stream)) int = match (f) {
	f: *file => f.fd,
	f: *stream => {
		assert(is_file(f));
		let f = f: *file;
		yield f.fd;
	},
};

fn fd_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *file;
	return match (rt::read(stream.fd, buf: *[*]u8, len(buf))) {
		err: rt::errno => errors::errno(err),
		n: size => switch (n) {
			0 => EOF,
			* => n,
		},
	};
};

fn fd_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *file;
	return match (rt::write(stream.fd, buf: *const [*]u8, len(buf))) {
		err: rt::errno => errors::errno(err),
		n: size => n,
	};
};

fn fd_close_static(s: *stream) void = {
	let stream = s: *file;
	rt::close(stream.fd)!;
};

fn fd_close(s: *stream) void = {
	fd_close_static(s);
	free(s);
};

def SENDFILE_MAX: size = 2147479552z;

fn fd_copy(to: *stream, from: *stream) (size | error) = {
	if (!is_file(from)) {
		return errors::unsupported;
	};

	let to = to: *file, from = from: *file;
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
	s: *stream,
	off: off,
	whence: whence,
) (off | error) = {
	let stream = s: *file;
	return match (rt::lseek(stream.fd, off: i64, whence: uint)) {
		err: rt::errno => errors::errno(err),
		n: i64 => n: off,
	};
};
