// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// #define __ADDR_BND_PKEY_PAD (_Alignof(void *) < sizeof(short) ? sizeof(short) : _Alignof(void *))
def __ADDR_BND_PKEY_PAD: size = 8;

// Returns the new PID to the parent, void to the child, or errno if something
// goes wrong.
export fn clone(
	stack: nullable *opaque,
	flags: int,
	parent_tid: nullable *int,
	child_tid: nullable *int,
	tls: u64,
) (int | void | errno) = {
	match (wrap_return(syscall5(SYS_clone,
		flags: u64, stack: uintptr: u64,
		parent_tid: uintptr: u64,
		tls, child_tid: uintptr: u64))) {
	case let u: u64 =>
		switch (u) {
		case 0 =>
			return;
		case =>
			return u: int;
		};
	case let err: errno =>
		return err;
	};
};

export def O_DIRECTORY: int = 0o200000;
export def O_DIRECT: int = 0o40000;

export type cmsghdr = struct {
	cmsg_len: socklen_t,
	_padding: int,
	cmsg_level: int,
	cmsg_type: int,
};

export def EDEADLOCK: int = EDEADLK;

export type epoll_event = struct {
	events: u32,
	data: epoll_data,
};

export type cpu_set = struct {
	__bits: [16]u64,
};
