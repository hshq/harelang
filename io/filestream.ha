use errors;

export type filestream = struct {
	stream,
	fd: file,
};

// Creates a [[filestream]] for a [[file]], for compatibility with
// [[stream]]-oriented APIs. Note that this is generally not thought to be
// necessary for most programs; most APIs should accept [[handle]] instead of
// [[stream]] in order to support both file-oriented and stream-oriented I/O.
export fn fdstream(fd: file) filestream = filestream {
	fd = fd,
	reader = &fdstream_read,
	writer = &fdstream_write,
	closer = &fdstream_close,
	seeker = &fdstream_seek,
	copier = &fdstream_copy,
};

fn fdstream_read(st: *stream, buf: []u8) (size | EOF | error) = {
	const st = st: *filestream;
	assert(st.reader == &fdstream_read);
	return fd_read(st.fd, buf);
};

fn fdstream_write(st: *stream, buf: const []u8) (size | error) = {
	const st = st: *filestream;
	assert(st.writer == &fdstream_write);
	return fd_write(st.fd, buf);
};

fn fdstream_close(st: *stream) void = {
	const st = st: *filestream;
	assert(st.closer == &fdstream_close);
	fd_close(st.fd);
};

fn fdstream_seek(st: *stream, off: off, whence: whence) (off | error) = {
	const st = st: *filestream;
	assert(st.seeker == &fdstream_seek);
	return fd_seek(st.fd, off, whence);
};

fn fdstream_copy(to: *stream, from: *stream) (size | error) = {
	const to = to: *filestream;
	const from = from: *filestream;
	assert(to.copier == &fdstream_copy);
	if (from.copier != &fdstream_copy) {
		return errors::unsupported;
	};
	return fd_copy(to.fd, from.fd);
};
