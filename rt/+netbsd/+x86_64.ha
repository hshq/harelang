// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type siginfo = struct {
	si_signo: int,
	si_errno: int,
	si_code: int,
	si_pid: pid_t,
	si_uid: uid_t,
	si_status: int,
	si_addr: *opaque,
	si_value: sigval,
	_reason: union {
		_fault: struct {
			_trapno: int,
		},
		_timer: struct {
			_timerid: int,
			_overrun: int,
		},
		_mesgq: struct {
			_mqd: int,
		},
		_poll: struct {
			_band: i64,
		},
		__spare__: struct {
			__spare1__: i64,
			__spare2__: [7]int,
		},
	},
};

export type ucontext = struct {
	uc_sigmask: sigset,
	uc_mcontext: mcontext,
	uc_link: *ucontext,
	uc_stack: stack_t,
	uc_flags: int,
	__spare__: [4]int,
};

export type mcontext = struct {
	mc_onstack: u64,
	mc_rdi: u64,
	mc_rsi: u64,
	mc_rdx: u64,
	mc_rcx: u64,
	mc_r8: u64,
	mc_r9: u64,
	mc_rax: u64,
	mc_rbx: u64,
	mc_rbp: u64,
	mc_r10: u64,
	mc_r11: u64,
	mc_r12: u64,
	mc_r13: u64,
	mc_r14: u64,
	mc_r15: u64,
	mc_trapno: u32,
	mc_fs: u16,
	mc_gs: u16,
	mc_addr: u64,
	mc_flags: u32,
	mc_es: u16,
	mc_ds: u16,
	mc_err: u64,
	mc_rip: u64,
	mc_cs: u64,
	mc_rflags: u64,
	mc_rsp: u64,
	mc_ss: u64,
};
