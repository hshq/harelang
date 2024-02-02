// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type sigcontext = struct {
	sc_rdi: u64,
	sc_rsi: u64,
	sc_rdx: u64,
	sc_rcx: u64,
	sc_r8: u64,
	sc_r9: u64,
	sc_r10: u64,
	sc_r11: u64,
	sc_r12: u64,
	sc_r13: u64,
	sc_r14: u64,
	sc_r15: u64,
	sc_rbp: u64,
	sc_rbx: u64,
	sc_rax: u64,
	sc_gs: u64,
	sc_fs: u64,
	sc_es: u64,
	sc_ds: u64,
	sc_trapno: u64,
	sc_err: u64,
	sc_rip: u64,
	sc_cs: u64,
	sc_rflags: u64,
	sc_rsp: u64,
	sc_ss: u64,

	sc_fpstate: *fxsave64,
	__sc_unused: int,
	sc_mask: int,
	sc_cookie: i64,
};

export type fxsave64 = struct {
	fx_fcw: u16,
	fx_fsw: u16,
	fx_ftw: u8,
	fx_unused1: u8,
	fx_fop: u16,
	fx_rip: u64,
	fx_rdp: u64,
	fx_mxcsr: u32,
	fx_mxcsr_mask: u32,
	fx_st: [8][2]u64,
	fx_xmm: [16][2]u64,
	fx_unused3: [96]u8,
};

export type ucontext = sigcontext;
