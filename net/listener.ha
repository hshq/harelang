use errors;
use io;

// A listener binds a socket and listens for incoming traffic for some
// unspecified protocol. This is generally most useful for providing an
// abstraction between a TCP socket and Unix socket (or any other stream
// oriented protocol), where the implementation which accepts and processes
// connections is not aware of the underlying transport. Most users will not
// need to use this interface directly, preferring functions such as
// [[net::tcp::accept]].
export type listener = struct {
	accept: nullable *fn(l: *listener) (*io::stream | io::error),
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

// Shuts down a [[listener]] and frees resources associated with it.
export fn shutdown(l: *listener) void = {
	match (l.shutdown) {
		f: *fn(l: *listener) void => f(l),
		null => void,
	};
};
