use net::ip;
use net::udp;
use unix::resolvconf;

let defaults: []ip::addr = [];

@fini fn fini() void = {
	free(defaults);
};

// Performs a DNS query using the provided list of DNS servers. The caller must
// free the return value with [[message_free]]. If no DNS servers are provided,
// the system defaults (if any) are used.
export fn query(query: *message, addr: ip::addr...) (*message | error) = {
	if (len(addr) == 0) {
		if (len(defaults) == 0) {
			defaults = resolvconf::load();
		};
		addr = defaults;
	};

	let socket = udp::listen(ip::ANY_V4, 0)?;
	defer udp::close(socket);

	// TODO: Use TCP for messages >512 bytes
	let sendbuf: [512]u8 = [0...];
	let z = encode(sendbuf, query);
	// TODO: Query multiple servers
	udp::sendto(socket, sendbuf[..z], addr[0], 53)?;

	let recvbuf: [512]u8 = [0...];
	for (true) {
		// TODO: Add timeout
		let src: ip::addr = ip::ANY_V4;
		z = udp::recvfrom(socket, recvbuf, &src, null)?;
		if (!ip::equal(src, addr[0])) {
			continue;
		};

		let header = header { ... };
		let dec = decoder_init(recvbuf[..z]);
		decode_header(&dec, &header)?;
		if (header.id != query.header.id) {
			continue;
		};

		break;
	};

	return decode(recvbuf[..z])?;
};
