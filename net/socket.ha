use io;

// Enables keep-alive for a socket.
export type keepalive = void;

// Enables port re-use for a TCP listener.
export type reuseport = void;

// Enables address re-use for a TCP listener.
export type reuseaddr = void;

// Configures the backlog size for a listener. If not specified, a sensible
// default (10) is used.
export type backlog = u32;

// To have the system select an arbitrary unused TCP port for [listen], set port
// to zero. To retrieve the assigned port, provide this as one of the options
// and the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// A listener binds a socket on the system and listens for incoming traffic for
// some specific protocol.
export type listener = struct {
	accept: nullable *fn(l: *listener) (*io::stream | io::error),
	shutdown: nullable *fn(l: *listener) void,
};

// Options for [listen].
export type listen_option = (
	keepalive |
	reuseport |
	reuseaddr |
	backlog |
	portassignment);

// Options for [connect].
export type connect_option = keepalive;

// Accepts the next connection from a listener. Blocks until a new connection is
// available.
export fn accept(l: *listener) (*io::stream | io::error) = {
	return match (l.accept) {
		f: *fn(l: *listener) (*io::stream | io::error) => f(l),
		null => io::unsupported,
	};
};

// Shuts down a [listener] and frees resources associated with it.
export fn shutdown(l: *listener) void = {
	match (l.shutdown) {
		f: *fn(l: *listener) void => f(l),
		null => void,
	};
};
