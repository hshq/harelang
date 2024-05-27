// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;

// Flags for [[memfd]].
export type memfd_flag = enum uint {
	NONE = 0,
	// Unsets the close-on-exec flag when creating a memfd.
	NOCLOEXEC = rt::MFD_CLOEXEC,
	// ALlows sealing operations on this file.
	ALLOW_SEALING = rt::MFD_ALLOW_SEALING,
	// Create the memfd with huge pages using hugetlbfs. Linux-only.
	HUGETLB = rt::MFD_HUGETLB,
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
	flags ^= memfd_flag::NOCLOEXEC;
	match (rt::memfd_create(name, flags: uint)) {
	case let i: int =>
		return i: io::file;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
