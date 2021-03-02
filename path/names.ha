use bytes;
use strings;

// Returns the directory name for a given path. For a path to a file name, this
// returns the directory in which that file resides. For a path to a directory,
// this returns the path to its parent directory. The return value is borrowed
// from the input, use [dup] to extend its lifetime.
export fn dirname(path: path::path) path::path = {
	let b = pathbytes(normalize(path));
	let i = match (bytes::rindex(b, PATHSEP)) {
		void => return path,
		z: size => z,
	};
	if (i == 0) {
		i += 1;
	};
	return
		if (path is str) strings::from_utf8_unsafe(b[..i])
		else b[..i];
};

@test fn dirname() void = {
	let p: path = "/foo/bar";
	assert(dirname(p) as str == "/foo");
	let p: path = "/foo";
	assert(dirname(p) as str == "/");
	let p: path = "/";
	assert(dirname(p) as str == "/");
	let p: path = "foo/bar";
	assert(dirname(p) as str == "foo");
	let p: path = "foo";
	assert(dirname(p) as str == "foo");
};

// Returns the final component of a given path. For a path to a file name, this
// returns the file name. For a path to a directory, this returns the directory
// name. The return value is borrowed from the input, use [dup] to extend its
// lifetime.
export fn basename(path: path::path) path::path = {
	let b = pathbytes(normalize(path));
	let i = match (bytes::rindex(b, PATHSEP)) {
		void => return path,
		z: size => if (z + 1 < len(b)) z + 1z else 0z,
	};
	return
		if (path is str) strings::from_utf8_unsafe(b[i..])
		else b[i..];
};

@test fn basename() void = {
	let p: path = "/foo/bar";
	assert(basename(p) as str == "bar");
	let p: path = "/foo";
	assert(basename(p) as str == "foo");
	let p: path = "/";
	assert(basename(p) as str == "/");
	let p: path = "foo/bar";
	assert(basename(p) as str == "bar");
	let p: path = "foo";
	assert(basename(p) as str == "foo");
};

// Returns true if the given path is a root directory.
export fn is_root(path: path::path) bool = len(pathbytes(path)) == 1;
