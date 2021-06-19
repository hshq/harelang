use errors;
use net;
use net::ip;
use rt;

export type socket = int;

// Creates a UDP socket and sets the default destination to the given address.
export fn connect(
	dest: ip::addr,
	port: u16,
) (socket | errors::opaque) = {
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
		int => sockfd,
		err: rt::errno => errors::errno(err),
	};
};

// Creates a UDP socket bound to an interface.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: bind_option...
) (socket | errors::opaque) = {
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

	return sockfd;
};

// Closes a UDP socket.
export fn close(sock: socket) void = {
	rt::close(sock): void;
};

// Sends a UDP packet to the destination previously specified by [[connect]].
export fn send(sock: socket, buf: []u8) (size | errors::opaque) = {
	return match (rt::send(sock, buf: *[*]u8, len(buf), 0)) {
		sz: size => sz,
		err: rt::errno => errors::errno(err),
	};
};

// Sends a UDP packet using this socket.
export fn sendto(
	sock: socket,
	buf: []u8,
	dest: ip::addr,
	port: u16,
) (size | errors::opaque) = {
	const sockaddr = ip::to_native(dest, port);
	const sz = size(rt::sockaddr): u32;
	return match (rt::sendto(sock, buf: *[*]u8, len(buf),
			0, &sockaddr, sz)) {
		sz: size => sz,
		err: rt::errno => errors::errno(err),
	};
};

// Receives a UDP packet from a bound socket.
export fn recvfrom(
	sock: socket,
	buf: []u8,
	src: nullable *ip::addr,
	port: nullable *u16,
) (size | errors::opaque) = {
	let addrsz = size(rt::sockaddr): u32;
	const sockaddr = rt::sockaddr { ... };
	const sz = match (rt::recvfrom(sock, buf: *[*]u8, len(buf),
			0, &sockaddr, &addrsz)) {
		sz: size => sz,
		err: rt::errno => errors::errno(err),
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
