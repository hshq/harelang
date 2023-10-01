// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Values for the [[mmap]] prot parameter. Only the EXEC, READ, WRITE, and NONE
// values are portable.
export type prot = enum uint {
	NONE = rt::PROT_NONE,
	READ = rt::PROT_READ,
	WRITE = rt::PROT_WRITE,
	EXEC = rt::PROT_EXEC,
	GROWSDOWN = rt::PROT_GROWSDOWN,
	GROWSUP = rt::PROT_GROWSUP,
};

// Values for the [[mmap]] flags parameter. Only the SHARED, PRIVATE, and FIXED
// values are portable.
export type mflag = enum uint {
	SHARED = rt::MAP_SHARED,
	PRIVATE = rt::MAP_PRIVATE,
	SHARED_VALIDATE = rt::MAP_SHARED_VALIDATE,
	FIXED = rt::MAP_FIXED,
	ANON = rt::MAP_ANON,
	NORESERVE = rt::MAP_NORESERVE,
	GROWSDOWN = rt::MAP_GROWSDOWN,
	DENYWRITE = rt::MAP_DENYWRITE,
	EXECUTABLE = rt::MAP_EXECUTABLE,
	LOCKED = rt::MAP_LOCKED,
	POPULATE = rt::MAP_POPULATE,
	NONBLOCK = rt::MAP_NONBLOCK,
	STACK = rt::MAP_STACK,
	HUGETLB = rt::MAP_HUGETLB,
	SYNC = rt::MAP_SYNC,
	FIXED_NOREPLACE = rt::MAP_FIXED_NOREPLACE,
	FILE = rt::MAP_FILE,
	HUGE_SHIFT = rt::MAP_HUGE_SHIFT,
	HUGE_MASK = rt::MAP_HUGE_MASK,
	HUGE_64KB = rt::MAP_HUGE_64KB,
	HUGE_512KB = rt::MAP_HUGE_512KB,
	HUGE_1MB = rt::MAP_HUGE_1MB,
	HUGE_2MB = rt::MAP_HUGE_2MB,
	HUGE_8MB = rt::MAP_HUGE_8MB,
	HUGE_16MB = rt::MAP_HUGE_16MB,
	HUGE_32MB = rt::MAP_HUGE_32MB,
	HUGE_256MB = rt::MAP_HUGE_256MB,
	HUGE_512MB = rt::MAP_HUGE_512MB,
	HUGE_1GB = rt::MAP_HUGE_1GB,
	HUGE_2GB = rt::MAP_HUGE_2GB,
	HUGE_16GB = rt::MAP_HUGE_16GB,
};

// Performs the mmap syscall. Consult your system for documentation on this
// function.
export fn mmap(
	addr: nullable *opaque,
	length: size,
	prot: prot,
	flags: mflag,
	fd: file,
	offs: size
) (*opaque | errors::error) = {
	match (rt::mmap(addr, length, prot, flags, fd, offs)) {
	case let ptr: *opaque =>
		return ptr;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Unmaps memory previously mapped with [[mmap]].
export fn munmap(addr: *opaque, length: size) (void | errors::error) = {
	match (rt::munmap(addr, length)) {
	case void =>
		return;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
