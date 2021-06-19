use errors;
use fmt;
use io;
use net::ip;
use os;
use rt;
use strings;

export fn connect_fd(
	addr: rt::sockaddr,
	options: connect_option...
) (int | io::error) = {
	const sockfd = mksockfd(addr)?;
	for (let i = 0z; i < len(options); i += 1) {
		// The only option is keepalive right now
		setsockopt(sockfd, rt::SO_KEEPALIVE, true)?;
	};
	wrap(rt::connect(sockfd, &addr, sockasz(addr)))?;
	return sockfd;
};

export type stream_listener = struct {
	l: listener,
	fd: int,
};

// Gets the fd of the listener's socket. This function is not portable.
export fn listenerfd(l: *listener) (int | void) = {
	if (l.accept == &stream_accept) {
		return (l: *stream_listener).fd;
	};
};

export fn listen_fd(
	addr: rt::sockaddr,
	options: listen_option...
) (int | io::error) = {
	const sockfd = mksockfd(addr)?;

	let bk: u32 = 10;
	let portout: nullable *u16 = null;

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
			reuseaddr => setsockopt(sockfd, rt::SO_REUSEADDR, true)?,
			reuseport => setsockopt(sockfd, rt::SO_REUSEPORT, true)?,
			keepalive => setsockopt(sockfd, rt::SO_KEEPALIVE, true)?,
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

export fn stream_accept(l: *listener) (*io::stream | io::error) = {
	assert(l.accept == &stream_accept);
	let l = l: *stream_listener;
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = wrap(rt::accept(l.fd, &sn, &sz))?;

	static let namebuf: [32]u8 = [0...];
	return os::fdopen(fd, fmt::bsprintf(namebuf, "<net connection {}>", fd),
		io::mode::READ | io::mode::WRITE);
};

export fn stream_shutdown(l: *listener) void = {
	assert(l.shutdown == &stream_shutdown);
	let l = l: *stream_listener;
	rt::close(l.fd)!;
	free(l);
};

fn setsockopt(sockfd: int, option: int, value: bool) (void | rt::errno) = {
	let val: int = if (value) 1 else 0;
	rt::setsockopt(sockfd, rt::SOL_SOCKET, option,
		&val: *void, size(int): u32)?;
	return;
};

fn setfcntl(sockfd: int, flag: int) (void | rt::errno) = {
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)?;
	rt::fcntl(sockfd, rt::F_SETFL, flags | flag)!;
	return;
};

fn wrap(ie: (int | rt::errno)) (int | io::error) = {
	match (ie) {
		i: int => i,
		err: rt::errno => errors::errno(err),
	};
};

fn sockasz(addr: rt::sockaddr) u32 = {
	return switch (addr.in.sin_family) {
		rt::AF_INET => size(rt::sockaddr_in): u32,
		rt::AF_INET6 => size(rt::sockaddr_in6): u32,
		rt::AF_UNIX => size(rt::sockaddr_un): u32,
		* => size(rt::sockaddr): u32,
	};
};

export fn mksockfd(addr: rt::sockaddr) (int | io::error) = {
	return wrap(rt::socket(addr.in.sin_family: int, rt::SOCK_STREAM, 0))?;
};
