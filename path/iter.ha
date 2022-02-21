// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use strings;

export type iflags = enum uint {
	NONE = 0,
	ABSOLUTE = 1 << 0,
};

export type iterator = struct {
	tok: bytes::tokenizer,
	flags: iflags,
};

let pathsep: []u8 = [PATHSEP];

// Returns an iterator which yields each component of a path. If the path is
// absolute, the first component will be the root path (e.g. "/").
export fn iter(path: (str | *buffer)) iterator = {
	let path = getbytes(path);
	let flags = iflags::NONE;
	if (len(path) > 0 && path[0] == PATHSEP) {
		flags |= iflags::ABSOLUTE;
		path = path[1..];
	};
	if (len(path) > 1 && path[len(path) - 1] == PATHSEP) {
		path = path[..len(path) - 1];
	};

	return iterator {
		tok = bytes::tokenize(path, pathsep),
		flags = flags,
	};
};

// Returns the next path component from an iterator, or void if none remain.
export fn next(iter: *iterator) (str | void) = {
	if (iter.flags & iflags::ABSOLUTE == iflags::ABSOLUTE) {
		iter.flags &= ~iflags::ABSOLUTE;
		static assert(PATHSEP <= 0x7F);
		return strings::fromutf8_unsafe(pathsep);
	};
	match (bytes::next_token(&iter.tok)) {
	case let b: []u8 =>
		return strings::fromutf8_unsafe(b);
	case void => void;
	};
};

@test fn iter() void = {
	assert(PATHSEP == '/': u32: u8); // meh
	let i = iter("/foo/bar/baz");
	assert(next(&i) as str == "/");
	assert(next(&i) as str == "foo");
	assert(next(&i) as str == "bar");
	assert(next(&i) as str == "baz");
	assert(next(&i) is void);
	let i = iter("foo/bar/baz/");
	assert(next(&i) as str == "foo");
	assert(next(&i) as str == "bar");
	assert(next(&i) as str == "baz");
	assert(next(&i) is void);
	let i = iter("foo");
	assert(next(&i) as str == "foo");
	assert(next(&i) is void);

	let i = iter("/");
	assert(next(&i) as str == "/");
	assert(next(&i) is void);
};
