use errors;
use rt;

// TODO: Atomics

// Returns the next available [[sqe]] for this [[io_uring]], or null if the
// queue is full.
export fn get_sqe(ring: *io_uring) nullable *sqe = {
	const sq = &ring.sq;
	const head = *sq.khead, next = sq.sqe_tail + 1;
	if (next - head <= *sq.kring_entries) {
		let sqe = &sq.sqes[sq.sqe_tail & *sq.kring_mask];
		sq.sqe_tail = next;
		return sqe;
	};
	return null;
};

// Returns the next available [[sqe]] for this [[io_uring]], or aborts the
// program if the queue is full.
export fn must_get_sqe(ring: *io_uring) *sqe = match (get_sqe(ring)) {
	null => abort("I/O queue full"),
	sq: *sqe => sq,
};

fn needs_enter(ring: *io_uring, flags: *enter_flags) bool = {
	if (ring.flags & setup_flags::IOPOLL == setup_flags::IOPOLL) {
		return true;
	};

	if (*ring.sq.kflags & sqring_flags::NEED_WAKEUP == sqring_flags::NEED_WAKEUP) {
		*flags |= enter_flags::SQ_WAKEUP;
		return true;
	};

	return false;
};

fn needs_flush(ring: *io_uring) bool =
	*ring.sq.kflags & sqring_flags::CQ_OVERFLOW == sqring_flags::CQ_OVERFLOW;

// Submits queued I/O asynchronously. Returns the number of submissions accepted
// by the kernel.
export fn submit(ring: *io_uring) (uint | errors::opaque) =
	do_submit(ring, flush_sq(ring), 0u);

// Submits queued I/O asynchronously and blocks until at least "wait" events are
// complete. If setup_flags::IOPOLL was configured for this ring, the meaning of
// the "wait" parameter is different: a non-zero value will block until at least
// one event is completed.
//
// Returns the number of submissions accepted by the kernel.
export fn submit_wait(ring: *io_uring, wait: uint) (uint | errors::opaque) =
	do_submit(ring, flush_sq(ring), wait);

fn flush_sq(ring: *io_uring) uint = {
	let sq = &ring.sq;
	let ktail = *sq.ktail;
	const mask = *sq.kring_mask;

	if (sq.sqe_head == sq.sqe_tail) {
		return ktail - *sq.khead;
	};

	for (let n = sq.sqe_tail - sq.sqe_head; n > 0; n -= 1u) {
		sq.array[ktail & mask] = sq.sqe_head & mask;
		ktail += 1u;
		sq.sqe_head += 1u;
	};

	*sq.ktail = ktail;
	return ktail - *sq.khead;
};

fn do_submit(
	ring: *io_uring,
	submitted: uint,
	wait: uint,
) (uint | errors::opaque) = {
	let flags: enter_flags = enter_flags::GETEVENTS;
	if (needs_enter(ring, &flags) || wait != 0) {
		return match (rt::io_uring_enter(ring.fd,
				submitted, wait, flags, null)) {
			err: rt::errno => errors::errno(err),
			n: uint => n,
		};
	} else {
		return submitted;
	};
};

// Advances the completion queue by N items.
export fn cq_advance(ring: *io_uring, n: uint) void = {
	*ring.cq.khead = *ring.cq.khead + n;
};

// Call after processing a [[cqe]]. The cqe is returned to the pool and cannot
// be used by the application again.
export fn cqe_seen(ring: *io_uring, cqe: *cqe) void = cq_advance(ring, 1);

// Waits until a CQE is available, then returns it. The caller must pass the
// returned CQE to [[cqe_seen]] to advance the queue.
export fn wait(ring: *io_uring) (*cqe | error) = {
	return match (get_cqe(ring, 0, 1)) {
		err: error => err,
		cq: nullable *cqe => {
			assert(cq != null); // XXX: Correct?
			cq: *cqe;
		},
	};
};

// Peeks the next CQE from the queue and returns it, or null if none are
// pending. The caller must pass the returned CQE to [[cqe_seen]] to advance the
// queue.
export fn peek(ring: *io_uring) (nullable *cqe | error) = get_cqe(ring, 0, 0);

fn peek_cqe(ring: *io_uring) (nullable *cqe, uint) = {
	let head = *ring.cq.khead;
	let tail = *ring.cq.ktail;
	let mask = *ring.cq.kring_mask;
	let avail = tail - head;
	if (avail == 0) {
		return (null, 0);
	};
	return (&ring.cq.cqes[head & mask], avail);
};

fn get_cqe(
	ring: *io_uring,
	submit: uint,
	wait: uint,
) (nullable *cqe | error) = {
	let cq: nullable *cqe = null;
	for (cq == null) {
		let enter = false, overflow = false;
		let flags: enter_flags = 0;

		// TODO: tuple destructuring
		let tup = peek_cqe(ring);
		let avail = tup.1;
		cq = tup.0;

		if (cq == null && wait == 0 && submit == 0) {
			if (!needs_flush(ring)) {
				return null;
			};
			overflow = true;
		};
		if (wait > avail || overflow) {
			flags |= enter_flags::GETEVENTS;
			enter = true;
		};
		if (submit > 0) {
			needs_enter(ring, &flags);
			enter = true;
		};
		if (!enter) {
			break;
		};

		match (rt::io_uring_enter(ring.fd,
				submit, wait, flags: uint, null)) {
			err: rt::errno => return errors::errno(err),
			n: uint => submit -= n,
		};
	};
	return cq;
};
