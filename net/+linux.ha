// Some common code for handling sockets on +linux
use errors;
use fmt;
use io;
use net::ip;
use os;
use rt;
use strings;

export type stream_listener = struct {
	l: listener,
	fd: int,
};

// Gets the file of a listener's socket.
export fn listenerfd(l: *listener) (io::file | void) = {
	if (l.accept == &stream_accept) {
		return (l: *stream_listener).fd;
	};
};

export fn stream_accept(l: *listener) (io::file | error) = {
	assert(l.accept == &stream_accept);
	let l = l: *stream_listener;
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = match (rt::accept(l.fd, &sn, &sz)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};
	return io::fdopen(fd);
};

export fn stream_shutdown(l: *listener) void = {
	assert(l.shutdown == &stream_shutdown);
	let l = l: *stream_listener;
	rt::close(l.fd)!;
	free(l);
};
