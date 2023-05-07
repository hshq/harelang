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
export fn init(items: str...) (buffer | errors::overflow) = {
	let buf = buffer { ... };
	add(&buf, items...)?;
	return buf;
};

// Sets the value of a path buffer to a list of components, overwriting any
// previous value. Returns the new string value of the path.
export fn set(buf: *buffer, items: str...) (str | errors::overflow) = {
	buf.end = 0;
	return add(buf, items...);
};

// Returns the current path stored in this buffer. 
// The return value is borrowed from the buffer. Use [[allocate]] to extend
// the lifetime of the string.
export fn string(buf: *buffer) str = {
	const value = strings::fromutf8_unsafe(buf.buf[..buf.end]);
	if (value == "") {
		return ".";
	};
	return value;
};

// Like [[string]] but the return value is copied to the heap and must be
// freed by the caller.
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
	buf.end = 0;
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
	let buf = init()!;
	assert(string(&buf) == ".");
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	let s = strings::join(pathsepstr, "foo", "bar", "baz");
	assert(string(&buf) == s);
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "bad")!;
	appendnorm(&buf, ".")!;
	free(s);
	s = strings::join(pathsepstr, "foo", "bar", "baz", "bad");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	appendnorm(&buf, pathsepstr)!;
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	appendnorm(&buf, "baz")!;
	s = strings::join(pathsepstr, "", "foo", "bar", "baz");
	assert(string(&buf) == s);
	appendnorm(&buf, pathsepstr)!;
	appendnorm(&buf, pathsepstr)!;
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	appendnorm(&buf, pathsepstr)!;
	appendnorm(&buf, pathsepstr)!;
	appendnorm(&buf, pathsepstr)!;
	assert(string(&buf) == pathsepstr);

	buf.end = 0;
	appendnorm(&buf, ".")!;
	appendnorm(&buf, "foo")!;
	assert(string(&buf) == "foo");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == ".");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");

	buf.end = 0;
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");
	appendnorm(&buf, "..")!;
	s = strings::join(pathsepstr, "..", "..");
	assert(string(&buf) == s);
	free(s);
	appendnorm(&buf, "..")!;
	s = strings::join(pathsepstr, "..", "..", "..");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	appendnorm(&buf, "foo")!;
	appendnorm(&buf, "bar")!;
	s = strings::join(pathsepstr, "foo", "bar");
	assert(string(&buf) == s);
	free(s);
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "foo");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == ".");
	appendnorm(&buf, "..")!;
	assert(string(&buf) == "..");
	appendnorm(&buf, "..")!;
	s = strings::join(pathsepstr, "..", "..");
	assert(string(&buf) == s);
	free(s);

	set(&buf, "foo", "bar")!;
	s = strings::join(pathsepstr, "foo", "bar");
	assert(string(&buf) == s);
	free(s);
	s = strings::concat("bar", pathsepstr);
	set(&buf, "foo", s)!;
	free(s);
	s = strings::join(pathsepstr, "foo", "bar", "");
	assert(string(&buf) == s);
	set(&buf, "foo", "bar", pathsepstr)!;
	assert(string(&buf) == s);
	free(s);
	s = strings::concat(pathsepstr, "baz");
	add(&buf, s)!;
	free(s);
	s = strings::join(pathsepstr, "foo", "bar", "baz");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	appendnorm(&buf, "a")!;
	appendnorm(&buf, "b")!;
	s = strings::join(pathsepstr, "a", "b");
	assert(string(&buf) == s);
	free(s);
};
