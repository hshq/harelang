// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use strings;

// Returns the directory name for a given path. For a path to a file name, this
// returns the directory in which that file resides. For a path to a directory,
// this returns the path to its parent directory. If the path consists solely of
// the target's path separator, a string to the path is returned unmodified. If
// the path is empty, "." is returned. The return value is either borrowed from
// the input or statically allocated); use [[strings::dup]] to extend its
// lifetime or modify it.
export fn dirname(path: (str | *buffer)) const str = {
	let path = getstring(path);
	if (path == "") {
		return ".";
	};
	let trimmed = strings::rtrim(path, PATHSEP: u32: rune);
	if (trimmed == "") {
		return "/";
	};
	let b = strings::toutf8(trimmed);
	let i = match (bytes::rindex(b, PATHSEP)) {
	case void =>
		return ".";
	case let z: size =>
		yield z;
	};
	if (i == 0) {
		i += 1;
	};
	path = strings::fromutf8_unsafe(b[..i]);
	path = strings::rtrim(path, PATHSEP: u32: rune);
	if (path == "") {
		return "/";
	};
	return path;
};

@test fn dirname() void = {
	assert(dirname("/foo/bar") == "/foo");
	assert(dirname("/foo") == "/");
	assert(dirname("/") == "/");
	assert(dirname("//") == "/");
	assert(dirname("///") == "/");
	assert(dirname("foo/bar") == "foo");
	assert(dirname("") == ".");
	assert(dirname("foo") == ".");
	assert(dirname("foo/") == ".");
	assert(dirname("foo//") == ".");
	assert(dirname("///foo") == "/");
	assert(dirname("///foo//") == "/");
	assert(dirname("//foo///bar//") == "//foo");
};

// Returns the final component of a given path. For a path to a file name, this
// returns the file name. For a path to a directory, this returns the directory
// name. If the path consists solely of the target's path separator, a string of
// the path is returned unmodified. If the path is empty, "." is returned. The
// return value is either borrowed from the input or statically allocated; use
// [[strings::dup]] to extend its lifetime or modify it.
export fn basename(path: (str | *buffer)) const str = {
	let path = getstring(path);
	if (path == "") {
		return ".";
	};
	let trimmed = strings::rtrim(path, PATHSEP: u32: rune);
	if (trimmed == "") {
		return "/";
	};
	let b = strings::toutf8(trimmed);
	let i = match (bytes::rindex(b, PATHSEP)) {
	case void =>
		return trimmed;
	case let z: size =>
		yield if (z + 1 < len(b)) z + 1z else 0z;
	};
	return strings::fromutf8_unsafe(b[i..]);
};

@test fn basename() void = {
	assert(basename("/foo/bar") == "bar");
	assert(basename("/foo") == "foo");
	assert(basename("/") == "/");
	assert(basename("//") == "/");
	assert(basename("///") == "/");
	assert(basename("foo/bar") == "bar");
	assert(basename("foo/bar//") == "bar");
	assert(basename("foo") == "foo");
};

// Returns the file name and extension for a path. The return value is borrowed
// from the input, see [[strings::dup]] to extend its lifetime.
//
// The extension includes the '.' character.
//
// 	extension("foo/example") => ("example", "")
// 	extension("foo/example.txt") => ("example", ".txt")
// 	extension("foo/example.tar.gz") => ("example", ".tar.gz")
export fn extension(p: (str | *buffer)) (str, str) = {
	let p = getstring(p);
	if (p == "") {
		return ("", "");
	};
	let p = basename(p);
	let b = strings::toutf8(p);
	if (len(b) == 0 || b[len(b) - 1] == PATHSEP) {
		return (p, "");
	};
	let i = match (bytes::index(b, '.')) {
	case void =>
		return (p, "");
	case let z: size =>
		yield z;
	};
	let e = b[i..];
	let n = b[..i];
	return (strings::fromutf8_unsafe(n), strings::fromutf8_unsafe(e));
};

@test fn extension() void = {
	assert(extension("").0 == "");
	assert(extension("").1 == "");
	assert(extension("foo/bar").0 == "bar");
	assert(extension("foo/bar").1 == "");
	assert(extension("foo/bar.txt").0 == "bar");
	assert(extension("foo/bar.txt").1 == ".txt");
	assert(extension("foo/bar.tar.gz").0 == "bar");
	assert(extension("foo/bar.tar.gz").1 == ".tar.gz");
	assert(extension("foo.bar/baz.ha").0 == "baz");
	assert(extension("foo.bar/baz.ha").1 == ".ha");
};
