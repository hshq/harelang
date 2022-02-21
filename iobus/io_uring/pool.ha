// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use linux::io_uring;

export type pool = struct {
	bus: *bus,
	buffer: []u8,
	bufsz: size,
	nbuf: size,
	group: u16,
};

export type buffer = u16;

// Creates a new buffer pool for use with read operations. The user can request
// pool use for an I/O request via [[setpool]], and the host will select a
// suitable buffer from the pool to perform the read request. The selected
// buffer can be determined from the [[result]] using [[getbuffer]]. The user
// should, after processing the results of the I/O operation, return the buffer
// to the pool with [[release]]. If no buffers were available, [[endread]] (or
// whichever "end" function is appropriate) will return [[nobuffers]]; in this
// case the user should release some buffers and re-submit the read later.
//
// The utility of this functionality is that the user may submit more reads than
// they have buffers allocated. For instance, a network server may allocate a
// pool of X buffers for reads, and submit reads for Y client connections, where
// X < Y. This allows the server software to support more connections without a
// corresponding increase in RAM utilization, albiet at the cost of limiting
// active connections to the number of available buffers.
//
// The buffer argument must be a slice whose length is divisible by bufsz, thus
// providing a buffer pool of N buffers where N is len(buffer) / bufsz.
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
//
// Note that I/O operations which completed with an error condition will not
// have a buffer assigned, even if [[setpool]] was called for the original
// handle. You must thus test for errors prior to calling [[getbuffer]], or risk
// causing an assertion failure.
export fn getbuffer(pool: *pool, result: result) (buffer, []u8) = {
	let buf: buffer = io_uring::get_buffer_id(result);
	return (buf, pool.buffer[(buf * pool.bufsz)..((buf + 1) * pool.bufsz)]);
};

// Returns a buffer from [[getbuffer]] back to the buffer pool for future reads.
export fn release(pool: *pool, buf: buffer) (void | queuefull) = {
	let sqe = getsqe(pool.bus)?;
	io_uring::provide_buffers(sqe, pool.group,
		pool.buffer[(buf * pool.bufsz)..((buf + 1) * pool.bufsz)],
		1, pool.bufsz, buf);
	io_uring::set_user(sqe, &internal_sqe);
};
