use errors;
use io;
use net::ip;
use net;
use os;
use rt;

// Opens a TCP connection to the given host and port. Blocks until the
// connection is established.
export fn connect(
	addr: ip::addr,
	port: u16,
	options: connect_option...
) (io::file | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	const sockfd = match (rt::socket(family, rt::SOCK_STREAM, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	for (let i = 0z; i < len(options); i += 1) {
		// The only option is keepalive right now
		setsockopt(sockfd, rt::SO_KEEPALIVE, true)?;
	};
	const sz = ip::native_addrlen(addr);
	match (rt::connect(sockfd, &sockaddr, sz)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
	return io::fdopen(sockfd);
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (*net::listener | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	const sockfd = match (rt::socket(family, rt::SOCK_STREAM, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

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
		case let p: portassignment => void;
		};
	};

	const sz = ip::native_addrlen(addr);
	match (rt::bind(sockfd, &sockaddr, sz)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
	match (rt::listen(sockfd, bk)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
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
		case int => void;
		};
		const addr = ip::from_native(sn);
		*portout = addr.1;
	};

	return alloc(net::stream_listener {
		l = net::listener {
			accept = &net::stream_accept,
			shutdown = &net::stream_shutdown,
		},
		fd = sockfd,
	}): *net::listener;
};

// Returns the remote address for a given connection, or void if none is
// available.
export fn peeraddr(peer: io::file) ((ip::addr, u16) | void) = {
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
			&val: *void, size(int): u32)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};
