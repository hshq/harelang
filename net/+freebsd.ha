// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use fmt;
use io;
use net::ip;
use os;
use rt;
use strings;

// Accepts the next connection from a socket. Blocks until a new connection is
// available.
export fn accept(sock: io::file) (io::file | error) = {
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = match (rt::accept(sock, &sn, &sz)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};
	return io::fdopen(fd);
};

// Shuts down a listening socket.
export fn shutdown(sock: io::file) void = {
	rt::close(sock)!;
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
