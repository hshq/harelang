use io;
use strings;

// Appends zero or more strings to an [io::stream]. The stream needn't be a
// strio stream, but it's often efficient if it is. Returns the number of bytes
// written, or an error.
export fn concat(st: *io::stream, strs: str...) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(strs); i += 1) {
		let q = 0z;
		let buf = strings::to_utf8(strs[i]);
		for (q < len(buf)) {
			let w = io::write(st, buf[q..])?;
			n += w;
			q -= w;
		};
	};
	return n;
};

@test fn concat() void = {
	let st = dynamic();
	defer io::close(st);
	concat(st, "hello") as size;
	concat(st, " ", "world") as size;
	assert(string(st) == "hello world");
};

// Joins several strings together by a delimiter and writes them to a stream.
// The stream needn't be a strio stream, but it's often more efficient if it is.
// Returns the number of bytes written, or an error.
export fn join(st: *io::stream, delim: str, strs: str...) (size | io::error) = {
	let n = 0z;
	let delim = strings::to_utf8(delim);
	for (let i = 0z; i < len(strs); i += 1) {
		let q = 0z;
		let buf = strings::to_utf8(strs[i]);
		for (q < len(buf)) {
			let w = io::write(st, buf[q..])?;
			n += w;
			q -= w;
		};
		if (i + 1 < len(strs)) {
			let q = 0z;
			for (q < len(delim)) {
				let w = io::write(st, delim[q..])?;
				n += w;
				q -= w;
			};
		};
	};
	return n;
};

@test fn join() void = {
	let st = dynamic();
	defer io::close(st);
	join(st, "::", "hello", "world") as size;
	assert(string(st) == "hello::world");
	truncate(st);
	join(st, "::") as size;
	assert(string(st) == "");
	truncate(st);
	join(st, "::", "foo") as size;
	assert(string(st) == "foo");
};
