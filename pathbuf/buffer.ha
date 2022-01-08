use bytes;
use errors;
use path;
use strings;

export type buffer = struct {
	buf: [path::PATH_MAX]u8,
	cur: []u8,
};

// Initializes a new path buffer.
export fn init() buffer = {
	let buf = buffer { ... };
	reset(&buf);
	return buf;
};

// Initializes a caller-allocated path buffer.
//
// 	let buf = pathbuf::buffer { ... };
// 	pathbuf::init_static(&buf);
export fn init_static(buf: *buffer) void = {
	reset(buf);
};

// Initializes a new path buffer and sets its initial value from a set of path
// components.
export fn initfrom(items: str...) (buffer | errors::overflow) = {
	let buf = buffer { ... };
	reset(&buf);
	join(&buf, items...)?;
	return buf;
};

// Resets a path buffer to its initial state (an empty path).
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

// Like [[dup]], but the new buffer is allocated by the caller.
export fn dup_static(new: *buffer, old: *buffer) void = {
	new.buf[..] = old.buf[..];
	new.cur = old.buf[..0];
};

// Returns the current path stored in this buffer. The path will always be
// normalized, which is to say that it will not include any "." or ".."
// components, or repeated path separators (e.g. "/usr//bin/../bin/./hare"
// becomes "/usr/bin/hare").
export fn path(buf: *buffer) str = {
	return strings::fromutf8_unsafe(buf.cur);
};

// Overwrites the contents of a [[buffer]] with an arbitrary path.
export fn setpath(buf: *buffer, path: str) (void | errors::overflow) = {
	reset(buf);
	join(buf, path)?;
};

// Normalizes and appends a path component to a buffer.
//
// Invariant: elem must either be equal to [path::PATHSEP], or contain no path
// separators.
fn appendnorm(buf: *buffer, elem: (str | []u8)) (void | errors::overflow) = {
	const elem = match (elem) {
	case let elem: []u8 =>
		yield elem;
	case let string: str =>
		yield strings::toutf8(string);
	};
	if (len(elem) == 1 && elem[0] == path::PATHSEP) {
		if (len(buf.cur) == 0) {
			static append(buf.cur, path::PATHSEP);
			return;
		};
		return;
	} else if (bytes::equal(elem, ['.': u8])) {
		return;
	} else if (bytes::equal(elem, ['.': u8, '.': u8])) {
		abort(); // TODO
	};
	if (len(buf.cur) + len(elem) + 1 >= path::PATH_MAX) {
		return errors::overflow;
	};
	if (len(buf.cur) > 1 && buf.cur[len(buf.cur) - 1] != path::PATHSEP) {
		static append(buf.cur, path::PATHSEP);
	};
	static append(buf.cur, elem...);
};

@test fn appendnorm() void = {
	let buf = init();
	assert(path(&buf) == "");
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(path(&buf) == "foo/bar/baz");
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "bad")!;
	appendnorm(&buf, ".")!;
	assert(path(&buf) == "foo/bar/baz/bad");

	let buf = init();
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(path(&buf) == "/foo/bar/baz");
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(path(&buf) == "/foo/bar/baz");

	let buf = init();
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(path(&buf) == "/");
};
