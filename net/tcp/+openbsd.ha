// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use net::ip;
use os;
use rt;

// Opens a TCP connection to the given host and port. Blocks until the
// connection is established.
export fn connect(
	addr: ip::addr,
	port: u16,
	options: connect_option...
) (net::socket | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	let flags = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let fl: net::sockflag =>
			flags |= fl;
		case => void;
		};
	};
	flags ^= rt::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (rt::socket(family, rt::SOCK_STREAM | flags, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case keepalive =>
			setsockopt(sockfd, rt::SO_KEEPALIVE, true)?;
		case => void;
		};
	};
	const sz = ip::native_addrlen(addr);
	match (rt::connect(sockfd, &sockaddr, sz)) {
	case let err: rt::errno =>
		if (err != rt::EINPROGRESS) {
			return errors::errno(err);
		};
	case void => void;
	};
	return io::fdopen(sockfd);
};

// Binds a TCP socket to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (net::socket | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	let flags = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let fl: net::sockflag =>
			flags |= fl;
		case => void;
		};
	};
	flags ^= rt::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (rt::socket(family, rt::SOCK_STREAM | flags, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	let bk: u32 = 10;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case reuseaddr =>
			setsockopt(sockfd, rt::SO_REUSEADDR, true)?;
		case reuseport =>
			setsockopt(sockfd, rt::SO_REUSEPORT, true)?;
		case keepalive =>
			setsockopt(sockfd, rt::SO_KEEPALIVE, true)?;
		case let b: backlog =>
			bk = b;
		case => void;
		};
	};

	const sz = ip::native_addrlen(addr);
	match (rt::bind(sockfd, &sockaddr, sz)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
	match (rt::listen(sockfd, bk)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};

	for (let i = 0z; i < len(options); i += 1) {
		let portout = match (options[i]) {
		case let p: portassignment =>
			yield p;
		case =>
			continue;
		};
		let sn = rt::sockaddr {...};
		let al = size(rt::sockaddr): u32;
		match (rt::getsockname(sockfd, &sn, &al)) {
		case let err: rt::errno =>
			return errors::errno(err);
		case void => void;
		};
		const addr = ip::from_native(sn);
		*portout = addr.1;
	};

	return sockfd;
};

// Returns the remote address for a given connection, or void if none is
// available.
export fn peeraddr(peer: net::socket) ((ip::addr, u16) | void) = {
	let sn = rt::sockaddr {...};
	let sz = size(rt::sockaddr): u32;
	if (rt::getpeername(peer, &sn, &sz) is rt::errno) {
		return;
	};
	return ip::from_native(sn);
};

fn setsockopt(
	sockfd: int,
	option: int,
	value: bool,
) (void | net::error) = {
	let val: int = if (value) 1 else 0;
	match (rt::setsockopt(sockfd, rt::SOL_SOCKET, option,
			&val: *opaque, size(int): u32)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};
