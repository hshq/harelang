use io;
use net::ip;
use os;
use rt;
use strings;

// Opens a TCP connection to the given host and port. Blocks until the
// connection is established.
export fn connect(
	addr: ip::addr,
	port: u16,
	options: connect_option...
) (*io::stream | io::error) = {
	const sockfd = mksockfd(addr)?;
	for (let i = 0z; i < len(options); i += 1) {
		// The only option is keepalive right now
		setsockopt(sockfd, rt::SO_KEEPALIVE, true);
	};

	const sockaddr = ip::to_native(addr, port);
	const asize = match (addr) {
		v4: ip::addr4 => size(rt::sockaddr_in): u32,
		v6: ip::addr6 => size(rt::sockaddr_in6): u32,
	};
	wrap(rt::connect(sockfd, &sockaddr, asize))?;

	return os::fdopen(sockfd, ip::string(addr),
		io::mode::READ | io::mode::WRITE);
};

export fn connect_unix(
	path: str,
	options: connect_option...
) (*io::stream | io::error) = {
	abort(); // TODO
};

type tcp_listener = struct {
	l: listener,
	fd: int,
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (*listener | io::error) = {
	const sockfd = mksockfd(addr)?;

	let bk: u32 = 10;
	let portout: nullable *u16 = null;

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
			reuseaddr => setsockopt(sockfd, rt::SO_REUSEADDR, true),
			reuseport => setsockopt(sockfd, rt::SO_REUSEPORT, true),
			keepalive => setsockopt(sockfd, rt::SO_KEEPALIVE, true),
			b: backlog => bk = b,
			p: portassignment => portout = p,
		};
	};
	setfcntl(sockfd, rt::O_CLOEXEC);

	let sockaddr = ip::to_native(addr, port);
	const asize = match (addr) {
		v4: ip::addr4 => size(rt::sockaddr_in): u32,
		v6: ip::addr6 => size(rt::sockaddr_in6): u32,
	};
	wrap(rt::bind(sockfd, &sockaddr, asize))?;
	wrap(rt::listen(sockfd, bk))?;

	match (portout) {
		p: *u16 => {
			let sn = rt::sockaddr {...};
			let al = asize;
			wrap(rt::getsockname(sockfd, &sn, &al))?;
			const addr = ip::from_native(sn);
			*p = addr.1;
		},
		null => void,
	};
	return alloc(tcp_listener {
		l = listener {
			accept = &tcp_accept,
			shutdown = &tcp_shutdown,
		},
		fd = sockfd,
	}): *listener;
};

fn tcp_accept(l: *listener) (*io::stream | io::error) = {
	assert(l.accept == &tcp_accept);
	let l = l: *tcp_listener;
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = wrap(rt::accept(l.fd, &sn, &sz))?;
	const addr = ip::from_native(sn).0;
	return os::fdopen(fd, ip::string(addr),
		io::mode::READ | io::mode::WRITE);
};

fn tcp_shutdown(l: *listener) void = {
	assert(l.shutdown == &tcp_shutdown);
	let l = l: *tcp_listener;
	rt::close(l.fd);
	free(l);
};

// Binds a Unix socket at the given path.
export fn listen_unix(
	path: str,
	options: listen_option...
) (*listener | io::error) = {
	abort(); // TODO
};
