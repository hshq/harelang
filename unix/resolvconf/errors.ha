use errors;
use encoding::utf8;
use io;
use net::ip;

// The resolv.conf file is not well-formatted.
export type invalid = !void;

// Any error which can be raised by the resolv.conf parser.
export type error = !(errors::error | io::error | utf8::invalid | ip::invalid | invalid);

// Converts an [[error]] into a human-friendly representation.
export fn strerror(err: error) const str = {
	match (err) {
	case invalid =>
		return "resolv.conf is not well-formatted";
	case let err: errors::error =>
		return errors::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case let err: ip::invalid =>
		return "Invalid IP address in /etc/resolv.conf";
	case utf8::invalid =>
		return "resolv.conf contains invalid UTF-8 data";
	};
};
