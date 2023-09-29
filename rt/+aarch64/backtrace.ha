// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn getfp() **opaque;

// Details for a stack frame. Contents are architecture-specific.
export type frame = struct {
	fp: nullable *frame,
	lr: nullable *opaque,
};

// Returns the caller's stack frame. Call [[nextframe]] to walk the stack.
export fn backtrace() frame = *(getfp(): *frame);

// Returns the frame above the current frame, if any.
export fn nextframe(fp: *frame) (frame | void) = {
	return match (fp.fp) {
	case null =>
		yield void;
	case let fp: *frame =>
		yield *fp;
	};
};

