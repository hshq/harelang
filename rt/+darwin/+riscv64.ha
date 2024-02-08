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
	gp_ra: u64,
	gp_sp: u64,
	gp_gp: u64,
	gp_tp: u64,
	gp_t: [7]u64,
	gp_s: [12]u64,
	gp_a: [8]u64,
	gp_sepc: u64,
	gp_sstatus: u64,
};

export type fpregs = struct {
	fp_x: [32][2]u64,
	fp_fcsr: u64,
	fp_flags: int,
	pad: int,
};
