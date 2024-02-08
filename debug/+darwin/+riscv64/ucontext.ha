// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Returns the stack pointer from a ucontext.
fn uctx_sp(uctx: *opaque) uintptr = {
	const uctx = uctx: *rt::ucontext;
	return uctx.uc_mcontext.mc_gpregs.gp_sp: uintptr;
};

// Returns the instruction pointer from a ucontext.
fn uctx_ip(uctx: *opaque) uintptr = {
	const uctx = uctx: *rt::ucontext;
	return uctx.uc_mcontext.mc_gpregs.gp_sepc: uintptr;
};

// Returns the current call frame from a ucontext.
fn uctx_frame(uctx: *opaque) stackframe = {
	const uctx = uctx: *rt::ucontext;
	return *(uctx.uc_mcontext.mc_gpregs.gp_s[0]: uintptr: *stackframe);
};
