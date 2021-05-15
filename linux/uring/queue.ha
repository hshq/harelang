use errors;
use rt;

// TODO: Atomics

// Returns the next available [[sqe]] for this [[io_uring]], or null if the
// queue is full.
export fn get_sqe(ring: *io_uring) nullable *sqe = {
	const sq = ring.sq;
	const head = *sq.khead, next = sq.sqe_tail + 1;
	if (next - head <= *sq.kring_entries) {
		let sqe = &sq.sqes[sq.sqe_tail & *sq.kring_mask];
		sq.sqe_tail = next;
		return sqe;
	};
	return null;
};

// Like [[get_sqe]], but aborts the program if the queue is full.
export fn must_get_sqe(ring: *io_uring) *sqe = {
	return match (get_sqe(ring)) {
		sq: *sqe => sq,
		null => abort("I/O submission queue full"),
	};
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
) (nullable *cqe | errors::opaque) = {
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
				// TODO: EAGAIN
				abort();
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
