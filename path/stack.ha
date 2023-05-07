// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
use bytes;
use strings;

// Appends path elements onto the end of a path buffer.
// Returns the new string value of the path.
export fn push(buf: *buffer, items: str...) (str | error) = {
	for (let i = 0z; i < len(items); i += 1) {
		let elem = strings::toutf8(items[i]);
		for (true) match (bytes::index(elem, PATHSEP)) {
		case void =>
			buf.end = appendnorm(buf, elem)?;
			break;
		case let j: size =>
			if (j == 0 && buf.end == 0) {
				buf.buf[0] = PATHSEP;
				buf.end = 1;
			} else {
				buf.end = appendnorm(buf, elem[..j])?;
			};
			elem = elem[j+1..];
		};
	};
	return string(buf);
};

const dot: []u8 = ['.'];
const dotdot: []u8 = ['.', '.'];

// append a path segment to a buffer, preserving normalization.
// seg must not contain any PATHSEPs. if you need to make the path
// absolute, you should do that manually. returns the new end of the buffer.
// x    +    => x
// x    + .  => x
// /    + .. => /
//      + .. => ..
// x/.. + .. => x/../..
// x/y  + .. => x
// x    + y  => x/y
fn appendnorm(buf: *buffer, seg: []u8) (size | error) = {
	if (len(seg) == 0 || bytes::equal(dot, seg)) return buf.end;
	if (bytes::equal(dotdot, seg)) {
		if (isroot(buf)) return buf.end;
		const isep = match (bytes::rindex(buf.buf[..buf.end], PATHSEP)) {
		case void => yield 0z;
		case let i: size => yield i + 1;
		};
		if (buf.end == 0 || bytes::equal(buf.buf[isep..buf.end], dotdot)) {
			return appendlit(buf, dotdot)?;
		} else {
			return if (isep <= 1) isep else isep - 1;
		};
	} else {
		return appendlit(buf, seg)?;
	};
};

// append a segment to a buffer, *without* preserving normalization.
// returns the new end of the buffer
fn appendlit(buf: *buffer, bs: []u8) (size | error) = {
	let newend = buf.end;
	if (buf.end == 0 || isroot(buf)) {
		if (PATH_MAX < buf.end + len(bs)) return too_long;
	} else {
		if (PATH_MAX < buf.end + len(bs) + 1) return too_long;
		buf.buf[buf.end] = PATHSEP;
		newend += 1;
	};
	buf.buf[newend..newend+len(bs)] = bs;
	return newend + len(bs);
};


@test fn push() void = {
	let buf = init()!;
	assert(string(&buf) == ".");

	// current dir invariants
	assert(push(&buf, "")! == ".");
	assert(push(&buf, ".")! == ".");

	// parent dir invariants
	assert(push(&buf, "..")! == "..");
	assert(push(&buf, "")! == "..");
	assert(push(&buf, ".")! == "..");
	assert(push(&buf, pathsepstr)! == "..");

	assert(set(&buf)! == ".");
	// root dir invariants
	assert(push(&buf, pathsepstr)! == pathsepstr);
	assert(push(&buf, "")! == pathsepstr);
	assert(push(&buf, ".")! == pathsepstr);
	assert(push(&buf, "..")! == pathsepstr);
	assert(push(&buf, pathsepstr)! == pathsepstr);

	assert(set(&buf)! == ".");
	// regular path and parent
	assert(push(&buf, "foo")! == "foo");
	assert(push(&buf, ".")! == "foo");
	assert(push(&buf, pathsepstr)! == "foo");
	assert(push(&buf, "..")! == ".");

	// multiple segments
	push(&buf, "a", "b")!;
	assert(bytes::equal(buf.buf[..buf.end], ['a', PATHSEP, 'b']));
	push(&buf, "..", "c")!;
	assert(bytes::equal(buf.buf[..buf.end], ['a', PATHSEP, 'c']));
	assert(push(&buf, "..")! == "a");
	push(&buf, strings::fromutf8([PATHSEP, 'd'])!)!;
	assert(bytes::equal(buf.buf[..buf.end], ['a', PATHSEP, 'd']));
	assert(push(&buf, "..", "..")! == ".");

	// multiple segments, absolute
	push(&buf, pathsepstr, "a", "b")!;
	assert(bytes::equal(buf.buf[..buf.end], [PATHSEP, 'a', PATHSEP, 'b']));
	push(&buf, "..", "c")!;
	assert(bytes::equal(buf.buf[..buf.end], [PATHSEP, 'a', PATHSEP, 'c']));
	push(&buf, "..")!;
	assert(bytes::equal(buf.buf[..buf.end], [PATHSEP, 'a']));
	push(&buf, strings::fromutf8([PATHSEP, 'd'])!)!;
	assert(bytes::equal(buf.buf[..buf.end], [PATHSEP, 'a', PATHSEP, 'd']));
	assert(push(&buf, "..", "..", "..")! == pathsepstr);
};

// Examine the final path segment in a buffer.
// Returns void if the path is empty or is the root dir.
export fn peek(buf: *const buffer) (str | void) = split(buf).1;

// Remove and return the final path segment in a buffer.
// Returns void if the path is empty or is the root dir.
export fn pop(buf: *buffer) (str | void) = {
	const (end, res) = split(buf);
	buf.end = end;
	return res;
};

// helper function for pop/peek, returns (new end of buffer, result)
fn split(buf: *buffer) (size, (str | void)) = {
	if (buf.end == 0 || isroot(buf)) return (buf.end, void);
	match (bytes::rindex(buf.buf[..buf.end], PATHSEP)) {
	case void =>
		return (0z, strings::fromutf8_unsafe(buf.buf[..buf.end]));
	case let i: size =>
		return (
			if (i == 0) 1z else i,
			strings::fromutf8_unsafe(buf.buf[i+1..buf.end]),
		);
	};
};

@test fn pop() void = {
	// empty
	let buf = init()!;
	assert(pop(&buf) is void);
	assert(string(&buf) == ".");

	// root dir
	buf.end = 0;
	push(&buf, pathsepstr)!;
	assert(pop(&buf) is void);
	assert(string(&buf) == pathsepstr);

	// relative file
	buf.end = 0;
	push(&buf, "foo")!;
	assert(pop(&buf) as str == "foo");
	assert(string(&buf) == ".");

	// abs file
	buf.end = 0;
	push(&buf, pathsepstr, "foo")!;
	assert(pop(&buf) as str == "foo");
	assert(string(&buf) == pathsepstr);
};

// Joins a list of path components together, normalizes it, and returns the
// resulting string. The caller must free the return value. If the resulting
// path would exceed [[PATH_MAX]], the program aborts.
export fn join(items: str...) str = {
	static let buf = buffer { ... };
	return strings::dup(set(&buf, items...)!);
};

// Returns the parent directory for a given path, without modifying the buffer.
// If the path is the root directory, the root directory is returned. The value
// is either borrowed from the input or statically allocated; use
// [[strings::dup]] to extend its lifetime or modify it.
export fn parent(buf: *const buffer) (str | error) = {
	const newend = appendnorm(buf, dotdot)?;
	if (newend == 0) return ".";
	return strings::fromutf8_unsafe(buf.buf[..newend]);
};
