// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type ucontext = struct {
	uc_sigmask: sigset,
	uc_mcontext: mcontext,
	uc_link: *ucontext,
	uc_stack: stack_t,
	uc_flags: int,
	__spare__: [4]int,
};

export type mcontext = struct {
	mc_gpregs: gpregs,
	mc_fpregs: fpregs,
	mc_flags: int,
	mc_pad: int,
	mc_spare: [8]u64,
};

export type gpregs = struct {
	gp_x: [30]u64,
	gp_lr: u64,
	gp_sp: u64,
	gp_elr: u64,
	gp_spsr: u64,
	gp_pad: int,
};

export type fpregs = struct {
	fp_q: [64]u64, // XXX: Contains 32 128-bit integers
	fp_sr: u32,
	fp_cr: u32,
	fp_flags: int,
	fp_pad: int,
};
