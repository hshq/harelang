use net::ip;
use net::udp;
use unix::resolvconf;

// Performs a DNS query using the provided list of DNS servers. The caller must
// free the return value with [[message_free]].
//
// If no DNS servers are provided, the system default servers (if any) are used.
export fn query(query: *message, servers: ip::addr...) (*message | error) = {
	if (len(servers) == 0) {
		servers = resolvconf::load();
	};
	if (len(servers) == 0) {
		// Fall back to localhost
		servers = [[127, 0, 0, 1]: ip::addr4];
	};

	const socket = udp::listen(ip::ANY_V4, 0)?;
	defer udp::close(socket);

	// TODO: Use TCP for messages >512 bytes
	let sendbuf: [512]u8 = [0...];
	let z = encode(sendbuf, query)?;

	// We send requests in parallel to all configured servers and take the
	// first one which sends us a reasonable answer.
	for (let i = 0z; i < len(servers); i += 1) {
		udp::sendto(socket, sendbuf[..z], servers[i], 53)?;
	};

	let header = header { ... };
	let recvbuf: [512]u8 = [0...];
	for (true) {
		// TODO: Add timeout
		let src: ip::addr = ip::ANY_V4;
		z = udp::recvfrom(socket, recvbuf, &src, null)?;

		let expected = false;
		for (let i = 0z; i < len(servers); i += 1) {
			if (ip::equal(src, servers[i])) {
				expected = true;
				break;
			};
		};
		if (!expected) {
			continue;
		};

		const dec = decoder_init(recvbuf[..z]);
		decode_header(&dec, &header)?;
		if (header.id == query.header.id && header.op.qr == qr::RESPONSE) {
			break;
		};
	};

	assert(!header.op.tc, "TODO: Retry with TCP for truncated DNS response");

	check_rcode(header.op.rcode)?;
	return decode(recvbuf[..z])?;
};
