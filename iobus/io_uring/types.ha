use errors;
use io;
use linux::io_uring;
use net::ip;
use net::unix;
use rt;

export type error = io_uring::error;

export fn strerror(err: error) const str = {
	return io_uring::strerror(err);
};

export type bus = struct {
	uring: io_uring::io_uring,
	fdset: []io::file,
	lastfd: size,
};

// The result of a completed I/O operation.
export type result = *io_uring::cqe;

// An I/O operation handle.
export type handle = struct {
	sqe: *io_uring::sqe,
	callbacks: [](*fn(res: result, data: *void) void, *void),
	union {
		accept: accept_handle,
	},
};

export type accept_handle = struct {
	sockaddr: rt::sockaddr,
	sockaddr_sz: uint,
};

export type registered_file = int;

export type file = (registered_file | io::file);

// Returned if the submission queue is full and new I/O submissions are not
// available. The user should call [[submit]] before attempting to submit new
// I/O.
export type queuefull = !void;
