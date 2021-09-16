use errors;

// An attempt was made to use an unsupported protocol.
export type unknownproto = !void;

// All error types which can be returned from networking functions.
export type error = !(unknownproto | ...errors::error);

// Converts a [[net::error]] into a human-readable string.
export fn strerror(err: error) const str = {
	match (err) {
	case unknownproto =>
		return "Unsupported protocol";
	case err: errors::error =>
		return errors::strerror(err);
	};
};

// TODO: listener should not be here, working around bug in harec forward
// references

// A listener binds a socket and listens for incoming traffic for some
// unspecified protocol. This is generally most useful for providing an
// abstraction between a TCP socket and Unix socket (or any other stream
// oriented protocol), where the implementation which accepts and processes
// connections is not aware of the underlying transport. Most users will not
// need to use this interface directly, preferring functions such as
// [[net::tcp::accept]].
export type listener = struct {
	accept: nullable *fn(l: *listener) (io::file | error),
	shutdown: nullable *fn(l: *listener) void,
};
