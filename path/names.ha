use bytes;
use encoding::utf8;
use strings;

// Returns the directory name for a given path. For a path to a file name, this
// returns the directory in which that file resides. For a path to a directory,
// this returns the path to its parent directory. The return value is borrowed
// from the input, use [dup] to extend its lifetime.
export fn dirname(path: str) str = {
	let b = strings::to_utf8(path);
	let i = match (bytes::rindex(b, PATHSEP)) {
		void => return path,
		z: size => z,
	};
	if (i == 0) {
		i += 1;
	};
	return strings::from_utf8_unsafe(b[..i]);
};

@test fn dirname() void = {
	assert(dirname("/foo/bar") == "/foo");
	assert(dirname("/foo") == "/");
	assert(dirname("/") == "/");
	assert(dirname("foo/bar") == "foo");
	assert(dirname("foo") == "foo");
};

// Returns the final component of a given path. For a path to a file name, this
// returns the file name. For a path to a directory, this returns the directory
// name. The return value is borrowed from the input, use [dup] to extend its
// lifetime.
export fn basename(path: str) str = {
	let b = strings::to_utf8(path);
	let i = match (bytes::rindex(b, PATHSEP)) {
		void => return path,
		z: size => if (z + 1 < len(b)) z + 1z else 0z,
	};
	return strings::from_utf8_unsafe(b[i..]);
};

@test fn basename() void = {
	assert(basename("/foo/bar") == "bar");
	assert(basename("/foo") == "foo");
	assert(basename("/") == "/");
	assert(basename("foo/bar") == "bar");
	assert(basename("foo") == "foo");
};

// Returns the file extension for a path. The return value is borrowed from the
// input, see [strings::dup] to extend its lifetime.
//
// The return value includes the '.' character.
//
// extension("foo/example") => ""
// extension("foo/example.txt") => ".txt"
// extension("foo/example.tar.gz") => ".tar.gz"
export fn extension(p: str) str = {
	let b = strings::to_utf8(p);
	if (len(b) == 0 || b[len(b) - 1] == PATHSEP) {
		return "";
	};
	let b = strings::to_utf8(basename(p));
	let i = match (bytes::index(b, '.': u32: u8)) {
		void => return "",
		z: size => z,
	};
	let e = b[i..];
	return strings::from_utf8_unsafe(e);
};

@test fn extension() void = {
	assert(extension("") == "");
	assert(extension("foo/") == "");
	assert(extension("foo/bar") == "");
	assert(extension("foo/bar.txt") == ".txt");
	assert(extension("foo/bar.tar.gz") == ".tar.gz");
	assert(extension("foo.bar/baz.ha") == ".ha");
};
