// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;

// Flags for [[memfd]].
export type memfd_flag = enum uint {
	NONE = 0,
	// Unsets the close-on-exec flag when creating a memfd.
	NOCLOEXEC = 1,
	// ALlows sealing operations on this file.
	ALLOW_SEALING = 2,
};

// Creates a new anonyomous [[io::file]] backed by memory.
//
// The initial file size is zero. It can be written to normally, or the size can
// be set manually with [[trunc]].
//
// This function is available on Linux and FreeBSD.
export fn memfd(
	name: str,
	flags: memfd_flag = memfd_flag::NONE,
) (io::file | errors::error) = {
	let oflag = rt::O_RDWR | rt::O_CLOEXEC;
	let shm_flag = rt::SHM_GROW_ON_WRITE;
	if (flags & memfd_flag::NOCLOEXEC != 0) {
		oflag &= ~rt::O_CLOEXEC;
	};
	if (flags & memfd_flag::ALLOW_SEALING != 0) {
		shm_flag |= rt::SHM_ALLOW_SEALING;
	};

	match (rt::shm_open(rt::SHM_ANON, oflag, 0, shm_flag, name)) {
	case let fd: int =>
		return fd: io::file;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
