fn getfp() **void;

// Details for a stack frame. Contents are architecture-specific.
export type frame = struct {
	fp: nullable *frame,
	lr: nullable *void,
};

// Returns the caller's stack frame. Call [[nextframe]] to walk the stack.
export fn backtrace() frame = *(getfp(): *frame);

// Returns the frame above the current frame, if any.
export fn nextframe(fp: *frame) (frame | void) = {
	return match (fp.fp) {
		null => void,
		fp: *frame => *fp,
	};
};

