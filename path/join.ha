use bufio;
use strings;
use io;

// Joins together several path components with the path separator. The caller
// must free the return value with [path_free].
export fn join(paths: path...) path = {
	// TODO: Normalize inputs so that if they end with a / we don't double
	// up on delimiters
	let sink = bufio::dynamic();
	let utf8 = true;
	for (let i = 0z; i < len(paths); i += 1) {
		utf8 = utf8 && paths[i] is str;

		let buf = pathbytes(paths[i]);
		let l = len(buf);
		for (l > 0 && buf[l - 1] == PATHSEP) {
			l -= 1;
		};
		if (l == 0) continue;
		for (let q = 0z; q < l) {
			let w = io::write(sink, buf[q..l]) as size;
			q += w;
		};
		if (i + 1 < len(paths)) {
			assert(io::write(sink, [PATHSEP]) as size == 1);
		};
	};

	return
		if (utf8) strings::from_utf8_unsafe(bufio::finish(sink))
		else bufio::finish(sink);
};

@test fn join() void = {
	assert(PATHSEP == '/': u32: u8); // TODO: meh
	let i = join("foo");
	defer path_free(i);
	assert(i as str == "foo");

	let p = join(i, "bar", "baz");
	defer path_free(p);
	assert(p as str == "foo/bar/baz");

	let q = join(p, "bat", "bad");
	defer path_free(q);
	assert(q as str == "foo/bar/baz/bat/bad");

	let r = join(p, q);
	defer path_free(r);
	assert(r as str == "foo/bar/baz/foo/bar/baz/bat/bad");

	let p = join("foo/", "bar");
	defer path_free(p);
	assert(p as str == "foo/bar");

	let p = join("foo///", "bar");
	defer path_free(p);
	assert(p as str == "foo/bar");

	let p = join("foo", "", "bar");
	defer path_free(p);
	assert(p as str == "foo/bar");
};
