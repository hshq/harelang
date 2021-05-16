use types;

fn prep(sq: *sqe, op: op, flags: sqe_flags...) void = {
	// XXX: Is this compatible with the spec?
	*sq = sqe { opcode = op, ... };
	for (let i = 0z; i < len(flags); i += 1) {
		sq.flags |= flags[i];
	};
};

// Prepares a read operation for an [[sqe]].
export fn read(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	flags: sqe_flags...,
) void = {
	prep(sqe, op::READ, flags...);
	sqe.fd = fd;
	sqe.addr = buf: uintptr: u64;
	assert(count <= types::U32_MAX);
	sqe.length = count: u32;
};

// Prepares a write operation for an [[sqe]].
export fn write(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	flags: sqe_flags...,
) void = {
	prep(sqe, op::WRITE, flags...);
	sqe.fd = fd;
	sqe.addr = buf: uintptr: u64;
	assert(count <= types::U32_MAX);
	sqe.length = count: u32;
};
