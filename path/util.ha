use strings;

fn getbytes(in: (str | *buffer)) []u8 = {
	match (in) {
	case let st: str =>
		return strings::toutf8(st);
	case let buf: *buffer =>
		return buf.cur;
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
export fn abs(path: str) bool = {
	let path = getbytes(path);
	if (len(path) == 0) {
		return false;
	};
	return path[0] == PATHSEP;
};
