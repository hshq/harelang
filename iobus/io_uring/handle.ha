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

// Discards states associated with an [[result]].
export fn done(bus: *bus, res: result) void = {
	const handle = handleof(res);
	free(handle.callbacks);
	io_uring::cqe_seen(&bus.uring, res);
};
