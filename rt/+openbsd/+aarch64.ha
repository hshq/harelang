// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type sigcontext = struct {
	__sc_unused: int,
	sc_mask: int,
	sc_sp: u64,
	sc_lr: u64,
	sc_elr: u64,
	sc_spsr: u64,
	sc_x: [30]u64,
	sc_cookie: u64,
};

export type ucontext = sigcontext;
