use linux::io_uring;

// Registers a callback to occur following the completion of an I/O operation.
// Note that this is generally less efficient than using an internal dispatch in
// your Hare program based on the handle returned from [[dispatch]].
export fn callback(
	op: *handle,
	cb: *fn(res: result, data: *void) void,
	data: *void,
) void = {
	append(op.callbacks, (cb, data));
};

// Returns the [[handle]] which this [[result]] corresponds to.
export fn handleof(res: result) *handle = {
	match (io_uring::get_user(res)) {
	case null =>
		abort("I/O submission was prepared, but not enqueued. Did you pass it to iobus::enqueue or iobus::submit?");
	case v: *void =>
		return v: *handle;
	};
};

// Discards state associated with an [[result]].
export fn done(bus: *bus, res: result) void = {
	const handle = handleof(res);
	free(handle.callbacks);
	io_uring::cqe_seen(&bus.uring, res);
};

// Causes a series of I/O handles to be executed serially, waiting for the Nth
// to complete before starting the N+1th. If any of the I/O operations fail, all
// subsequent I/O handles in the chain will be cancelled, returning
// [[errors::cancelled]]. A short read or write (including [[io::EOF]]) is
// considered a failure for this purpose.
//
// All of the I/O handles must be provided as parameters in the order that they
// were created, and must form a continuous sequence of I/O handles as obtained
// from this bus. Discontinuous sequences are not permitted, such that 'h1 =
// read(); h2 = read(); h3 = read(); serial(h1, h3)' is invalid. This function
// must be called prior to any of the handles being submitted to the bus.
export fn chain(items: *handle...) void = {
	// TODO: Add assertions to enforce the constraints of this function
	for (let i = 0z; i < len(items) - 1; i += 1) {
		items[i].sqe.flags |= io_uring::flags::IO_LINK;
	};
};

// Serialize behaves similarly to [[chain]], except that an error in I/O
// execution does not cause the remainder of the chain to be cancelled. However,
// a poorly formed I/O submission (such as for an invalid file handle) will
// still cause the chain to be cancelled.
export fn serialize(items: *handle...) void = {
	// TODO: Add assertions to enforce the constraints of this function
	for (let i = 0z; i < len(items) - 1; i += 1) {
		items[i].sqe.flags |= io_uring::flags::IO_HARDLINK;
	};
};
