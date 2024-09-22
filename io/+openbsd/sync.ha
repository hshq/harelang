// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Flushes all in-flight I/O for the given file descriptor to persistent
// storage, flushing any writes the kernel has cached, and any changes to the
// corresponding inode.
export fn fsync(fd: file) (void | error) = {
	match (rt::fsync(fd)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Flushes all in-flight I/O for the given file descriptor to persistent
// storage, flushing any writes the kernel has cached. Only persists changes to
// the associated inode if it is not required for the file contents to be
// successfully retrieved. If the file size has changed, for example, this will
// block until the inode is updated; but it would not block on an update to its
// mtime.
export fn fdatasync(fd: file) (void | error) = {
	match (rt::fdatasync(fd)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};
