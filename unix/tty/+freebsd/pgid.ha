// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use os::exec;
use rt;

// Sets the process group on the foreground of this terminal.
export fn tcsetpgrp(fd: io::file, pg: exec::process) (void | errors::error) = {
	match (rt::ioctl(fd, rt::TIOCSPGRP, pg: u64)) {
	case int => void;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
