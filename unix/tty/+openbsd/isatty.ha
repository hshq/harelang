// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use io;
use os;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	return rt::fcntl(fd, rt::F_ISATTY, 0) is int;
};
