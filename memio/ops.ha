// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use io;
use strings;

// Appends zero or more strings to an [[io::handle]]. The output needn't be a
// memio stream, but it's generally more efficient if it is. Returns the number
// of bytes written, or an error.
export fn concat(out: io::handle, strs: str...) (size | io::error) =
	join(out, "", strs...);

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
		assert(ln == len(tests[i].1) && string(&st)! == tests[i].1);
		reset(&st);
	};
};

// Joins several strings together by a delimiter and writes them to a handle.
// The output needn't be a memio stream, but it's generally more efficient if it
// is. Returns the number of bytes written, or an error.
export fn join(out: io::handle, delim: str, strs: str...) (size | io::error) = {
	let n = 0z;
	let delim = strings::toutf8(delim);
	for (let i = 0z; i < len(strs); i += 1) {
		n += io::writeall(out, strings::toutf8(strs[i]))?;
		if (len(delim) != 0 && i + 1 < len(strs)) {
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
		assert(ln == len(tests[i].2) && string(&st)! == tests[i].2);
		reset(&st);
	};
};

// Appends zero or more strings to an [[io::handle]], in reverse order. The
// output needn't be a memio stream, but it's generally more efficient if it is.
// Returns the number of bytes written, or an error.
export fn rconcat(out: io::handle, strs: str...) (size | io::error) =
	rjoin(out, "", strs...);

@test fn rconcat() void = {
	let st = dynamic();
	defer io::close(&st)!;
	let tests: [_]([]str, str) = [
		([], ""),
		([""], ""),
		(["", ""], ""),
		(["hello"], "hello"),
		(["hello", " ", "world"], "world hello"),
		(["", "hello", " ", "world"], "world hello"),
		(["hello", " ", "world", ""], "world hello"),
		(["hello", "", " ", "world"], "world hello")
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let ln = rconcat(&st, tests[i].0...) as size;
		assert(ln == len(tests[i].1) && string(&st)! == tests[i].1);
		reset(&st);
	};
};

// Joins several strings together by a delimiter and writes them to a handle, in
// reverse order. The output needn't be a memio stream, but it's generally more
// efficient if it is. Returns the number of bytes written, or an error.
export fn rjoin(out: io::handle, delim: str, strs: str...) (size | io::error) = {
	let n = 0z;
	let delim = strings::toutf8(delim);
	for (let i = len(strs); i > 0; i -= 1) {
		n += io::writeall(out, strings::toutf8(strs[i - 1]))?;
		if (len(delim) != 0 && i - 1 > 0) {
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
		assert(ln == len(tests[i].2) && string(&st)! == tests[i].2);
		reset(&st);
	};
};

// Appends a rune to a stream.
export fn appendrune(out: io::handle, r: rune) (size | io::error) =
	io::writeall(out, utf8::encoderune(r));
