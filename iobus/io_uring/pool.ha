use linux::io_uring;

export type pool = struct {
	bus: *bus,
	buffer: []u8,
	bufsz: size,
	nbuf: size,
	group: u16,
};

export type buffer = u16;

// Creates a new buffer pool for use with read operations. The buffer argument
// must be a slice whose length is divisible by bufsz, thus providing a buffer
// pool of N buffers where N is len(buffer) / bufsz.
export fn newpool(
	bus: *bus,
	buffer: []u8,
	bufsz: size,
) (pool | queuefull) = {
	// XXX: If there's an error with the CQE, it will cause an assertion
	// failure later, which is lame as hell. We should change this to return
	// the handle and let the user run it through their bus normally.
	assert(len(buffer) % bufsz == 0, "Invalid buffer pool size");
	const nbuf = len(buffer) / bufsz;
	const group = bus.nextgroup;
	bus.nextgroup += 1;

	let sqe = getsqe(bus)?;
	io_uring::provide_buffers(sqe, group, buffer, nbuf, bufsz, 0);
	io_uring::set_user(sqe, &internal_sqe);
	return pool {
		bus = bus,
		buffer = buffer,
		bufsz = bufsz,
		nbuf = nbuf,
		group = group,
	};
};

// Configures an operation to use a [[pool]].
export fn setpool(handle: *handle, pool: pool) void = {
	io_uring::set_buffer_select(handle.sqe, pool.group);
	// XXX: Is this always right?
	handle.sqe.length = pool.bufsz: u32;
};

// Returns the buffer used by a [[handle]] configured with [[setpool]]. The
// caller should provide the buffer from the return value to [[release]] when
// done to return it to the host for future requests. After calling [[release]],
// the slice reference is no longer valid.
export fn getbuffer(pool: *pool, result: result) (buffer, []u8) = {
	let buf: buffer = io_uring::get_buffer_id(result);
	return (buf, pool.buffer[(buf * pool.bufsz)..((buf + 1) * pool.bufsz)]);
};

// Returns a buffer from [[getbuffer]] back to the buffer pool.
export fn release(pool: *pool, buf: buffer) (void | queuefull) = {
	let sqe = getsqe(pool.bus)?;
	io_uring::provide_buffers(sqe, pool.group,
		pool.buffer[(buf * pool.bufsz)..((buf + 1) * pool.bufsz)],
		1, pool.bufsz, buf);
	io_uring::set_user(sqe, &internal_sqe);
};
