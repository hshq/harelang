use errors;
use io;
use net::ip;
use net;
use os;
use rt;

// Creates a UDP socket and sets the default destination to the given address.
export fn connect(
	dest: ip::addr,
	port: u16,
) (io::file | net::error) = {
	const sockfd = match (rt::socket(match (dest) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	}, rt::SOCK_DGRAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};

	const sockaddr = ip::to_native(dest, port);
	const sz = size(rt::sockaddr): u32;
	return match (rt::connect(sockfd, &sockaddr, sz)) {
		int => io::fdopen(sockfd,
			"<udp connection>",
			io::mode::READ | io::mode::WRITE),
		err: rt::errno => errors::errno(err),
	};
};

// Creates a UDP socket bound to an interface.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (io::file | net::error) = {
	const sockfd = match (rt::socket(match (addr) {
		ip::addr4 => rt::AF_INET: int,
		ip::addr6 => rt::AF_INET6: int,
	}, rt::SOCK_DGRAM, 0)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	const sockaddr = ip::to_native(addr, port);
	const sz = size(rt::sockaddr): u32;
	match (rt::bind(sockfd, &sockaddr, sz)) {
		int => void,
		err: rt::errno => return errors::errno(err),
	};

	for (let i = 0z; i < len(options); i += 1) {
		// The only option is portassignment right now
		let sn = rt::sockaddr {...};
		let al = size(rt::sockaddr): u32;
		match (rt::getsockname(sockfd, &sn, &al)) {
			err: rt::errno => return errors::errno(err),
			int => void,
		};
		const addr = ip::from_native(sn);
		*options[i] = addr.1;
	};

	return io::fdopen(sockfd, "<udp listener>",
		io::mode::READ | io::mode::WRITE);
};

// Sends a UDP packet to the destination previously specified by [[connect]].
export fn send(sock: *io::file, buf: []u8) (size | net::error) = {
	return match (rt::send(io::fd(sock), buf: *[*]u8, len(buf), 0)) {
		sz: size => sz,
		err: rt::errno => errors::errno(err),
	};
};

// Sends a UDP packet using this socket.
export fn sendto(
	sock: *io::file,
	buf: []u8,
	dest: ip::addr,
	port: u16,
) (size | net::error) = {
	const sockaddr = ip::to_native(dest, port);
	const sz = size(rt::sockaddr): u32;
	return match (rt::sendto(io::fd(sock), buf: *[*]u8, len(buf),
			0, &sockaddr, sz)) {
		sz: size => sz,
		err: rt::errno => errors::errno(err),
	};
};

// Receives a UDP packet from a bound socket.
export fn recvfrom(
	sock: *io::file,
	buf: []u8,
	src: nullable *ip::addr,
	port: nullable *u16,
) (size | net::error) = {
	let addrsz = size(rt::sockaddr): u32;
	const sockaddr = rt::sockaddr { ... };
	const sz = match (rt::recvfrom(io::fd(sock), buf: *[*]u8, len(buf),
			0, &sockaddr, &addrsz)) {
		sz: size => sz,
		err: rt::errno => return errors::errno(err),
	};

	assert(addrsz <= size(rt::sockaddr));
	const peer = ip::from_native(sockaddr);
	match (src) {
		null => void,
		src: *ip::addr => *src = peer.0,
	};
	match (port) {
		null => void,
		port: *u16 => *port = peer.1,
	};

	return sz;
};
