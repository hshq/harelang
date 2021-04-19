use bytes;
use strings;

export type iflags = enum uint {
	NONE = 0,
	ABSOLUTE = 1 << 0,
};

// An iterator which yields each component of a path.
export type iterator = struct {
	tok: bytes::tokenizer,
	flags: iflags,
};

let pathsep: []u8 = [PATHSEP];

// Returns an iterator which yields each component of a path. If the path is
// absolute, the first component will be the root path (e.g. /).
export fn iter(path: str) iterator = {
	let flags = iflags::NONE;
	let pb = strings::toutf8(path);
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
export fn next(iter: *iterator) (str | void) = {
	if (iter.flags & iflags::ABSOLUTE == iflags::ABSOLUTE) {
		iter.flags &= ~iflags::ABSOLUTE;
		static assert(PATHSEP <= 0x7F);
		return strings::fromutf8_unsafe(pathsep);
	};
	return match (bytes::next_token(&iter.tok)) {
		b: []u8 => strings::fromutf8_unsafe(b),
		_: void => void,
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
