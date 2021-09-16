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

// Gets the fd of the listener's socket. This function is not portable.
export fn listenerfd(l: *listener) (int | void) = {
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
	case err: rt::errno =>
		return errors::errno(err);
	case fd: int =>
		yield fd;
	};

	static let namebuf: [32]u8 = [0...];
	return io::fdopen(fd,
		fmt::bsprintf(namebuf, "<network fd {}>", fd),
		io::mode::READ | io::mode::WRITE);
};

export fn stream_shutdown(l: *listener) void = {
	assert(l.shutdown == &stream_shutdown);
	let l = l: *stream_listener;
	rt::close(l.fd)!;
	free(l);
};
