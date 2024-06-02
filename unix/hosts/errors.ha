use encoding::utf8;
use fs;
use io;
use net::ip;

// Returned when an invalid host line was found.
export type invalid = !void;

// All possible errors returned from this module.
export type error = !(io::error | invalid | utf8::invalid | ip::invalid
	| fs::error);

// Converts an [[error]] to a human-friendly representation.
export fn strerror(err: error) const str = {
	match (err) {
	case invalid =>
		return "Host file format is invalid";
	case utf8::invalid =>
		return "File is invalid UTF-8";
	case ip::invalid =>
		return "IP address is invalid";
	case let err: io::error =>
		return io::strerror(err);
	case let err: fs::error =>
		return fs::strerror(err);
	};
};
