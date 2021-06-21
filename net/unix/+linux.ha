use errors;
use fmt;
use io;
use net;
use os;
use rt;
use strings;
use types;

// Opens a UNIX socket connection to the path. Blocks until the connection is
// established.
export fn connect(addr: addr) (*io::stream | net::error) = {
	let sockaddr = match (to_native(addr)) {
		a: rt::sockaddr => a,
		invalid => return errors::unsupported, // path too long
	};
	const sockfd = match (rt::socket(rt::AF_UNIX: int, rt::SOCK_STREAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	const sz = size(rt::sockaddr): u32;
	match (rt::connect(sockfd, &sockaddr, sz)) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};
	static let buf: [rt::UNIX_PATH_MAX + 32]u8 = [0...];
	return os::fdopen(sockfd,
		fmt::bsprintf(buf, "<unix connection {}>", addr),
		io::mode::READ | io::mode::WRITE);
};

// Binds a UNIX socket listener to the given path.
export fn listen(
	addr: addr,
	options: listen_option...
) (*net::listener | net::error) = {
	let sockaddr = match (to_native(addr)) {
		a: rt::sockaddr => a,
		invalid => return errors::unsupported, // path too long
	};
	const sockfd = match (rt::socket(rt::AF_UNIX: int, rt::SOCK_STREAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	let bk: u32 = 10;
	for (let i = 0z; i < len(options); i += 1) {
		// Only option is backlog right now
		bk = options[i];
	};

	match (rt::bind(sockfd, &sockaddr, size(rt::sockaddr): u32)) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};
	match ((rt::listen(sockfd, bk))) {
		err: rt::errno => return errors::errno(err),
		int => void,
	};

	return alloc(net::stream_listener {
		l = net::listener {
			accept = &net::stream_accept,
			shutdown = &net::stream_shutdown,
		},
		fd = sockfd,
	}): *net::listener;
};

// Converts a UNIX socket address to a native sockaddr.
fn to_native(addr: addr) (rt::sockaddr | invalid) = {
	// sun_path should be null-terminated and fit into rt::UNIX_PATH_MAX
	if (len(addr) > rt::UNIX_PATH_MAX - 1) {
		return invalid;
	};
	let ret = rt::sockaddr {
		un = rt::sockaddr_un {
			sun_family = rt::AF_UNIX,
			...
		}
	};
	match ((&addr: *types::string).data) {
		null => void,
		data: *[*]u8 => rt::memcpy(&ret.un.sun_path, data, len(addr)),
	};
	ret.un.sun_path[len(addr)] = 0;
	return ret;
};
