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
// the input or statically allocated; use [[strings::dup]] to extend its
// lifetime or modify it.
export fn dirname(path: (str | *buffer)) const str = {
	let path = getstring(path);
	if (path == "") {
		return ".";
	};
	let trimmed = strings::rtrim(path, PATHSEP: u32: rune);
	if (trimmed == "") {
		return pathsepstr;
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
		return pathsepstr;
	};
	return path;
};

@test fn dirname() void = {
	assertpatheql(&dirname, pathsepstr, "", "foo");
	assertpatheql(&dirname, pathsepstr, pathsepstr);
	assertpatheql(&dirname, pathsepstr, "", "", "");
	assertpatheql(&dirname, pathsepstr, "", "", "", "");
	assertpatheql(&dirname, "foo", "foo", "bar");
	assertpatheql(&dirname, ".", "");
	assertpatheql(&dirname, ".", "foo");
	assertpatheql(&dirname, ".", "foo", "");
	assertpatheql(&dirname, ".", "foo", "", "");
	assertpatheql(&dirname, pathsepstr, "", "", "", "foo");
	assertpatheql(&dirname, pathsepstr, "", "", "", "foo", "", "");
	let expected = strings::concat(pathsepstr, "foo");
	assertpatheql(&dirname, expected, "", "foo", "bar");
	free(expected);
	expected = strings::concat(pathsepstr, pathsepstr, "foo");
	assertpatheql(&dirname, expected, "", "", "foo", "", "", "bar", "", "");
	free(expected);
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
		return pathsepstr;
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
	assertpatheql(&basename, "bar", "", "foo", "bar");
	assertpatheql(&basename, "foo", "", "foo");
	assertpatheql(&basename, pathsepstr, pathsepstr);
	assertpatheql(&basename, pathsepstr, "", "", "");
	assertpatheql(&basename, pathsepstr, "", "", "", "");
	assertpatheql(&basename, "bar", "foo", "bar");
	assertpatheql(&basename, "bar", "foo", "bar", "", "");
	assertpatheql(&basename, "foo", "foo");
	assertpatheql(&basename, "foo", "foo", "");
	assertpatheql(&basename, "bar", "foo", "bar", "");
	assertpatheql(&basename, ".", "");
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
	assertpatheql(&ext0, "", "");
	assertpatheql(&ext1, "", "");
	assertpatheql(&ext0, "bar", "foo", "bar");
	assertpatheql(&ext1, "", "foo", "bar");
	assertpatheql(&ext0, "bar", "foo", "bar.txt");
	assertpatheql(&ext1, ".txt", "foo", "bar.txt");
	assertpatheql(&ext0, "bar", "foo", "bar.tar.gz");
	assertpatheql(&ext1, ".tar.gz", "foo", "bar.tar.gz");
	assertpatheql(&ext0, "baz", "foo.bar", "baz.ha");
	assertpatheql(&ext1, ".ha", "foo.bar", "baz.ha");
};

fn assertpatheql(
	func: *fn(path: (str | *buffer)) const str,
	expected: str,
	path: str...
) void = {
	const s = strings::join(pathsepstr, path...);
	assert(func(s) == expected);
	free(s);
};

fn ext0(p: (str | *buffer)) const str = extension(p).0;
fn ext1(p: (str | *buffer)) const str = extension(p).1;
