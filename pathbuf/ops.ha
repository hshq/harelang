use bytes;
use errors;
use path;
use strings;

// Joins several path elements together and appends them to a path buffer.
export fn join(buf: *buffer, items: str...) (void | errors::overflow) = {
	for (let i = 0z; i < len(items); i += 1) {
		const elem = strings::toutf8(items[i]);
		const tok = bytes::tokenize(elem, [path::PATHSEP]);
		for (let j = 0z; true; j += 1) {
			const next = match (bytes::next_token(&tok)) {
			case let tok: []u8 =>
				yield tok;
			case void =>
				break;
			};
			if (len(next) == 0 && j == 0) {
				// Handles the join("/foo") case as
				// join("/", "foo");
				appendnorm(buf, "/")?;
			};
			appendnorm(buf, next)?;
		};
	};
};

@test fn join() void = {
	let buf = init();
	join(&buf, "foo", "bar", "baz")!;
	assert(path(&buf) == "foo/bar/baz");

	reset(&buf);
	join(&buf, "/foo/bar", "baz")!;
	assert(path(&buf) == "/foo/bar/baz");

	reset(&buf);
	join(&buf, "/", "foo/bar", "baz")!;
	assert(path(&buf) == "/foo/bar/baz");
};
