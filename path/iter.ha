use bytes;
use strings;

const pathsep: []u8 = [PATHSEP];

export type iflags = enum uint {
	NONE = 0,
	STRING = 1 << 0,
	ABSOLUTE = 1 << 1,
};

// An iterator which yields each component of a path.
export type iterator = struct {
	tok: bytes::tokenizer,
	flags: iflags,
};

// Returns an iterator which yields each component of a path. If the path is
// absolute, the first component will be the root path (e.g. /).
export fn iter(path: path) iterator = {
	let flags = iflags::NONE;
	if (path is str) {
		flags |= iflags::STRING;
	};

	let pb = pathbytes(path);
	if (len(pb) > 0 && pb[0] == PATHSEP) {
		flags |= iflags::ABSOLUTE;
		pb = pb[1..];
	};
	if (len(pb) > 1 && pb[len(pb) - 1] == PATHSEP) {
		pb = pb[..len(pb) - 1];
	};

	return iterator {
		tok = bytes::tokenize(pb, pathsep),
		flags = flags,
	};
};

// Returns the next path component from an iterator, or void if none remain.
export fn next(iter: *iterator) (path | void) = {
	if (iter.flags & iflags::ABSOLUTE == iflags::ABSOLUTE) {
		iter.flags &= ~iflags::ABSOLUTE;
		static assert(PATHSEP <= 0x7F);
		return strings::from_utf8_unsafe(pathsep);
	};
	return match (bytes::next_token(&iter.tok)) {
		void => void,
		b: []u8 => if (iter.flags & iflags::STRING == iflags::STRING)
			strings::from_utf8_unsafe(b)
		else b,
	};
};

@test fn iter() void = {
	assert(PATHSEP == '/': u32: u8); // meh
	let i = iter("/foo/bar/baz");
	assert(equal(next(&i) as path, "/"));
	assert(equal(next(&i) as path, "foo"));
	assert(equal(next(&i) as path, "bar"));
	assert(equal(next(&i) as path, "baz"));
	assert(next(&i) is void);
	let i = iter("foo/bar/baz/");
	assert(equal(next(&i) as path, "foo"));
	assert(equal(next(&i) as path, "bar"));
	assert(equal(next(&i) as path, "baz"));
	assert(next(&i) is void);
	let i = iter("foo");
	assert(equal(next(&i) as path, "foo"));
	assert(next(&i) is void);

	let i = iter("/");
	assert(equal(next(&i) as path, "/"));
	assert(next(&i) is void);
};
