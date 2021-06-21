use io;
use net;

// Dials a remote address using, establishing a connection and returning the
// resulting [[io::stream]]. The proto parameter should be the transport
// protocol (e.g. "tcp"), the address parameter should be the remote address,
// and the service should be the name of the service, or the default port to
// use.
//
// The address parameter may be either an IPv4 or IPv6 address, or a name, and
// may include a port separated by a colon (':'). If an IPv6 address and a port
// are both desired, use brackets ('[' and ']') to separate the address from the
// port (e.g. "[::1]:80"). If the port is not specified, it is inferred from the
// service parameter. If a name is used instead of an IP address, a DNS lookup
// is performed, consulting the local /etc/hosts file or equivalent, if
// possible.
//
// The service parameter can be a service name (e.g. "submission") or a default
// port to use, if one is not specified by address. If a service name is used,
// an internal list of services is consulted (see [[dial::registersvc]]), and if
// not known to Hare, the system service list (e.g. /etc/services) will be
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
) (*io::stream | net::error) = {
	abort(); // TODO
};
