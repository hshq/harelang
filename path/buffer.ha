// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Humm <hummsmith42@gmail.com>
use bytes;
use errors;
use strings;

export type buffer = struct {
	buf: [PATH_MAX]u8,
	end: size,
};

// Initializes a new path buffer.
export fn init() buffer = {
	let buf = buffer { ... };
	reset(&buf);
	return buf;
};

// Resets a path buffer to its initial state.
export fn reset(buf: *buffer) void = {
	buf.end = 0;
};

// Sets the value of a path buffer to a list of components, overwriting any
// previous value. Returns the new string value of the path.
export fn set(buf: *buffer, items: str...) (str | errors::overflow) = {
	reset(buf);
	return add(buf, items...);
};

// Creates a copy of another path buffer, which can be modified without
// affecting the original.
export fn dup(buf: *buffer) buffer = {
	let new = buffer { ... };
	new.buf[..] = buf.buf[..];
	new.end = 0;
	return new;
};

// Returns the current path stored in this buffer. The path will always be
// normalized, which is to say that it will not include any of the following:
//
// - Redundant ".." components
// - Redundant path separators
// - Any "." components, except in the case of "."
//
// "/usr//bin/../bin/./hare" becomes "/usr/bin/hare" and "../../foo/bar" is
// unchanged. The path will only end in a slash if the last item which was
// added ended in "/", like so:
//
// 	let buf = path::init();
// 	path::set(&buf, "foo", "bar")!;
// 	assert(path::string(&buf) == "foo/bar");
//
// 	path::set(&buf, "foo", "bar/")!;
// 	assert(path::string(&buf) == "foo/bar/");
//
// 	path::set(&buf, "foo", "bar", "/")!;
// 	assert(path::string(&buf) == "foo/bar/");
export fn string(buf: *buffer) str = {
	const value = strings::fromutf8_unsafe(buf.buf[..buf.end]);
	if (value == "") {
		return ".";
	};
	return value;
};

// Like [[string]] but the return value is copied to the heap and must be freed
// by the caller.
export fn allocate(buf: *buffer) str = {
	return strings::dup(string(buf));
};

const dot: []u8 = ['.'];
const dotdot: []u8 = ['.', '.'];
const dotdotslash: []u8 = ['.', '.', PATHSEP];

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
		if (buf.end == 0) {
			buf.buf[0] = PATHSEP;
			buf.end += 1;
			return;
		};
		return;
	} else if (bytes::equal(elem, dot)) {
		return;
	} else if (bytes::equal(elem, dotdot)) {
		return parent(buf);
	};
	return doappend(buf, elem);
};

// Moves the buffer to the parent of the current directory.
fn parent(buf: *buffer) (void | errors::overflow) = {
	let ascending = true;
	const iter = iter(buf);
	for (true) {
		match (next(&iter)) {
		case let elem: str =>
			if (elem != "..") {
				ascending = false;
				break;
			};
		case void =>
			break;
		};
	};
	if (ascending) {
		// If we are appending ".." to a path which is entirely composed
		// of ".." elements, then we want to append it normally, so that
		// "../.." becomes "../../.." instead of "..".
		return doappend(buf, dotdot);
	};
	// XXX: This is not super efficient
	const name = dirname(string(buf));
	reset(buf);
	add(buf, name)?;
};

fn doappend(buf: *buffer, elem: []u8) (void | errors::overflow) = {
	if (buf.end + len(elem) + 1 >= PATH_MAX) {
		return errors::overflow;
	};
	if (buf.end > 0 && buf.buf[buf.end - 1] != PATHSEP) {
		buf.buf[buf.end] = PATHSEP;
		buf.end += 1;
	};
	buf.buf[buf.end..buf.end + len(elem)] = elem;
	buf.end += len(elem);
};

@test fn appendnorm() void = {
	let buf = init();
	assert(string(&buf) == ".");
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(string(&buf) == "foo/bar/baz");
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "bad")!;
	appendnorm(&buf, ".")!;
	assert(string(&buf) == "foo/bar/baz/bad");

	reset(&buf);
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	assert(string(&buf) == "/foo/bar/baz");
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(string(&buf) == "/foo/bar/baz");

	reset(&buf);
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	appendnorm(&buf, "/")!;
	assert(string(&buf) == "/");

	reset(&buf);
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "foo")!;
	assert(string(&buf) == "foo");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == ".");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");

	reset(&buf);
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "../..");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "../../..");

	reset(&buf);
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	assert(string(&buf) == "foo/bar");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "foo");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == ".");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "../..");

	set(&buf, "foo", "bar")!;
	assert(string(&buf) == "foo/bar");
	set(&buf, "foo", "bar/")!;
	assert(string(&buf) == "foo/bar/");
	set(&buf, "foo", "bar", "/")!;
	assert(string(&buf) == "foo/bar/");
	add(&buf, "/baz")!;
	assert(string(&buf) == "foo/bar/baz");

	reset(&buf);
	appendnorm(&buf, "a")!;
	appendnorm(&buf, "b")!;
	assert(string(&buf) == "a/b");
};
