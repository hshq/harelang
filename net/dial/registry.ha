use io;
use net;

export type dialer = fn(addr: str, service: str) (*io::stream | net::error);

type protocol = struct {
	name: str,
	dial: *dialer,
};

type service = struct {
	name: str,
	alias: []str,
	port: u16,
};

let default_protocols: []protocol = [
	protocol { name = "tcp", dial = &dial_tcp },
	protocol { name = "udp", dial = &dial_udp },
];

let default_tcp: []service = [
	service { name = "ssh", alias = [], port = 22 },
	service { name = "smtp", alias = ["mail"], port = 25 },
	service { name = "domain", alias = ["dns"], port = 53 },
	service { name = "http", alias = ["www"], port = 80 },
	service { name = "imap2", alias = ["imap"], port = 143 },
	service { name = "https", alias = [], port = 443 },
	service { name = "submission", alias = [], port = 587 },
	service { name = "imaps", alias = [], port = 993 },
];

let default_udp: []service = [
	service { name = "domain", alias = ["dns"], port = 53 },
	service { name = "ntp", alias = [], port = 123 },
];

let protocols: []protocol = [];
let tcp_services: []service = [];
let udp_services: []service = [];

@fini fn fini() void = {
	free(protocols);
	free(tcp_services);
	free(udp_services);
};

// Registers a new transport-level protocol (e.g. TCP) with the dialer. The name
// should be statically allocated.
export fn registerproto(name: str, dial: *dialer) void = {
	append(protocols, protocol {
		name = name,
		dial = dial,
	});
};

// Registers a new application-level service (e.g. SSH) with the dialer. Note
// that the purpose of services is simply to establish the default outgoing
// port for TCP and UDP connections. The name and alias list should be
// statically allocated.
export fn registersvc(
	name: str,
	alias: []str,
	tcp: (u16 | void),
	udp: (u16 | void),
) void = {
	assert(!(tcp is void) || !(udp is void),
		"Expected registersvc to receive TCP or UDP port, or both");
	match (tcp) {
		void => void,
		port: u16 => append(tcp_services, service {
			name = name,
			alias = alias,
			port = port,
		}),
	};
	match (udp) {
		void => void,
		port: u16 => append(udp_services, service {
			name = name,
			alias = alias,
			port = port,
		}),
	};
};
