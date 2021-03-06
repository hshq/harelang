// An executable command.
export type command = struct {
	platform: platform_cmd,
	argv: []str,
	env: []str,
};

// Returned when path resolution fails to find a command by its name.
export type nocmd = void!;

// An error provided by the operating system.
export type os_error = struct {
	string: *fn(data: *void) str,
	data: *void,
}!;

// All errors that can be returned from os::exec.
export type error = (nocmd | os_error)!;

// Returns a human-readable message for the given error.
export fn errstr(err: error) const str = {
	return match (err) {
		err: os_error => err.string(err.data),
		nocmd         => "Command not found",
	};
};

