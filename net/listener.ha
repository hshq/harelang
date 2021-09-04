use errors;
use io;

// Accepts the next connection from a listener. Blocks until a new connection is
// available.
export fn accept(l: *listener) (io::file | error) = {
	return match (l.accept) {
		f: *fn(l: *listener) (io::file | error) => f(l),
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
