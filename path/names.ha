use bytes;
use encoding::utf8;
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

// Returns the file extension for a path. This presumes that the file extension
// is a valid UTF-8 string, if not, it will return an empty string. The return
// value is borrowed from the input, see [strings::dup] to extend its lifetime.
//
// The return value includes the '.' character.
//
// extension("foo/example") => ""
// extension("foo/example.txt") => ".txt"
// extension("foo/example.tar.gz") => ".tar.gz"
export fn extension(p: path::path) str = {
	let b = pathbytes(p);
	if (len(b) == 0 || b[len(b) - 1] == PATHSEP) {
		return "";
	};
	let b = pathbytes(basename(p));
	let i = match (bytes::index(b, '.': u32: u8)) {
		void => return "",
		z: size => z,
	};
	let e = b[i..];
	return match (strings::try_from_utf8(e)) {
		utf8::invalid => "",
		s: str => s,
	};
};

@test fn extension() void = {
	assert(extension("") == "");
	assert(extension("foo/") == "");
	assert(extension("foo/bar") == "");
	assert(extension("foo/bar.txt") == ".txt");
	assert(extension("foo/bar.tar.gz") == ".tar.gz");
	assert(extension("foo.bar/baz.ha") == ".ha");
};
