use errors;
use net::ip;
use net::udp;
use time;
use unix::poll;
use unix::resolvconf;

// TODO: Let user customize this?
def timeout: time::duration = 3 * time::SECOND;

// Performs a DNS query using the provided list of DNS servers. The caller must
// free the return value with [[message_free]].
//
// If no DNS servers are provided, the system default servers (if any) are used.
export fn query(query: *message, servers: ip::addr...) (*message | error) = {
	// TODO: Use TCP for messages >512 bytes
	if (len(servers) == 0) {
		servers = resolvconf::load();
	};
	if (len(servers) == 0) {
		// Fall back to localhost
		servers = [
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]: ip::addr6,
			[127, 0, 0, 1]: ip::addr4,
		];
	};

	const socket4 = udp::listen(ip::ANY_V4, 0)?;
	defer udp::close(socket4);
	const socket6 = udp::listen(ip::ANY_V6, 0)?;
	defer udp::close(socket6);
	const pollfd: [_]poll::pollfd = [
		poll::pollfd {
			fd = udp::sockfd(socket4),
			events = poll::event::POLLIN,
			...
		},
		poll::pollfd {
			fd = udp::sockfd(socket6),
			events = poll::event::POLLIN,
			...
		},
	];

	let sendbuf: [512]u8 = [0...];
	let z = encode(sendbuf, query)?;

	// We send requests in parallel to all configured servers and take the
	// first one which sends us a reasonable answer.
	for (let i = 0z; i < len(servers); i += 1) match (servers[i]) {
		ip::addr4 => {
			udp::sendto(socket4, sendbuf[..z], servers[i], 53)?;
		},
		ip::addr6 => {
			udp::sendto(socket6, sendbuf[..z], servers[i], 53)?;
		},
	};

	let header = header { ... };
	let recvbuf: [512]u8 = [0...];
	for (true) {
		let nevent = poll::poll(pollfd, timeout)!;
		if (nevent == 0) {
			return errors::timeout;
		};

		let src: ip::addr = ip::ANY_V4;
		if (pollfd[0].revents & poll::event::POLLIN != 0) {
			z = udp::recvfrom(socket4, recvbuf, &src, null)?;
		};
		if (pollfd[1].revents & poll::event::POLLIN != 0) {
			z = udp::recvfrom(socket6, recvbuf, &src, null)?;
		};

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
