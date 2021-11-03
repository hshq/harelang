use errors;
use io;

// An executable command.
export type command = struct {
	platform: platform_cmd,
	argv: []str,
	env: []str,
	files: [](io::file, io::file),
};

// Returned when path resolution fails to find a command by its name.
export type nocmd = !void;

// All errors that can be returned from os::exec.
export type error = !(nocmd | ...errors::error);

// Returns a human-readable message for the given error.
export fn strerror(err: error) const str = {
	match (err) {
	case nocmd =>
		return "Command not found";
	case err: errors::opaque =>
		return errors::strerror(err);
	};
};

