use errors;
use io;
use net::ip;

// Enables keep-alive for a socket.
export type keepalive = void;

// Enables port re-use for a TCP listener.
export type reuseport = void;

// Enables address re-use for a TCP listener.
export type reuseaddr = void;

// Configures the backlog size for a listener. If not specified, a sensible
// default (10) is used.
export type backlog = u32;

// To have the system select an arbitrary unused port for [listen], set port to
// zero. To retrieve the assigned port, provide this as one of the options and
// the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// Options for the [listen] family of functions.
export type listen_option = (
	keepalive |
	reuseport |
	reuseaddr |
	backlog |
	portassignment);

// Options for the [connect] family of functions.
export type connect_option = keepalive;

// Indicates that a send or recv operation should include out-of-band data.
export type oob = []u8;

// Options for [send] and [recv].
export type dgram_option = oob;

// A listener binds a socket and listens for incoming traffic for some
// unspecified protocol.
export type listener = struct {
	accept: nullable *fn(l: *listener) (*io::stream | io::error),
	send: nullable *fn(l: *listener, to: ip::addr, port: u16,
		buf: []u8, options: dgram_option...) (size | io::error),
	recv: nullable *fn(l: *listener,
		from: nullable *ip::addr, port: nullable *u16,
		buf: []u8, options: dgram_option...) (size | io::error),
	shutdown: nullable *fn(l: *listener) void,
};

// Accepts the next connection from a listener. Blocks until a new connection is
// available.
export fn accept(l: *listener) (*io::stream | io::error) = {
	return match (l.accept) {
		f: *fn(l: *listener) (*io::stream | io::error) => f(l),
		null => errors::unsupported,
	};
};

// Shuts down a [listener] and frees resources associated with it.
export fn shutdown(l: *listener) void = {
	match (l.shutdown) {
		f: *fn(l: *listener) void => f(l),
		null => void,
	};
};

// Sends a datagram to the given destination, returning the number of bytes sent
// (or an error).
export fn send(
	l: *listener,
	to: ip::addr,
	port: u16,
	buf: []u8,
	options: dgram_option...
) (size | io::error) = {
	abort(); // TODO
};

// Blocks until a datagram is received from a listener, writing it to the
// provided buffer and returning the number of bytes received. Populates the
// sender address and port in 'from' and 'port' if non-null.
export fn recv(
	l: *listener,
	from: nullable *ip::addr,
	port: nullable *u16,
	buf: []u8,
	options: dgram_option...
) (size | io::error) = {
	abort(); // TODO
};
