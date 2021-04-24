use errors;
use io;
use net::ip;
use net::unix;
use os;
use rt;
use strings;

fn connect_fd(
	addr: rt::sockaddr,
	options: connect_option...
) (int | io::error) = {
	const sockfd = mksockfd(addr)?;
	for (let i = 0z; i < len(options); i += 1) {
		// The only option is keepalive right now
		setsockopt(sockfd, rt::SO_KEEPALIVE, true);
	};
	wrap(rt::connect(sockfd, &addr, sockasz(addr)))?;
	return sockfd;
};

// Opens a TCP connection to the given host and port. Blocks until the
// connection is established.
export fn connect(
	addr: ip::addr,
	port: u16,
	options: connect_option...
) (*io::stream | io::error) = {
	const sockaddr = ip::to_native(addr, port);
	const sockfd = connect_fd(sockaddr, options...)?;
	return os::fdopen(sockfd, string(addr),
		io::mode::READ | io::mode::WRITE);
};

// Opens a UNIX socket connection to the path. Blocks until the
// connection is established.
export fn connect_unix(
	addr: unix::addr,
	options: connect_option...
) (*io::stream | io::error) = {
	let sockaddr = match (unix::to_native(addr)) {
		a: rt::sockaddr => a,
		_: unix::invalid => return errors::unsupported, // path too long
	};
	const sockfd = connect_fd(sockaddr, options...)?;
	return os::fdopen(sockfd, string(addr),
		io::mode::READ | io::mode::WRITE);
};

type stream_listener = struct {
	l: listener,
	fd: int,
};

fn listen_fd(
	addr: rt::sockaddr,
	options: listen_option...
) (int | io::error) = {
	const sockfd = mksockfd(addr)?;

	let bk: u32 = 10;
	let portout: nullable *u16 = null;

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
			_: reuseaddr => setsockopt(sockfd, rt::SO_REUSEADDR, true),
			_: reuseport => setsockopt(sockfd, rt::SO_REUSEPORT, true),
			_: keepalive => setsockopt(sockfd, rt::SO_KEEPALIVE, true),
			b: backlog => bk = b,
			p: portassignment => portout = p,
		};
	};
	setfcntl(sockfd, rt::O_CLOEXEC)!;

	wrap(rt::bind(sockfd, &addr, sockasz(addr)))?;
	wrap(rt::listen(sockfd, bk))?;

	match (portout) {
		p: *u16 => {
			if (addr.in.sin_family != rt::AF_INET &&
				addr.in.sin_family != rt::AF_INET6) {
				return errors::unsupported;
			};
			let sn = rt::sockaddr {...};
			let al = sockasz(addr);
			wrap(rt::getsockname(sockfd, &sn, &al))?;
			const addr = ip::from_native(sn);
			*p = addr.1;
		},
		null => void,
	};

	return sockfd;
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (*listener | io::error) = {
	let sockaddr = ip::to_native(addr, port);
	let sockfd = listen_fd(sockaddr, options...)?;
	return alloc(stream_listener {
		l = listener {
			accept = &stream_accept,
			shutdown = &stream_shutdown,
		},
		fd = sockfd,
	}): *listener;
};

fn stream_accept(l: *listener) (*io::stream | io::error) = {
	assert(l.accept == &stream_accept);
	let l = l: *stream_listener;
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = wrap(rt::accept(l.fd, &sn, &sz))?;
	const addr = from_native(sn);
	return os::fdopen(fd, string(addr),
		io::mode::READ | io::mode::WRITE);
};

fn stream_shutdown(l: *listener) void = {
	assert(l.shutdown == &stream_shutdown);
	let l = l: *stream_listener;
	rt::close(l.fd)!;
	free(l);
};

// Binds a UNIX socket listener at the given path.
export fn listen_unix(
	addr: unix::addr,
	options: listen_option...
) (*listener | io::error) = {
	let sockaddr = match (unix::to_native(addr)) {
		a: rt::sockaddr => a,
		_: unix::invalid => return errors::unsupported, // path too long
	};
	let sockfd = listen_fd(sockaddr, options...)?;
	return alloc(stream_listener {
		l = listener {
			accept = &stream_accept,
			shutdown = &stream_shutdown,
		},
		fd = sockfd,
	}): *listener;
};
