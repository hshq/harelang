// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Mykyta Holubakha <hilobakho@gmail.com>

fn getfp() **void;

// Details for a stack frame. Contents are architecture-specific.
export type frame = struct {
	addr: *void
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
	let addr = sframe.addr: *nullable *void;
	match (*addr) {
	case let a: *void =>
		return frame { addr = a };
	case null =>
		return;
	};
};
