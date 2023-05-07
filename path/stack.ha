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

// Joins a list of path components together, normalizes it, and returns the
// resulting string. The caller must free the return value. If the resulting
// path would exceed [[PATH_MAX]], the program aborts.
export fn join(items: str...) str = {
	static let buf = buffer { ... };
	return strings::dup(set(&buf, items...)!);
};
