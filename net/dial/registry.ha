// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net;
use net::dns;
use unix::hosts;

// Returned if the address parameter was invalid, for example if it specifies an
// invalid port number.
export type invalid_address = !void;

// Returned if the service parameter does not name a service known to the
// system.
export type unknown_service = !void;

// Errors which can occur from dial.
export type error = !(invalid_address | unknown_service | net::error | dns::error
	| hosts::error);

// Converts an [[error]] to a human-readable string. The result may be
// statically allocated.
export fn strerror(err: error) const str = {
	// TODO: These could be better
	match (err) {
	case invalid_address =>
		return "Attempted to dial an invalid address";
	case unknown_service =>
		return "Unknown service";
	case let err: net::error =>
		return net::strerror(err);
	case let err: dns::error =>
		return dns::strerror(err);
	case let err: hosts::error =>
		return hosts::strerror(err);
	};
};

// A dialer is a function which implements dial for a specific protocol.
export type dialer = fn(addr: str, service: str) (net::socket | error);

type protocol = struct {
	name: str,
	dial: *dialer,
};

type service = struct {
	proto: str,
	name: str,
	alias: []str,
	port: u16,
};

let default_protocols: [_]protocol = [
	protocol { name = "tcp", dial = &dial_tcp },
	protocol { name = "udp", dial = &dial_udp },
];

let default_services: [_]service = [
	service { proto = "tcp", name = "ssh", alias = [], port = 22 },
	service { proto = "tcp", name = "smtp", alias = ["mail"], port = 25 },
	service { proto = "tcp", name = "domain", alias = ["dns"], port = 53 },
	service { proto = "tcp", name = "http", alias = ["www"], port = 80 },
	service { proto = "tcp", name = "imap2", alias = ["imap"], port = 143 },
	service { proto = "tcp", name = "https", alias = [], port = 443 },
	service { proto = "tcp", name = "submission", alias = [], port = 587 },
	service { proto = "tcp", name = "imaps", alias = [], port = 993 },
	service { proto = "udp", name = "domain", alias = ["dns"], port = 53 },
	service { proto = "udp", name = "ntp", alias = [], port = 123 },
];

let protocols: []protocol = [];
let services: []service = [];

@fini fn fini() void = {
	free(protocols);
	free(services);
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
	proto: str,
	name: str,
	alias: []str,
	port: u16,
) void = {
	append(services, service {
		proto = proto,
		name = name,
		alias = alias,
		port = port,
	});
};

fn lookup_service(proto: str, service: str) (u16 | void) = {
	for (let i = 0z; i < len(default_services); i += 1) {
		const serv = &default_services[i];
		if (service_match(serv, proto, service)) {
			return serv.port;
		};
	};

	for (let i = 0z; i < len(services); i += 1) {
		const serv = &services[i];
		if (service_match(serv, proto, service)) {
			return serv.port;
		};
	};
};

fn service_match(candidate: *service, proto: str, service: str) bool = {
	if (candidate.name == service) {
		return true;
	};
	for (let j = 0z; j < len(candidate.alias); j += 1) {
		if (candidate.alias[j] == service) {
			return true;
		};
	};
	return false;
};
