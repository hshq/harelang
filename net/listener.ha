use errors;
use io;

// Accepts the next connection from a listener. Blocks until a new connection is
// available.
export fn accept(l: *listener) (io::file | error) = {
	match (l.accept) {
	case let f: *fn(l: *listener) (io::file | error) =>
		return f(l);
	case null =>
		return errors::unsupported;
	};
};

// Shuts down a [[listener]] and frees resources associated with it.
export fn shutdown(l: *listener) void = {
	match (l.shutdown) {
	case let f: *fn(l: *listener) void =>
		f(l);
	case null => void;
	};
};
