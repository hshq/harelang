use bytes;
use errors;
use strings;

export type buffer = struct {
	buf: [PATH_MAX]u8,
	cur: []u8,
};

// Initializes a new path buffer.
export fn init() buffer = {
	let buf = buffer { ... };
	reset(&buf);
	return buf;
};

// Resets a path buffer to its initial state.
export fn reset(buf: *buffer) void = {
	buf.cur = buf.buf[..0];
};

// Creates a copy of another path buffer, which can be modified without
// affecting the original.
export fn dup(buf: *buffer) buffer = {
	let new = buffer { ... };
	new.buf[..] = buf.buf[..];
	new.cur = new.buf[..0];
	return new;
};

// Returns the current path stored in this buffer. The path will always be
// normalized, which is to say that it will not include any of the following:
//
// - "." components
// - Redundant ".." components
// - Repeated path separators
//
// "/usr//bin/../bin/./hare" becomes "/usr/bin/hare" and "../../foo/bar" is
// unchanged.
export fn string(buf: *buffer) str = {
	return strings::fromutf8_unsafe(buf.cur);
};

// Normalizes and appends a path component to a buffer.
//
// Invariant: elem must either be equal to [PATHSEP], or contain no path
// separators.
fn appendnorm(buf: *buffer, elem: (str | []u8)) (void | errors::overflow) = {
	const elem = match (elem) {
	case let elem: []u8 =>
		yield elem;
	case let string: str =>
		yield strings::toutf8(string);
	};
	if (len(elem) == 1 && elem[0] == PATHSEP) {
		if (len(buf.cur) == 0) {
			static append(buf.cur, PATHSEP);
			return;
		};
		return;
	} else if (bytes::equal(elem, ['.': u8])) {
		return;
	} else if (bytes::equal(elem, ['.': u8, '.': u8])) {
		abort(); // TODO
	};
	if (len(buf.cur) + len(elem) + 1 >= PATH_MAX) {
		return errors::overflow;
	};
	if (len(buf.cur) > 1 && buf.cur[len(buf.cur) - 1] != PATHSEP) {
		static append(buf.cur, PATHSEP);
	};
	static append(buf.cur, elem...);
};

@test fn appendnorm() void = {
	let buf = init();
	assert(string(&buf) == "");
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(string(&buf) == "foo/bar/baz");
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "bad")!;
	appendnorm(&buf, ".")!;
	assert(string(&buf) == "foo/bar/baz/bad");

	let buf = init();
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(string(&buf) == "/foo/bar/baz");
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(string(&buf) == "/foo/bar/baz");

	let buf = init();
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(string(&buf) == "/");
};
