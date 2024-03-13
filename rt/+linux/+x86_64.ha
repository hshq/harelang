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
		parent_tid: uintptr: u64, child_tid: uintptr: u64,
		tls))) {
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

export type epoll_event = struct @packed {
	// Packed on x86_64
	events: u32,
	data: epoll_data,
};

export type cpu_set = struct {
	__bits: [16]u64,
};

export type ucontext = struct {
	uc_flags: u64,
	uc_link: *ucontext,
	uc_stack: stack_t,
	uc_mcontext: sigcontext,
	uc_sigmask: sigset,
};

export type sigcontext = struct {
	r8: u64,
	r9: u64,
	r10: u64,
	r11: u64,
	r12: u64,
	r13: u64,
	r14: u64,
	r15: u64,
	di: u64,
	si: u64,
	bp: u64,
	bx: u64,
	dx: u64,
	ax: u64,
	cx: u64,
	sp: u64,
	ip: u64,
	flags: u64,
	cs: u16,
	gs: u16,
	fs: u16,
	ss: u16,
	err: u64,
	trapno: u64,
	oldmask: u64,
	cr2: u64,
	fpstate: u64,
	reserved1: [8]u64,
};
