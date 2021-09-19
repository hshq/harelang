fn getfp() **void;

// Details for a stack frame. Contents are architecture-specific.
export type frame = struct {
	addr: *void
};

// Returns the current stack frame. See [[nextframe]] to walk the stack.
export fn backtrace() frame = frame {
	addr = getfp()
};

// Returns the frame above the current frame, if any.
export fn nextframe(sframe: frame) (frame | void) = {
	let addr = sframe.addr: *nullable *void;
	return match (*addr) {
		null => void,
		a: *void => frame { addr = a }
	};
};
