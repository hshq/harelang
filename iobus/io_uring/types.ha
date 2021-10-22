use errors;
use io;
use linux::io_uring;
use rt;

// All errors which may be raised by iobus.
export type error = !(io_uring::error | nobuffers);

// Returned from [[endread]] et al when an operation was configured to use a
// buffer pool, but the buffer pool has been exhausted.
export type nobuffers = !void;

// Converts an [[error]] into a user-friendly string.
export fn strerror(err: error) const str = {
	match (err) {
	case nobuffers =>
		return "iobus buffer pool exhausted";
	case err: io_uring::error =>
		return io_uring::strerror(err);
	};
};

fn wraperror(err: io_uring::error) error = {
	match (err) {
	case io_uring::nobuffers =>
		return nobuffers;
	case =>
		return err;
	};
};

fn cqe_result(res: *io_uring::cqe) (int | error) = {
	match (io_uring::result(res)) {
	case err: io_uring::error =>
		return wraperror(err);
	case n: int =>
		return n;
	};
};

export type bus = struct {
	uring: io_uring::io_uring,
	fdset: []io::file,
	lastfd: size,
	nextgroup: u16,
};

export type result = *io_uring::cqe;

export type handle = struct {
	sqe: *io_uring::sqe,
	user: nullable *void,
	callbacks: [](*fn(res: result, data: *void) void, *void),
	union {
		accept: accept_handle,
		cstring: *char,
	},
};

export type accept_handle = struct {
	sockaddr: rt::sockaddr,
	sockaddr_sz: uint,
};

export type registered_file = int;

// A file object which accepts multiplexed I/O operations.
export type file = (registered_file | io::file);

// Returned if the submission queue is full and new I/O submissions are not
// available. The user should call [[submit]] before attempting to submit new
// I/O.
export type queuefull = !void;
