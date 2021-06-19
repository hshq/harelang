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
	options: net::connect_option...
) (*io::stream | io::error) = {
	const sockaddr = ip::to_native(addr, port);
	const sockfd = net::connect_fd(sockaddr, options...)?;
	return os::fdopen(sockfd, ip::string(addr),
		io::mode::READ | io::mode::WRITE);
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: net::listen_option...
) (*net::listener | io::error) = {
	let sockaddr = ip::to_native(addr, port);
	let sockfd = net::listen_fd(sockaddr, options...)?;
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
