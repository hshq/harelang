// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use io;
use os;
use strings;

@test fn pty() void = {
	let pty = openpty()!;
	defer io::close(pty.1)!;
	defer io::close(pty.0)!;

	assert(fs::exists(os::cwd, ptsname(pty.0)!));

	for (let i: u16 = 5; i < 100; i += 1) {
		let sz1 = ttysize { rows = i, columns = i };
		set_winsize(pty.1, sz1)!;
		let sz2 = winsize(pty.1)!;
		assert(sz2.rows == sz1.rows);
		assert(sz2.columns == sz1.columns);
	};

	fmt::fprintln(pty.0, "hello, world")!;
	let s = strings::fromutf8(bufio::read_line(pty.1) as []u8)!;
	defer free(s);
	assert(s == "hello, world");
};
