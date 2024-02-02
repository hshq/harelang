// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type sigcontext = struct {
	__sc_unused: int,
	sc_mask: int,

	sc_ra: u64,
	sc_sp: u64,
	sc_gp: u64,
	sc_tp: u64,
	sc_t: [7]u64,
	sc_s: [12]u64,
	sc_a: [8]u64,
	sc_sepc: u64,

	sc_f: [32]u64,
	sc_fcsr: u64,

	sc_cookie: u64,
};

export type ucontext = sigcontext;
