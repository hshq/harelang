use errors;
use fmt;
use io;
use net;
use os;
use rt;
use strings;
use types;

// Opens a UNIX socket connection to the path. Blocks until the
// connection is established.
export fn connect(
	addr: addr,
	options: net::connect_option...
) (*io::stream | io::error) = {
	let sockaddr = match (to_native(addr)) {
		a: rt::sockaddr => a,
		invalid => return errors::unsupported, // path too long
	};
	const sockfd = net::connect_fd(sockaddr, options...)?;
	static let buf: [rt::UNIX_PATH_MAX + 32]u8 = [0...];
	return os::fdopen(sockfd,
		fmt::bsprintf(buf, "<unix connection {}>", addr),
		io::mode::READ | io::mode::WRITE);
};

// Binds a UNIX socket listener at the given path.
export fn listen(
	addr: addr,
	options: net::listen_option...
) (*net::listener | io::error) = {
	let sockaddr = match (to_native(addr)) {
		a: rt::sockaddr => a,
		invalid => return errors::unsupported, // path too long
	};
	let sockfd = net::listen_fd(sockaddr, options...)?;
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
