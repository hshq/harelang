use bytes;
use strings;

// A path or path component.
export type path = (str | []u8);

fn pathbytes(path: path) []u8 = match (path) {
	s: str  => strings::to_utf8(s),
	b: []u8 => b,
};

// Frees a path.
export fn path_free(p: path) void = match (p) {
	s: str => free(s),
	b: []u8 => free(b),
};

// Duplicates a path.
export fn dup(p: path) path = match (p) {
	s: str => strings::dup(s),
	b: []u8 => {
		// TODO: alloc from another slice
		let new: []u8 = alloc([], len(b));
		append(new, ...b);
		new;
	},
};

// Returns true if two paths are equal.
export fn equal(a: path, b: path) bool =
	bytes::equal(pathbytes(a), pathbytes(b));

// Returns true if a path is an absolute path.
export fn abs(path: path::path) bool = {
	let b = pathbytes(path);
	if (len(b) == 0) {
		return false;
	};
	return b[0] == PATHSEP;
};
