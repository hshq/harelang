// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use os;
use rt;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	let wsz = rt::winsize { ... };
	match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *opaque)) {
	case let e: rt::errno =>
		return false;
	case let r: int =>
		return r == 0;
	};
};
