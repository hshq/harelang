// Provides default dialers for tcp and udp
use net;
use net::ip;
use net::tcp;
use net::udp;

fn dial_tcp(addr: str, service: str) (*io::stream | error) = {
	const result = resolve("tcp", addr, service)?;
	const addrs = result.0, port = result.1;
	for (let i = 0z; i < len(addrs); i += 1) {
		const addr = addrs[i];
		match (tcp::connect(addr, port)) {
			conn: *io::stream => return conn,
			err: net::error => if (i + 1 >= len(addrs)) {
				return err;
			},
		};
	};
	abort(); // Unreachable
};

fn dial_udp(addr: str, service: str) (*io::stream | error) = {
	const result = resolve("udp", addr, service)?;
	const addrs = result.0, port = result.1;
	for (let i = 0z; i < len(addrs); i += 1) {
		const addr = addrs[i];
		match (udp::connect(addr, port)) {
			sock: udp::socket => return udp::stream(sock),
			err: net::error => if (i + 1 >= len(addrs)) {
				return err;
			},
		};
	};
	abort(); // Unreachable
};
