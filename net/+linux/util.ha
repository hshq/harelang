use io;
use fmt;
use net::ip;
use net::unix;
use os;
use rt;

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

fn mksockfd(addr: rt::sockaddr) (int | io::error) = {
	return wrap(rt::socket(addr.in.sin_family: int, rt::SOCK_STREAM, 0))?;
};

fn sockasz(addr: rt::sockaddr) u32 = {
	return switch (addr.in.sin_family) {
		rt::AF_INET => size(rt::sockaddr_in): u32,
		rt::AF_INET6 => size(rt::sockaddr_in6): u32,
		rt::AF_UNIX => size(rt::sockaddr_un): u32,
		* => size(rt::sockaddr): u32,
	};
};

fn string(addr: (ip::addr | unix::addr)) str = {
	return match (addr) {
		ip: ip::addr => ip::string(ip),
		un: unix::addr => un,
	};
};

fn from_native(addr: rt::sockaddr) (ip::addr | unix::addr) = {
	return switch (addr.in.sin_family) {
		rt::AF_INET => ip::from_native(addr).0,
		rt::AF_INET6 => ip::from_native(addr).0,
		rt::AF_UNIX => unix::from_native(addr),
		* => abort("Wrong address family"),
	};
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

// Gets the fd of the listener's socket.
export fn listenerfd(l: *listener) (int | void) = {
	if (l.accept == &stream_accept) {
		return (l: *stream_listener).fd;
	};
};
