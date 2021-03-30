use io;
use rt;
use os;
use strings;
use net::ip;

// Enables keep-alive for a socket.
export type keepalive = void;

// Enables port re-use for a TCP listener.
export type reuseport = void;

// Enables address re-use for a TCP listener.
export type reuseaddr = void;

// Configures the backlog size for a listener. If not specified, a sensible
// default (10) is used.
export type backlog = u32;

// To have the system select an arbitrary unused TCP port for [listen], set port
// to zero. To retrieve the assigned port, provide this as one of the options
// and the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// A listener binds a socket on the system and listens for incoming traffic for
// some specific protocol.
export type listener = int;

// Options for [listen].
export type listen_option = (
	keepalive |
	reuseport |
	reuseaddr |
	backlog |
	portassignment);

// Options for [connect].
export type connect_option = keepalive;

fn setsockopt(sockfd: int, option: int, value: bool) (void | rt::errno) = {
	let val: int = if (value) 1 else 0;
	rt::setsockopt(sockfd, rt::SOL_SOCKET, option,
		&val: *void, size(int): u32)?;
};

fn setfcntl(sockfd: int, flag: int) (void | rt::errno) = {
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)?;
	rt::fcntl(sockfd, rt::F_SETFL, flags | flag); // ? always detects io::error
	return;
};

fn wrap(ie: (int | rt::errno)) (int | io::error) = {
	match (ie) {
		i: int => i,
		er: rt::errno => errno_to_io(er)
	};
};

fn mksockfd(addr: ip::addr) (int | io::error) = {
	const af = match (addr) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	};
	return wrap(rt::socket(af, rt::SOCK_STREAM, 0))?;
};

// Binds a TCP listener to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (listener | io::error) = {
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
	return sockfd;
};


// Returns the remote address for a given connection, or void if none is
// available.
export fn peeraddr(stream: *io::stream) ((ip::addr, u16) | void) = {
	let fd = match (os::streamfd(stream)) {
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

// Accepts the next connection from a listener, returning an [io::stream].
// Blocks until a new connection is available.
export fn accept(l: listener) (*io::stream | io::error) = {
	let sn = rt::sockaddr {...};
	const sz = size(rt::sockaddr): u32;
	const fd = wrap(rt::accept(l, &sn, &sz))?;
	const addr = ip::from_native(sn).0;
	return os::fdopen(fd, ip::string(addr),
		io::mode::READ | io::mode::WRITE);
};

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

fn io_errstr(data: *void) str = {
	const errno = data: uintptr: int: rt::errno;
	return rt::errstr(errno);
};

fn errno_to_io(err: rt::errno) io::error = {
	let err = io::os_error {
		string = &io_errstr,
		data = err: uintptr: *void,
	};
	return err: io::error;
};
