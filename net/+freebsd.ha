// Some common code for handling sockets on +freebsd
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

fn msg_to_native(msg: *msghdr) *rt::msghdr = {
	let native = &msg.native;
	if (len(msg.vectors) != 0) {
		native.msg_iov = msg.vectors: *[*]rt::iovec;
		native.msg_iovlen = len(msg.vectors): int;
	};
	if (len(msg.control) != 0) {
		native.msg_control = msg.control: *[*]u8;
		native.msg_controllen = len(msg.control): rt::socklen_t;
	};
	return native;
};

// Sends a message to a socket. See [[newmsg]] for details.
export fn sendmsg(sock: io::file, msg: *msghdr) (size | error) = {
	// TODO: Flags
	match (rt::sendmsg(sock, msg_to_native(msg), 0)) {
	case let n: int =>
		return n: size;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Receives a message from a socket. See [[newmsg]] for details.
export fn recvmsg(sock: io::file, msg: *msghdr) (size | error) = {
	// TODO: Flags
	match (rt::recvmsg(sock, msg_to_native(msg), 0)) {
	case let n: int =>
		return n: size;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
