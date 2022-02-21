// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

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

fn msg_to_native(msg: *msghdr) *rt::msghdr = {
	let native = &msg.native;
	if (len(msg.vectors) != 0) {
		native.msg_iov = msg.vectors: *[*]rt::iovec;
		native.msg_iovlen = len(msg.vectors);
	};
	if (len(msg.control) != 0) {
		native.msg_control = msg.control: *[*]u8;
		native.msg_controllen = len(msg.control);
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
