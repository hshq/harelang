// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

def AARCH64_FP: uint = 29; // fp is an alias of r29
def AARCH64_LR: uint = 30; // lr is an alias of r30

// Returns the stack pointer from a ucontext.
fn uctx_sp(uctx: *opaque) uintptr = {
	const uctx = uctx: *rt::ucontext;
	return uctx.sc_sp: uintptr;
};

// Returns the instruction pointer from a ucontext.
fn uctx_ip(uctx: *opaque) uintptr = {
	const uctx = uctx: *rt::ucontext;
	return uctx.sc_elr: uintptr;
};

// Returns the current call frame from a ucontext.
fn uctx_frame(uctx: *opaque) stackframe = {
	const uctx = uctx: *rt::ucontext;
	return *(uctx.sc_x[AARCH64_FP]: uintptr: *stackframe);
};
