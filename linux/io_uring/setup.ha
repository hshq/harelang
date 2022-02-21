// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use rt;

// Sets up an io_uring. The params parameter must be initialized with the
// desired flags, sq_thread_cpu, and sq_thread_idle parameters; the remaining
// fields are initialized by the kernel.
export fn setup(entries: u32, params: *params) (io_uring | error) = {
	const fd = match (rt::io_uring_setup(entries, params)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	let uring = io_uring {
		sq = sq { ... },
		cq = cq { ... },
		fd = fd,
		flags = params.flags,
		features = params.features,
	};
	let sq = &uring.sq, cq = &uring.cq;

	sq.ring_sz = params.sq_off.array + params.sq_entries * size(uint);
	cq.ring_sz = params.cq_off.cqes + params.cq_entries * size(cqe);

	if (uring.features & features::SINGLE_MMAP == features::SINGLE_MMAP) {
		if (cq.ring_sz > sq.ring_sz) {
			sq.ring_sz = cq.ring_sz;
		};
		cq.ring_sz = sq.ring_sz;
	};

	sq.ring_ptr = match (rt::mmap(null,
			params.sq_off.array + entries * size(u32),
			rt::PROT_READ | rt::PROT_WRITE,
			rt::MAP_SHARED | rt::MAP_POPULATE,
			fd, OFF_SQ_RING)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let ptr: *void =>
		yield ptr;
	};

	cq.ring_ptr = if (uring.features & features::SINGLE_MMAP == features::SINGLE_MMAP) {
		yield sq.ring_ptr;
	} else match (rt::mmap(null, cq.ring_sz,
			rt::PROT_READ | rt::PROT_WRITE,
			rt::MAP_SHARED | rt::MAP_POPULATE,
			fd, OFF_CQ_RING)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let ptr: *void =>
		yield ptr;
	};

	const ring_ptr = sq.ring_ptr: uintptr;
	sq.khead = (ring_ptr + params.sq_off.head: uintptr): *uint;
	sq.ktail = (ring_ptr + params.sq_off.tail: uintptr): *uint;
	sq.kring_mask = (ring_ptr + params.sq_off.ring_mask: uintptr): *uint;
	sq.kring_entries = (ring_ptr + params.sq_off.ring_entries: uintptr): *uint;
	sq.kflags = (ring_ptr + params.sq_off.flags: uintptr): *sqring_flags;
	sq.kdropped = (ring_ptr + params.sq_off.dropped: uintptr): *uint;
	sq.array = (ring_ptr + params.sq_off.array: uintptr): *[*]uint;
	sq.sqes = match (rt::mmap(null,
			params.sq_entries * size(sqe),
			rt::PROT_READ | rt::PROT_WRITE,
			rt::MAP_SHARED | rt::MAP_POPULATE,
			fd, OFF_SQES)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let ptr: *void =>
		yield ptr: *[*]sqe;
	};

	const ring_ptr = cq.ring_ptr: uintptr;
	cq.khead = (ring_ptr + params.cq_off.head: uintptr): *uint;
	cq.ktail = (ring_ptr + params.cq_off.tail: uintptr): *uint;
	cq.kring_mask = (ring_ptr + params.cq_off.ring_mask: uintptr): *uint;
	cq.kring_entries = (ring_ptr + params.cq_off.ring_entries: uintptr): *uint;
	cq.koverflow = (ring_ptr + params.cq_off.overflow: uintptr): *uint;
	cq.cqes = (ring_ptr + params.cq_off.cqes: uintptr): *[*]cqe;

	if (params.cq_off.flags != 0) {
		cq.kflags = (ring_ptr + params.cq_off.flags: uintptr): *cqring_flags;
	};

	return uring;
};

// Frees state associated with an [[io_uring]].
export fn finish(ring: *io_uring) void = {
	let sq = &ring.sq, cq = &ring.cq;
	rt::munmap(sq.ring_ptr, sq.ring_sz): void;
	if (cq.ring_ptr != null: *void && cq.ring_ptr != sq.ring_ptr) {
		rt::munmap(cq.ring_ptr, cq.ring_sz): void;
	};
	rt::close(ring.fd): void;
};
