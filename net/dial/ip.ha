// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

// Provides default dialers for tcp and udp
use io;
use net;
use net::ip;
use net::tcp;
use net::udp;
use io;

fn dial_tcp(addr: str, service: str) (io::file | error) = {
	const result = resolve("tcp", addr, service)?;
	const addrs = result.0, port = result.1;
	for (let i = 0z; i < len(addrs); i += 1) {
		const addr = addrs[i];
		match (tcp::connect(addr, port)) {
		case let conn: io::file =>
			return conn;
		case let err: net::error =>
			if (i + 1 >= len(addrs)) {
				return err;
			};
		};
	};
	abort(); // Unreachable
};

fn dial_udp(addr: str, service: str) (io::file | error) = {
	const result = resolve("udp", addr, service)?;
	const addrs = result.0, port = result.1;
	for (let i = 0z; i < len(addrs); i += 1) {
		const addr = addrs[i];
		match (udp::connect(addr, port)) {
		case let sock: io::file =>
			return sock;
		case let err: net::error =>
			if (i + 1 >= len(addrs)) {
				return err;
			};
		};
	};
	abort(); // Unreachable
};
