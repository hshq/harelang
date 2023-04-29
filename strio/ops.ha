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
	let tests: [_]([]str, str) = [
		([], ""),
		([""], ""),
		(["", ""], ""),
		(["hello"], "hello"),
		(["hello", " ", "world"], "hello world"),
		(["", "hello", " ", "world"], "hello world"),
		(["hello", " ", "world", ""], "hello world"),
		(["hello", "", " ", "world"], "hello world")
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let ln = concat(&st, tests[i].0...) as size;
		assert(ln == len(tests[i].1) && string(&st) == tests[i].1);
		truncate(&st);
	};
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
	let tests: [_](str, []str, str) = [
		("::", [], ""),
		("::", [""], ""),
		("::", ["", ""], "::"),
		("::", ["", "", ""], "::::"),
		("::", ["hello"], "hello"),
		("::", ["hello", "world"], "hello::world"),
		("::", ["", "hello", "world"], "::hello::world"),
		("::", ["hello", "world", ""], "hello::world::"),
		("::", ["hello", "", "world"], "hello::::world"),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let ln = join(&st, tests[i].0, tests[i].1...) as size;
		assert(ln == len(tests[i].2) && string(&st) == tests[i].2);
		truncate(&st);
	};
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
	let tests: [_](str, []str, str) = [
		("::", [], ""),
		("::", [""], ""),
		("::", ["", ""], "::"),
		("::", ["", "", ""], "::::"),
		("::", ["hello"], "hello"),
		("::", ["hello", "world"], "world::hello"),
		("::", ["", "hello", "world"], "world::hello::"),
		("::", ["hello", "world", ""], "::world::hello"),
		("::", ["hello", "", "world"], "world::::hello"),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let ln = rjoin(&st, tests[i].0, tests[i].1...) as size;
		assert(ln == len(tests[i].2) && string(&st) == tests[i].2);
		truncate(&st);
	};
};

// Appends a rune to a stream.
export fn appendrune(out: io::handle, r: rune) (size | io::error) =
	io::writeall(out, utf8::encoderune(r));
