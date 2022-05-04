// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Noah Pederson <noah@packetlost.dev>
use errors;
use fmt;
use io;
use net::ip;
use os;
use rt;
use strings;

// Optional flags to [[accept]] to be set on the returned [[io::file]].
// See the O_CLOEXEC and O_NONBLOCK sections of open(2) for details.
export type sockflags = enum int {
	CLOEXEC = rt::SOCK_CLOEXEC,
	NONBLOCK = rt::SOCK_NONBLOCK
};

// Accepts the next connection from a socket. Blocks until a new connection is
// available. Optionally accepts CLOEXEC and NONBLOCK flags. If flags are
// supplied, the [[io::file]] returned will have the supplied flags set.
// If no flags are supplied, CLOEXEC is used by default.
export fn accept(sock: io::file, flags: sockflags...) (io::file | error) = {
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	// Default to CLOEXEC if no flags are supplied
	if (len(flags) == 0) {
		flags = [sockflags::CLOEXEC];
	};
	// Apply any supplied flags
	let f = 0i;
	for (let i = 0z; i < len(flags); i += 1) {
		f |= flags[i];
	};
	const fd = match (rt::accept4(sock, &sn, &sz, f: int)) {
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
