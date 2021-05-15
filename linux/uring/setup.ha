use errors;
use rt;


// Sets up an io_uring. The params parameter must be initialized with the
// desired flags, sq_thread_cpu, and sq_thread_idle parameters; the remaining
// fields are initialized by the kernel.
export fn setup(entries: u32, params: *params) (io_uring | error) = {
	const fd = match (rt::io_uring_setup(entries, params)) {
		err: rt::errno => return errors::errno(err),
		fd: int => fd,
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
		err: rt::errno => return errors::errno(err),
		ptr: *void => ptr,
	};

	cq.ring_ptr = if (uring.features & features::SINGLE_MMAP == features::SINGLE_MMAP) {
		sq.ring_ptr;
	} else match (rt::mmap(null, cq.ring_sz,
			rt::PROT_READ | rt::PROT_WRITE,
			rt::MAP_SHARED | rt::MAP_POPULATE,
			fd, OFF_CQ_RING)) {
		err: rt::errno => return errors::errno(err),
		ptr: *void => ptr,
	};

	const ring_ptr = sq.ring_ptr: uintptr;
	sq.khead = (ring_ptr + params.sq_off.head: uintptr): *uint;
	sq.ktail = (ring_ptr + params.sq_off.tail: uintptr): *uint;
	sq.kring_mask = (ring_ptr + params.sq_off.ring_mask: uintptr): *uint;
	sq.kring_entries = (ring_ptr + params.sq_off.ring_entries: uintptr): *uint;
	sq.kflags = (ring_ptr + params.sq_off.flags: uintptr): *sqring_flags;
	sq.kdropped = (ring_ptr + params.sq_off.dropped: uintptr): *uint;
	sq.array = (ring_ptr + params.sq_off.array: uintptr): *uint;
	sq.sqes = match (rt::mmap(null,
			params.sq_entries * size(sqe),
			rt::PROT_READ | rt::PROT_WRITE,
			rt::MAP_SHARED | rt::MAP_POPULATE,
			fd, OFF_SQES)) {
		err: rt::errno => return errors::errno(err),
		ptr: *void => ptr: *[*]sqe,
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
