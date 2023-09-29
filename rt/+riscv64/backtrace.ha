// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn getfp() **opaque;

// Details for a stack frame. Contents are architecture-specific.
export type frame = struct {
	addr: *opaque
};

// Returns the current stack frame. See [[nextframe]] to walk the stack.
export fn backtrace() frame = {
	let fp = frame {
		addr = getfp()
	};
	// Skip the call to backtrace itself
	return nextframe(fp) as frame;
};

// Returns the frame above the current frame, if any.
export fn nextframe(sframe: frame) (frame | void) = {
	let addr = sframe.addr: *nullable *opaque;
	match (*addr) {
	case null =>
		return;
	case let a: *opaque =>
		return frame { addr = a };
	};
};
