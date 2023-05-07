// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
use bytes;
use errors;
use strings;

// Joins path elements onto the end of a path buffer.
// Returns the new string value of the path.
export fn push(buf: *buffer, items: str...) (str | errors::overflow) = {
	for (let i = 0z; i < len(items); i += 1) {
		const elem = strings::toutf8(items[i]);
		const tok = bytes::tokenize(elem, pathsep);
		for (let j = 0z; true; j += 1) {
			const next = match (bytes::next_token(&tok)) {
			case let tok: []u8 =>
				yield tok;
			case void =>
				break;
			};
			if (len(next) == 0 && j == 0) {
				// Handles the push("/foo") case as
				// push("/", "foo");
				appendnorm(buf, pathsepstr)?;
			};
			appendnorm(buf, next)?;
		};
	};
	return string(buf);
};

@test fn push() void = {
	let buf = init()!;
	push(&buf, "foo", "bar", "baz")!;
	let s = strings::join(pathsepstr, "foo", "bar", "baz");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	s = strings::join(pathsepstr, "", "foo", "bar");
	push(&buf, s, "baz")!;
	free(s);
	s = strings::join(pathsepstr, "", "foo", "bar", "baz");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	s = strings::join(pathsepstr, "foo", "bar");
	push(&buf, pathsepstr, s, "baz")!;
	free(s);
	s = strings::join(pathsepstr, "", "foo", "bar", "baz");
	assert(string(&buf) == s);
	free(s);

	buf.end = 0;
	s = strings::join(pathsepstr, ".", "foo", "bar");
	push(&buf, s)!;
	free(s);
	s = strings::join(pathsepstr, "foo", "bar");
	assert(string(&buf) == s);
	free(s);
};

// Remove and return the final path segment in a buffer.
// Returns void if the path is empty or is the root dir.
export fn pop(buf: *buffer) (str | void) = {
	let trimmed = bytes::rtrim(buf.buf[..buf.end], PATHSEP);
	if (len(trimmed) == 0) return void;
	match (bytes::rindex(trimmed, PATHSEP)) {
	case void =>
		defer buf.end = 0;
		return strings::fromutf8_unsafe(buf.buf[..buf.end]);
	case let i: size =>
		defer buf.end = i+1;
		return strings::fromutf8_unsafe(buf.buf[i+1..buf.end]);
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

	// relative dir
	buf.end = 0;
	push(&buf, "foo/")!;
	assert(pop(&buf) as str == "foo/");
	assert(string(&buf) == ".");

	// abs dir
	buf.end = 0;
	push(&buf, pathsepstr, "foo/")!;
	assert(pop(&buf) as str == "foo/");
	assert(string(&buf) == pathsepstr);
};

// Joins a list of path components together, normalizes it, and returns the
// resulting string. The caller must free the return value. If the resulting
// path would exceed [[PATH_MAX]], the program aborts.
export fn join(items: str...) str = {
	static let buf = buffer { ... };
	return strings::dup(set(&buf, items...)!);
};
