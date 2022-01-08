use bytes;
use errors;
use strings;

// Joins several path elements together and copies them into a path buffer.
// Returns the new string value of the path.
export fn add(buf: *buffer, items: str...) (str | errors::overflow) = {
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
				// Handles the add("/foo") case as
				// add("/", "foo");
				appendnorm(buf, "/")?;
			};
			appendnorm(buf, next)?;
		};
	};
	return string(buf);
};

@test fn add() void = {
	let buf = init();
	add(&buf, "foo", "bar", "baz")!;
	assert(string(&buf) == "foo/bar/baz");

	reset(&buf);
	add(&buf, "/foo/bar", "baz")!;
	assert(string(&buf) == "/foo/bar/baz");

	reset(&buf);
	add(&buf, "/", "foo/bar", "baz")!;
	assert(string(&buf) == "/foo/bar/baz");

	reset(&buf);
	add(&buf, "./foo/bar")!;
	assert(string(&buf) == "foo/bar");
};

// Joins a list of path components together, normalizes it, and returns the
// resulting string. The caller must free the return value. If the resulting
// path would exceed [[PATH_MAX]], the program aborts.
export fn join(items: str...) str = {
	static let buf = buffer { ... };
	reset(&buf);
	add(&buf, items...)!;
	return strings::dup(string(&buf));
};
