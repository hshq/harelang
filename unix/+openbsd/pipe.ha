// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;

// Flags to use for the [[io::file]]s returned by [[pipe]].
// Only NOCLOEXEC and NONBLOCK are guaranteed to be available.
export type pipe_flag = enum {
	NOCLOEXEC = rt::O_CLOEXEC,
	NONBLOCK = rt::O_NONBLOCK,
};

// Create a pair of two linked [[io::file]]s, such that any data written to the
// second [[io::file]] may be read from the first.
export fn pipe(flags: pipe_flag = 0) ((io::file, io::file) | errors::error) = {
	let fds: [2]int = [0...];
	flags ^= pipe_flag::NOCLOEXEC; // invert CLOEXEC
	match (rt::pipe2(&fds, flags)) {
	case void => void;
	case let e: rt::errno =>
		return errors::errno(e);
	};
	return (fds[0], fds[1]);
};
