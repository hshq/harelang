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
	const family = match (dest) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	const sockfd = match (rt::socket(family, rt::SOCK_DGRAM, 0)) {
	case err: rt::errno =>
		return errors::errno(err);
	case fd: int =>
		yield fd;
	};

	const sockaddr = ip::to_native(dest, port);
	const sz = size(rt::sockaddr): u32;
	match (rt::connect(sockfd, &sockaddr, sz)) {
	case int =>
		return io::fdopen(sockfd);
	case err: rt::errno =>
		return errors::errno(err);
	};
};

// Creates a UDP socket bound to an interface.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (io::file | net::error) = {
	const family = match (addr) {
	case ip::addr4 =>
		yield rt::AF_INET: int;
	case ip::addr6 =>
		yield rt::AF_INET6: int;
	};
	const sockfd = match (rt::socket(family, rt::SOCK_DGRAM, 0)) {
	case err: rt::errno =>
		return errors::errno(err);
	case fd: int =>
		yield fd;
	};
	let flags = rt::fcntl(sockfd, rt::F_GETFL, 0)!;
	rt::fcntl(sockfd, rt::F_SETFL, flags | rt::O_CLOEXEC)!;

	const sockaddr = ip::to_native(addr, port);
	const sz = size(rt::sockaddr): u32;
	match (rt::bind(sockfd, &sockaddr, sz)) {
	case int => void;
	case err: rt::errno =>
		return errors::errno(err);
	};

	for (let i = 0z; i < len(options); i += 1) {
		// The only option is portassignment right now
		let sn = rt::sockaddr {...};
		let al = size(rt::sockaddr): u32;
		match (rt::getsockname(sockfd, &sn, &al)) {
		case err: rt::errno =>
			return errors::errno(err);
		case int => void;
		};
		const addr = ip::from_native(sn);
		*options[i] = addr.1;
	};

	return io::fdopen(sockfd);
};

// Sends a UDP packet to the destination previously specified by [[connect]].
export fn send(sock: io::file, buf: []u8) (size | net::error) = {
	match (rt::send(sock, buf: *[*]u8, len(buf), 0)) {
	case sz: size =>
		return sz;
	case err: rt::errno =>
		return errors::errno(err);
	};
};

// Sends a UDP packet using this socket.
export fn sendto(
	sock: io::file,
	buf: []u8,
	dest: ip::addr,
	port: u16,
) (size | net::error) = {
	const sockaddr = ip::to_native(dest, port);
	const sz = size(rt::sockaddr): u32;
	match (rt::sendto(sock, buf: *[*]u8, len(buf), 0, &sockaddr, sz)) {
	case sz: size =>
		return sz;
	case err: rt::errno =>
		return errors::errno(err);
	};
};

// Receives a UDP packet from a bound socket.
export fn recvfrom(
	sock: io::file,
	buf: []u8,
	src: nullable *ip::addr,
	port: nullable *u16,
) (size | net::error) = {
	let addrsz = size(rt::sockaddr): u32;
	const sockaddr = rt::sockaddr { ... };
	const sz = match (rt::recvfrom(sock, buf: *[*]u8, len(buf), 0,
		&sockaddr, &addrsz)) {
	case sz: size =>
		yield sz;
	case err: rt::errno =>
		return errors::errno(err);
	};

	assert(addrsz <= size(rt::sockaddr));
	const peer = ip::from_native(sockaddr);
	match (src) {
	case null => void;
	case src: *ip::addr =>
		*src = peer.0;
	};
	match (port) {
	case null => void;
	case port: *u16 =>
		*port = peer.1;
	};

	return sz;
};
