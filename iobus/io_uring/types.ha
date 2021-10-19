use errors;
use io;
use linux::io_uring;
use rt;

// All errors which may be raised by iobus.
export type error = io_uring::error;

// Converts an [[error]] into a user-friendly string.
export fn strerror(err: error) const str = {
	return io_uring::strerror(err);
};

export type bus = struct {
	uring: io_uring::io_uring,
	fdset: []io::file,
	lastfd: size,
};

export type result = *io_uring::cqe;

export type handle = struct {
	sqe: *io_uring::sqe,
	user: nullable *void,
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

// A file object which accepts multiplexed I/O operations.
export type file = (registered_file | io::file);

// Returned if the submission queue is full and new I/O submissions are not
// available. The user should call [[submit]] before attempting to submit new
// I/O.
export type queuefull = !void;
