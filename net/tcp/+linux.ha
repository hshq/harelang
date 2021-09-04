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
) (*io::stream | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const sockfd = match (rt::socket(match (addr) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	}, rt::SOCK_STREAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	for (let i = 0z; i < len(options); i += 1) {
		// The only option is keepalive right now
		setsockopt(sockfd, rt::SO_KEEPALIVE, true)?;
	};
	const sz = size(rt::sockaddr): u32;
	match (rt::connect(sockfd, &sockaddr, sz)) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};
	return alloc(os::fdopen(sockfd, ip::string(addr),
		io::mode::READ | io::mode::WRITE));
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (*net::listener | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const sockfd = match (rt::socket(match (addr) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	}, rt::SOCK_STREAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	let bk: u32 = 10;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
			reuseaddr => setsockopt(sockfd, rt::SO_REUSEADDR, true)?,
			reuseport => setsockopt(sockfd, rt::SO_REUSEPORT, true)?,
			keepalive => setsockopt(sockfd, rt::SO_KEEPALIVE, true)?,
			b: backlog => bk = b,
			p: portassignment => void,
		};
	};

	match (rt::bind(sockfd, &sockaddr, size(rt::sockaddr): u32)) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};
	match ((rt::listen(sockfd, bk))) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};

	for (let i = 0z; i < len(options); i += 1) {
		let portout = match (options[i]) {
			p: portassignment => p,
			* => continue,
		};
		let sn = rt::sockaddr {...};
		let al = size(rt::sockaddr): u32;
		match (rt::getsockname(sockfd, &sn, &al)) {
			err: rt::errno => return errors::errno(err),
			int => void,
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
export fn peeraddr(stream: *io::stream) ((ip::addr, u16) | void) = {
	let fd = match (os::streamfd(stream, true)) {
		fd: int => fd,
		void => return,
	};
	let sn = rt::sockaddr {...};
	let sz = size(rt::sockaddr): u32;
	if (rt::getpeername(fd, &sn, &sz) is rt::errno) {
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
	return match (rt::setsockopt(sockfd, rt::SOL_SOCKET, option,
			&val: *void, size(int): u32)) {
		err: rt::errno => errors::errno(err),
		int => void,
	};
};
