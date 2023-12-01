// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Values for the [[mmap]] prot parameter. Only the EXEC, READ, WRITE, and NONE
// values are portable.
export type prot = enum int {
	NONE = rt::PROT_NONE,
	READ = rt::PROT_READ,
	WRITE = rt::PROT_WRITE,
	EXEC = rt::PROT_EXEC,
};

// Values for the [[mmap]] flags parameter. Only the SHARED, PRIVATE, and FIXED
// values are portable.
export type mflag = enum int {
	SHARED = rt::MAP_SHARED,
	PRIVATE = rt::MAP_PRIVATE,
	FIXED = rt::MAP_FIXED,
	ANON = rt::MAP_ANON,
	STACK = rt::MAP_STACK,
	CONCEAL = rt::MAP_CONCEAL
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
	match (rt::mmap(addr, length, prot, flags, fd, offs: i64)) {
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
