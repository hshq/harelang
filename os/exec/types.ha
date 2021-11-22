use errors;
use io;

// Represents a "null" file descriptor, e.g. /dev/null.
export type nullfd = void;

// Used to close a file descriptor which does not have the CLOEXEC flag set.
export type closefd = void;

// An executable command.
export type command = struct {
	platform: platform_cmd,
	argv: []str,
	env: []str,
	files: []((io::file | nullfd | closefd), io::file),
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

