use errors;
use rt;

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
	match (get_cqe(ring, 0, 1)) {
	case err: error =>
		return err;
	case cq: nullable *cqe =>
		assert(cq != null); // XXX: Correct?
		return cq: *cqe;
	};
};

// Peeks the next CQE from the queue and returns it, or null if none are
// pending. The caller must pass the returned CQE to [[cqe_seen]] to advance the
// queue.
export fn peek(ring: *io_uring) (nullable *cqe | error) = get_cqe(ring, 0, 0);

// Returns the result of a [[cqe]], or an error if unsuccessful.
export fn result(cqe: *cqe) (int | error) =
	if (cqe.res < 0) errors::errno(rt::wrap_errno(-cqe.res))
	else cqe.res;

// Gets the user data field of a [[cqe]]. See [[set_user]] for the corresponding
// SQE function.
export fn get_user(cqe: *cqe) nullable *void =
	cqe.user_data: uintptr: nullable *void;

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
		let flags = enter_flags::NONE;

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
		case err: rt::errno =>
			return errors::errno(err);
		case n: uint =>
			submit -= n;
		};
	};
	return cq;
};
