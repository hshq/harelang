// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Values for the [[mmap]] prot parameter. Only the EXEC, READ, WRITE, and NONE
// values are portable.
export type prot = enum uint {
	NONE  = rt::PROT_NONE,
	READ  = rt::PROT_READ,
	WRITE = rt::PROT_WRITE,
	EXEC  = rt::PROT_EXEC,
};

// Values for the [[mmap]] flags parameter. Only the SHARED, PRIVATE, and FIXED
// values are portable.
export type mflag = enum uint {
	SHARED                   = rt::MAP_SHARED,
	PRIVATE                  = rt::MAP_PRIVATE,
	FIXED                    = rt::MAP_FIXED,
	RENAME                   = rt::MAP_RENAME,
	NORESERVE                = rt::MAP_NORESERVE,
	RESERVED0080             = rt::MAP_RESERVED0080,
	NOEXTEND                 = rt::MAP_NOEXTEND,
	HASSEMAPHORE             = rt::MAP_HASSEMAPHORE,
	NOCACHE                  = rt::MAP_NOCACHE,
	JIT                      = rt::MAP_JIT,
	FILE                     = rt::MAP_FILE,
	ANON                     = rt::MAP_ANON,
	ANONYMOUS                = rt::MAP_ANONYMOUS,
	RESILIENT_CODESIGN       = rt::MAP_RESILIENT_CODESIGN,
	RESILIENT_MEDIA          = rt::MAP_RESILIENT_MEDIA,
	TRANSLATED_ALLOW_EXECUTE = rt::MAP_TRANSLATED_ALLOW_EXECUTE,
	UNIX03                   = rt::MAP_UNIX03,
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
