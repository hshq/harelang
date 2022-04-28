// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Yasumasa Tada <ytada@spartan.dev>
use encoding::utf8;
use io;
use strings;

// Appends zero or more strings to an [[io::handle]]. The output needn't be a
// strio stream, but it's generally more efficient if it is. Returns the number
// of bytes written, or an error.
export fn concat(out: io::handle, strs: str...) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(strs); i += 1) {
		n += io::writeall(out, strings::toutf8(strs[i]))?;
	};
	return n;
};

@test fn concat() void = {
	let st = dynamic();
	defer io::close(&st)!;
	concat(&st, "hello") as size;
	concat(&st, " ", "world") as size;
	assert(string(&st) == "hello world");
};

// Joins several strings together by a delimiter and writes them to a handle.
// The output needn't be a strio stream, but it's generally more efficient if it
// is. Returns the number of bytes written, or an error.
export fn join(out: io::handle, delim: str, strs: str...) (size | io::error) = {
	let n = 0z;
	let delim = strings::toutf8(delim);
	for (let i = 0z; i < len(strs); i += 1) {
		n += io::writeall(out, strings::toutf8(strs[i]))?;
		if (i + 1 < len(strs)) {
			n += io::writeall(out, delim)?;
		};
	};
	return n;
};

@test fn join() void = {
	let st = dynamic();
	defer io::close(&st)!;
	join(&st, "::", "hello", "world") as size;
	assert(string(&st) == "hello::world");
	truncate(&st);
	join(&st, "::") as size;
	assert(string(&st) == "");
	truncate(&st);
	join(&st, "::", "foo") as size;
	assert(string(&st) == "foo");
};

// Joins several strings together by a delimiter and writes them to a handle, in
// reverse order. The output needn't be a strio stream, but it's generally more
// efficient if it is. Returns the number of bytes written, or an error.
export fn rjoin(out: io::handle, delim: str, strs: str...) (size | io::error) = {
	let n = 0z;
	let delim = strings::toutf8(delim);
	for (let i = len(strs); i > 0; i -= 1) {
		n += io::writeall(out, strings::toutf8(strs[i - 1]))?;
		if (i - 1 > 0) {
			n += io::writeall(out, delim)?;
		};
	};
	return n;
};

@test fn rjoin() void = {
	let st = dynamic();
	defer io::close(&st)!;
	rjoin(&st, "::", "hello", "world") as size;
	assert(string(&st) == "world::hello");
	truncate(&st);
	rjoin(&st, "::") as size;
	assert(string(&st) == "");
	truncate(&st);
	rjoin(&st, "::", "foo") as size;
	assert(string(&st) == "foo");
};

// Appends a rune to a stream.
export fn appendrune(out: io::handle, r: rune) (size | io::error) =
	io::writeall(out, utf8::encoderune(r));
