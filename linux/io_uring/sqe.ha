// TODO:
// - Interface for buffer registration
use rt;
use types;

fn prep(sq: *sqe, op: op, flags: sqe_flags...) void = {
	// XXX: Is this compatible with the spec?
	*sq = sqe { opcode = op, ... };
	for (let i = 0z; i < len(flags); i += 1) {
		sq.flags |= flags[i];
	};
};

fn preprw(
	sqe: *sqe,
	op: op,
	fd: int,
	addr: nullable *void,
	length: uint,
	offs: u64,
	flags: sqe_flags...
) void = {
	prep(sqe, op, flags...);
	sqe.fd = fd;
	sqe.addr = addr;
	sqe.length = length;
	sqe.off = offs;
};

// Prepares a no-op "operation" for an [[sqe]].
export fn nop(sqe: *sqe, flags: sqe_flags...) void = {
	prep(sqe, op::NOP, flags...);
};

// Prepares a vectored read operation for an [[sqe]].
export fn readv(
	sqe: *sqe,
	fd: int,
	iov: []rt::iovec,
	offs: size,
) void = {
	preprw(sqe, op::READV, fd, iov: *[*]rt::iovec, len(iov): uint, offs);
};

// Prepares a vectored write operation for an [[sqe]].
export fn writev(
	sqe: *sqe,
	fd: int,
	iov: []rt::iovec,
	offs: size,
) void = {
	preprw(sqe, op::WRITEV, fd, iov: *[*]rt::iovec, len(iov): uint, offs);
};

// Prepares a read operation for an [[sqe]].
export fn read(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	flags: sqe_flags...,
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::READ, fd, buf, count: u32, 0, flags...);
};

// Prepares a write operation for an [[sqe]].
export fn write(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	flags: sqe_flags...,
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::WRITE, fd, buf, count: u32, 0, flags...);
};
