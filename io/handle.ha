// TODO: Examine the ABI constraints of [[handle]]. Would it be better to make
// stream an integer representing an internal handle into a stream table? This
// would reduce performance for streams somewhat via the indirect lookup, but
// improve the ABI performance for files.

// An I/O handle is a resource which I/O operations may be performed on. It is
// either a [[stream]], which is a userspace I/O abstraction, or a [[file]],
// which is backed by a resource on the host OS, such as a file descriptor.
export type handle = (file | *stream);

// Reads up to len(buf) bytes from a [[handle]] into the given buffer, returning
// the number of bytes read.
export fn read(h: handle, buf: []u8) (size | EOF | error) = {
	match (h) {
	case fd: file =>
		return fd_read(fd, buf);
	case st: *stream =>
		return st_read(st, buf);
	};
};

// Writes up to len(buf) bytes to the [[handle]] from the given buffer,
// returning the number of bytes written.
export fn write(h: handle, buf: const []u8) (size | error) = {
	match (h) {
	case fd: file =>
		return fd_write(fd, buf);
	case st: *stream =>
		return st_write(st, buf);
	};
};

// Closes a [[handle]]. No further operations against this handle are permitted
// after calling this function.
export fn close(h: handle) void = {
	match (h) {
	case fd: file =>
		fd_close(fd);
	case st: *stream =>
		st_close(st);
	};
};

// Sets the offset within a [[handle]].
export fn seek(h: handle, off: off, w: whence) (off | error) = {
	match (h) {
	case fd: file =>
		return fd_seek(fd, off, w);
	case st: *stream =>
		return st_seek(st, off, w);
	};
};

// Returns the current offset within a [[handle]].
export fn tell(h: handle) (off | error) = {
	return seek(h, 0, whence::CUR);
};