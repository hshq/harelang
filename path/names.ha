// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use bytes;
use strings;

// Returns the file name and extension for a path. The return value is borrowed
// from the input, see [[strings::dup]] to extend its lifetime.
//
// The extension includes the '.' character.
//
// 	extension("foo/example") => ("example", "")
// 	extension("foo/example.txt") => ("example", ".txt")
// 	extension("foo/example.tar.gz") => ("example.tar", ".gz")
// this change is only here until the next commit, rebase is annoying
export fn extension(p: str) (str, str) = {
	if (p == "") {
		return ("", "");
	};
	let p = basename(p);
	let b = strings::toutf8(p);
	if (len(b) == 0 || b[len(b) - 1] == PATHSEP) {
		return (p, "");
	};
	let i = match (bytes::rindex(b, '.')) {
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
	assertpatheql(&ext0, "bar.tar", "foo", "bar.tar.gz");
	assertpatheql(&ext1, ".gz", "foo", "bar.tar.gz");
	assertpatheql(&ext0, "baz", "foo.bar", "baz.ha");
	assertpatheql(&ext1, ".ha", "foo.bar", "baz.ha");
};

fn assertpatheql(
	func: *fn(path: str) const str,
	expected: str,
	path: str...
) void = {
	const s = strings::join(pathsepstr, path...);
	assert(func(s) == expected);
	free(s);
};

fn ext0(p: str) const str = extension(p).0;
fn ext1(p: str) const str = extension(p).1;
