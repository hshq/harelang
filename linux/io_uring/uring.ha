// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021-2022 Eyal Sawady <ecs@d2evs.net>
use errors;

// Returned when buffer pool use was configured for an [[sqe]], but there are no
// buffers available.
export type nobuffers = !void;

// All errors which may be returned by this module.
export type error = !(errors::error | nobuffers);

// Converts an [[error]] into a human-readable string.
export fn strerror(err: error) const str = {
	match (err) {
	case nobuffers =>
		return "Buffer pool exhausted";
	case let err: errors::error =>
		return errors::strerror(err);
	};
};

// The maximum value for the first parameter of [[setup]].
export def MAX_ENTRIES: uint = 4096;

def CQE_BUFFER_SHIFT: u32 = 16;
def OFF_SQ_RING: u64 = 0;
def OFF_CQ_RING: u64 = 0x8000000;
def OFF_SQES: u64 = 0x10000000;

// An io_uring [[sqe]] operation.
export type op = enum u8 {
	NOP,
	READV,
	WRITEV,
	FSYNC,
	READ_FIXED,
	WRITE_FIXED,
	POLL_ADD,
	POLL_REMOVE,
	SYNC_FILE_RANGE,
	SENDMSG,
	RECVMSG,
	TIMEOUT,
	TIMEOUT_REMOVE,
	ACCEPT,
	ASYNC_CANCEL,
	LINK_TIMEOUT,
	CONNECT,
	FALLOCATE,
	OPENAT,
	CLOSE,
	FILES_UPDATE,
	STATX,
	READ,
	WRITE,
	FADVISE,
	MADVISE,
	SEND,
	RECV,
	OPENAT2,
	EPOLL_CTL,
	SPLICE,
	PROVIDE_BUFFERS,
	REMOVE_BUFFERS,
	TEE,
};

// Flags for an [[sqe]].
export type flags = enum u8 {
	NONE = 0,
	// Use fixed fileset
	FIXED_FILE = 1 << 0,
	// Issue after inflight IO
	IO_DRAIN = 1 << 1,
	// Links next sqe
	IO_LINK = 1 << 2,
	// Like LINK, but stronger
	IO_HARDLINK = 1 << 3,
	// Always go async
	ASYNC = 1 << 4,
	// Select buffer from sqe.buf_group
	BUFFER_SELECT = 1 << 5,
};

// Flags for an fsync operation.
export type fsync_flags = enum u32 {
	NONE = 0,
	DATASYNC = 1 << 0,
};

// Flags for a timeout operation.
export type timeout_flags = enum u32 {
	NONE = 0,
	// If set, the timeout will be "absolute", waiting until CLOCK_MONOTONIC
	// reaches the time defined by the timespec. If unset, it will be
	// interpted as a duration relative to the I/O submission.
	ABS = 1 << 0,
	// When combined with [[op::TIMEOUT_REMOVE]], causes the submission to
	// update the timer rather than remove it.
	UPDATE = 1 << 1,
};

// Flags for a splice operation.
export type splice_flags = enum u32 {
	NONE = 0,
	F_FD_IN_FIXED = 1 << 31,
};

// Flags for a [[cqe]].
export type cqe_flags = enum u32 {
	NONE = 0,
	F_BUFFER = 1 << 0,
	F_MORE = 1 << 1,
};

// A submission queue entry.
export type sqe = struct {
	opcode: op,
	flags: flags,
	ioprio: u16,
	fd: i32,
	union {
		off: u64,
		addr2: nullable *void,
	},
	union {
		addr: nullable *void,
		splice_off_in: u64,
	},
	length: u32,
	union {
		rw_flags: int,
		fsync_flags: fsync_flags,
		poll_events: u16,
		poll32_events: u32,
		sync_range_flags: u32,
		msg_flags: int,
		timeout_flags: timeout_flags,
		accept_flags: u32,
		cancel_flags: u32,
		open_flags: u32,
		statx_flags: u32,
		fadvise_advice: u32,
		splice_flags: splice_flags,
	},
	user_data: u64,
	union {
		struct {
			union {
				buf_index: u16,
				buf_group: u16,
			},
			personality: u16,
			splice_fd_in: i32,
		},
		pad2: [3]u64,
	},
};

// A completion queue entry.
export type cqe = struct {
	user_data: u64,
	res: i32,
	flags: cqe_flags,
};

// Filled with the offset for mmap(2)
export type sqring_offsets = struct {
	head: u32,
	tail: u32,
	ring_mask: u32,
	ring_entries: u32,
	flags: u32,
	dropped: u32,
	array: u32,
	resv1: u32,
	resv2: u64,
};

// Flags for the sq ring.
export type sqring_flags = enum u32 {
	NONE = 0,
	// Needs io_uring_enter wakeup
	NEED_WAKEUP = 1 << 0,
	// CQ ring is overflown
	CQ_OVERFLOW = 1 << 1,
};

// Filled with the offset for mmap(2)
export type cqring_offsets = struct {
	head: u32,
	tail: u32,
	ring_mask: u32,
	ring_entries: u32,
	overflow: u32,
	cqes: u32,
	flags: u32,
	resv1: u32,
	resv2: u64,
};

// Flags for the cq ring.
export type cqring_flags = enum u32 {
	NONE = 0,
	EVENTFD_DISABLED = 1 << 0,
};

// Flags for [[setup]].
export type setup_flags = enum u32 {
	NONE = 0,
	// io_context is polled
	IOPOLL = 1 << 0,
	// SQ poll thread
	SQPOLL = 1 << 1,
	// sq_thread_cpu is valid
	SQ_AFF = 1 << 2,
	// App defines CQ size
	CQSIZE = 1 << 3,
	// Clamp SQ/CQ ring sizes
	CLAMP = 1 << 4,
	// Attach to existing wq
	ATTACH_WQ = 1 << 5,
	// Start with ring disabled
	R_DISABLED = 1 << 6,
};

// Parameters for [[setup]]. Partially completed by the kernel.
export type params = struct {
	sq_entries: u32,
	cq_entries: u32,
	flags: setup_flags,
	sq_thread_cpu: u32,
	sq_thread_idle: u32,
	features: features,
	wq_fd: u32,
	resv: [3]u32,
	sq_off: sqring_offsets,
	cq_off: cqring_offsets,
};

// Features supported by the kernel.
export type features = enum u32 {
	NONE = 0,
	SINGLE_MMAP = 1 << 0,
	NODROP = 1 << 1,
	SUBMIT_STABLE = 1 << 2,
	RW_CUR_POS = 1 << 3,
	CUR_PERSONALITY = 1 << 4,
	FAST_POLL = 1 << 5,
	POLL_32BITS = 1 << 6,
};

// Flags for [[enter]].
export type enter_flags = enum uint {
	NONE = 0,
	GETEVENTS = 1 << 0,
	SQ_WAKEUP = 1 << 1,
	SQ_WAIT = 1 << 2,
};

// Operations for [[register]].
export type regop = enum uint {
	REGISTER_BUFFERS,
	UNREGISTER_BUFFERS,
	REGISTER_FILES,
	UNREGISTER_FILES,
	REGISTER_EVENTFD,
	UNREGISTER_EVENTFD,
	REGISTER_FILES_UPDATE,
	REGISTER_EVENTFD_ASYNC,
	REGISTER_PROBE,
	REGISTER_PERSONALITY,
	UNREGISTER_PERSONALITY,
	REGISTER_RESTRICTIONS,
	REGISTER_ENABLE_RINGS,
};

// Information for a REGISTER_FILES_UPDATE operation.
export type files_update = struct {
	offs: u32,
	resv: u32,
	fds: *int,
};

// Flags for a probe operation.
export type op_flags = enum u16 {
	NONE = 0,
	SUPPORTED = 1 << 0,
};

// REGISTER_PROBE operation details.
export type probe_op = struct {
	op: u8,
	resv: u8,
	flags: op_flags,
	resv2: u32,
};

// Summary of REGISTER_PROBE results.
export type probe = struct {
	last_op: u8,
	ops_len: u8,
	resv: u16,
	resv2: [3]u32,
	ops: [*]probe_op,
};

// Details for a REGISTER_RESTRICTIONS operation.
export type restriction = struct {
	opcode: resop,
	union {
		register_op: regop,
		sqe_op: op,
		flags: flags,
	},
	resv: u8,
	resv2: [3]u32,
};

// Opcode for a [[restriction]].
export type resop = enum u16 {
	NONE = 0,
	// Allow an io_uring_register(2) opcode
	REGISTER_OP = 0,
	// Allow an sqe opcode
	SQE_OP = 1,
	// Allow sqe flags
	SQE_FLAGS_ALLOWED = 2,
	// Require sqe flags (these flags must be set on each submission)
	SQE_FLAGS_REQUIRED = 3,
};

// State for an io_uring.
export type io_uring = struct {
	sq: sq,
	cq: cq,
	fd: int,
	flags: setup_flags,
	features: features,
};

// Submission queue state.
export type sq = struct {
	khead: *uint,
	ktail: *uint,
	kring_mask: *uint,
	kring_entries: *uint,
	kflags: *sqring_flags,
	kdropped: *uint,
	array: *[*]uint,
	sqes: *[*]sqe,
	sqe_head: uint,
	sqe_tail: uint,
	ring_sz: size,
	ring_ptr: *void,
};

// Completion queue state.
export type cq = struct {
	khead: *uint,
	ktail: *uint,
	kring_mask: *uint,
	kring_entries: *uint,
	kflags: *cqring_flags,
	koverflow: *uint,
	cqes: *[*]cqe,
	ring_sz: size,
	ring_ptr: *void,
};
