// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use net;
use net::ip;
use net::uri;

// Dials a remote address, establishing a connection and returning the resulting
// [[net::socket]]. The proto parameter should be the transport protocol (e.g.
// "tcp"), the address parameter should be the remote address, and the service
// should be the name of the service, or the default port to use.
//
// The interpretation of the address and service parameters is dependent on the
// protocol in use. For IP-based protocols (such as TCP or UDP), the address
// parameter may be either an IPv4 or IPv6 address, or a name, and may include a
// port separated by a colon (':'). If an IPv6 address and a port are both
// desired, use brackets ('[' and ']') to separate the address from the port
// (e.g. "[::1]:80"). If the port is not specified, it is inferred from the
// service parameter. If a name is used instead of an IP address, a DNS lookup
// is performed, consulting the local /etc/hosts file or equivalent, if
// possible.
//
// The service parameter can be a service name (e.g. "submission") or a default
// port to use, if one is not specified by address. If a service name is used,
// an internal list of services is consulted (see [[registersvc]]), and if not
// known to Hare, the system service list (e.g. /etc/services) will be
// consulted. If the connection port cannot be established, [[errors::invalid]]
// is returned. The special service name "unknown" will always consult the
// address parameter for a desired port, and will return [[errors::invalid]] if
// one is not provided there.
//
// If the address parameter includes a name, but not a port, an SRV lookup will
// be performed alongside the A or AAAA record lookup for that name. If the name
// server provides an SRV record for the given service, it will be utilized in
// lieu of the service database.
export fn dial(
	proto: str,
	address: str,
	service: str,
) (net::socket | error) = {
	for (let i = 0z; i < len(default_protocols); i += 1) {
		const p = default_protocols[i];
		if (p.name == proto) {
			return p.dial(address, service);
		};
	};
	for (let i = 0z; i < len(protocols); i += 1) {
		const p = protocols[i];
		if (p.name == proto) {
			return p.dial(address, service);
		};
	};
	return net::unknownproto: net::error;
};

def HOST_MAX: size = 255;

// Performs a [[dial]] operation for a given URI, taking the service name from
// the URI scheme and forming an address from the URI host and port.
export fn dial_uri(proto: str, uri: *uri::uri) (net::socket | error) = {
	// XXX: Should the code to convert a URI to e.g. "[::1]:80" be
	// generalized for end-user use?
	if (uri.host is str && len(uri.host as str) > HOST_MAX) {
		return invalid_address;
	};
	static let addr: [HOST_MAX + len("[]:65535")]u8 = [0...];

	const colon = if (uri.port != 0) ":" else "";
	const port: fmt::formattable = if (uri.port != 0) uri.port else "";

	let addr = match (uri.host) {
	case let host: str =>
		yield fmt::bsprintf(addr, "{}{}{}", host, colon, port);
	case let ip: ip::addr4 =>
		const host = ip::string(ip);
		yield fmt::bsprintf(addr, "{}{}{}", host, colon, port);
	case let ip: ip::addr6 =>
		const host = ip::string(ip);
		yield fmt::bsprintf(addr, "[{}]{}{}", host, colon, port);
	};

	return dial(proto, addr, uri.scheme);
};
