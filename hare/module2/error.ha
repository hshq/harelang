use io;
use fs;

// Returned if the desired module could not be found.
export type modnotfound = !void;

// Tagged union of all possible error types.
export type error = !(io::error | fs::error | modnotfound);

export fn strerror(err: error) const str = {
	match (err) {
	case let err: io::error =>
		return io::strerror(err);
	case let err: fs::error =>
		return fs::strerror(err);
	case modnotfound =>
		// TODO: put the module name in here
		return "Module not found";
	};
};
