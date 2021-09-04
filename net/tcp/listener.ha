use io;
use net;

// Accepts the next connection from a listener. Blocks until a new connection is
// available. This is a convenience wrapper around [[net::accept]].
export fn accept(l: *net::listener) (io::file | net::error) = {
	return net::accept(l);
};

// Shuts down a [[net::listener]] and frees resources associated with it. This
// is a convenience wrapper around [[net::shutdown]].
export fn shutdown(l: *net::listener) void = {
	return net::shutdown(l);
};
