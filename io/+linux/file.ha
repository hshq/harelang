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

// Duplicates a [[file]] onto the heap, as if it were opened with [[fdalloc]].
export fn filedup(f: *file) *file = {
	let new = alloc(*f);
	new.closer = &fd_close;
	return new;
};

// Similar to [[fdopen]], but heap-allocates the file. Closing the stream will
// free the associated resources.
export fn fdalloc(fd: int, name: str, mode: mode) *file =
	filedup(&fdopen(fd, strings::dup(name), mode));

// Returns true if a [[stream]] is a file.
export fn is_file(s: *stream) bool = {
	return s.reader == &fd_read
		|| s.writer == &fd_write
		|| s.closer == &fd_close
		|| s.copier == &fd_copy;
};

// Returns the file descriptor for a given [[file]]. This function is not
// portable.
export fn fd(f: *file) int = f.fd;

// Returns the file descriptor for a given [[stream]], returning void if the
// stream is not backed by a file. This function is not portable.
export fn unwrapfd(s: *stream) (int | void) = {
	for (!is_file(s)) {
		s = match (io::source(s)) {
		case errors::unsupported =>
			return;
		case s: *io::stream =>
			yield s;
		};
	};
	return fd(s: *file);
};

fn fd_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *file;
	match (rt::read(stream.fd, buf: *[*]u8, len(buf))) {
	case err: rt::errno =>
		return errors::errno(err);
	case n: size =>
		switch (n) {
		case 0 =>
			return EOF;
		case =>
			return n;
		};
	};
};

fn fd_write(s: *stream, buf: const []u8) (size | error) = {
	let stream = s: *file;
	match (rt::write(stream.fd, buf: *const [*]u8, len(buf))) {
	case err: rt::errno =>
		return errors::errno(err);
	case n: size =>
		return n;
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
			case err: rt::errno =>
				switch (err) {
				case rt::EINVAL =>
					if (sum == 0) {
						return errors::unsupported;
					};
					return errors::errno(err);
				case =>
					return errors::errno(err);
				};
			case n: size =>
				yield switch (n) {
				case 0 =>
					break;
				case =>
					yield n;
				};
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
	match (rt::lseek(stream.fd, off: i64, whence: uint)) {
	case err: rt::errno =>
		return errors::errno(err);
	case n: i64 =>
		return n: off;
	};
};
