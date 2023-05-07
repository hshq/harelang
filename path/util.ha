// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
use strings;

fn getbytes(in: (str | *buffer)) []u8 = {
	match (in) {
	case let st: str =>
		return strings::toutf8(st);
	case let buf: *buffer =>
		return buf.buf[..buf.end];
	};
};

fn getstring(in: (str | *buffer)) str = {
	match (in) {
	case let st: str =>
		return st;
	case let buf: *buffer =>
		return string(buf);
	};
};

// Returns true if a path is an absolute path.
export fn abs(path: (*buffer | str)) bool = {
	let path = getbytes(path);
	return 0 < len(path) && path[0] == PATHSEP;
};
