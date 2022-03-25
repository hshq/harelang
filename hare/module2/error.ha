use fs;
use hare::parse;
use io;

// Returned if the desired module could not be found.
export type modnotfound = !void;

// Tagged union of all possible error types.
export type error = !(io::error | fs::error | parse::error | modnotfound);

export fn strerror(err: error) const str = {
	match (err) {
	case let err: io::error =>
		return io::strerror(err);
	case let err: fs::error =>
		return fs::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case modnotfound =>
		return "Module not found";
	};
};
