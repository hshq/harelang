use io;
use net::ip;
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

fn mksockfd(addr: ip::addr) (int | io::error) = {
	const af = match (addr) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	};
	return wrap(rt::socket(af, rt::SOCK_STREAM, 0))?;
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
