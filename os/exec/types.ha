use errors;

// An executable command.
export type command = struct {
	platform: platform_cmd,
	argv: []str,
	env: []str,
};

// Returned when path resolution fails to find a command by its name.
export type nocmd = !void;

// All errors that can be returned from os::exec.
export type error = !(nocmd | errors::opaque);

// Returns a human-readable message for the given error.
export fn strerror(err: error) const str = {
	return match (err) {
		nocmd => "Command not found",
		err: errors::opaque => errors::strerror(err),
	};
};

