// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: Implement FreeBSD version
use errors;
use rt;

// Flags for the [[mlock]] family of operations.
export type mcl = enum uint {
	CURRENT = 1,
	FUTURE = 2,
	ONFAULT = 4,
};

// Locks a region of memory so that it will not be written to swap.
export fn mlock(
	addr: *opaque,
	length: size,
	flags: mcl,
) (void | errors::error) = {
	match (rt::mlock2(addr, length, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Unlocks memory previously locked with [[mlock]].
export fn munlock(addr: *opaque, length: size) (void | errors::error) = {
	match (rt::munlock(addr, length)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Locks the entire process's address space so that it will not be written to
// swap.
export fn mlockall(flags: mcl) (void | errors::error) = {
	match (rt::mlockall(flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Unlocks all locked memory in the process's address space.
export fn munlockall() (void | errors::error) = {
	match (rt::munlockall()) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};
