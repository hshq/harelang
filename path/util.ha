use strings;

// Returns true if a path is an absolute path.
export fn abs(path: str) bool = {
	let b = strings::to_utf8(path);
	if (len(b) == 0) {
		return false;
	};
	return b[0] == PATHSEP;
};
