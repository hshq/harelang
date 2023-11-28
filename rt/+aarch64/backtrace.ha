// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn getfp() *frame;

// Details for a stack frame. A null address indicates that you've reached the
// top of the stack. Contents are architecture-specific.
export type frame = struct {
	fp: nullable *frame,
	lr: nullable *opaque,
};

// Returns the caller's stack frame. Call [[nextframe]] to walk the stack.
export fn backtrace() frame = *getfp();

// Returns the frame above the current frame. The current frame must contain a
// non-nullable address.
export fn nextframe(sframe: frame) frame = *(sframe.fp as *frame);
