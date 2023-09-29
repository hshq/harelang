// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use os;

// Returns a stream connected to the TTY of the current process. The caller must
// close it using [[io::close]].
export fn open() (io::file | error) = {
	match (os::open("/dev/tty", fs::flag::RDWR)) {
	case let f: io::file =>
		return f;
	case fs::error =>
		return errors::noentry;
	};
};
