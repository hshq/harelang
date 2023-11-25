// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Lock operation to use with [[lock]].
export type lockop = enum int {
	// shared file lock
	SHARED    = rt::LOCK_SH,
	// exclusive file lock
	EXCLUSIVE = rt::LOCK_EX,
	// unlock file
	UNLOCK    = rt::LOCK_UN,
};

// Apply or remove an advisory lock on an open file. If block is true, the
// request will block while waiting for the lock.
export fn lock(fd: file, block: bool, op: lockop) (bool | error) = {
	let flags = op: int;
	if (!block) flags |= rt::LOCK_NB;
	return fd_lock(fd, flags);
};

// Truncate a file to a specified length. The file must be open for writing.
export fn trunc(fd: file, ln: size) (void | error) = fd_trunc(fd, ln);
