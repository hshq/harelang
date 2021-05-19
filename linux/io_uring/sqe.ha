use endian;
use rt;
use types;

fn prep(sq: *sqe, op: op, flags: sqe_flags...) void = {
	rt::memset(sq, 0, size(sqe));
	sq.opcode = op;
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

// Sets the user data field of an [[sqe]]. This is copied to the [[cqe]] and can
// be used to correlate a completion event with the original SQE.
export fn set_user(sqe: *sqe, user_data: *void) void = {
	static assert(size(uintptr) <= size(u64));
	sqe.user_data = user_data: uintptr: u64;
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
	flags: sqe_flags...
) void = {
	preprw(sqe, op::READV, fd,
		iov: *[*]rt::iovec, len(iov): uint, offs, flags...);
};

// Prepares a vectored write operation for an [[sqe]].
export fn writev(
	sqe: *sqe,
	fd: int,
	iov: []rt::iovec,
	offs: size,
	flags: sqe_flags...
) void = {
	preprw(sqe, op::WRITEV, fd,
		iov: *[*]rt::iovec, len(iov): uint, offs, flags...);
};

// Prepares a read operation for an [[sqe]].
export fn read(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	flags: sqe_flags...
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
	flags: sqe_flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::WRITE, fd, buf, count: u32, 0, flags...);
};

// Prepares a read for a fixed buffer previously registered with
// [[register_buffers]]. The buf and count parameters must refer to an address
// which falls within the buffer referenced by the index parameter.
export fn read_fixed(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	index: u16,
	flags: sqe_flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::READ_FIXED, fd, buf, count: u32, 0, flags...);
	sqe.buf_index = index;
};

// Prepares a write for a fixed buffer previously registered with
// [[register_buffers]]. The buf and count parameters must refer to an address
// which falls within the buffer referenced by the index parameter.
export fn write_fixed(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	index: u16,
	flags: sqe_flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::WRITE_FIXED, fd, buf, count: u32, 0, flags...);
	sqe.buf_index = index;
};

// Prepares an fsync operation for an [[sqe]]. Note that operations are executed
// in parallel and not are completed in submission order, so an fsync submitted
// after a write may not cause the write to be accounted for by the fsync unless
// [[sqe_flags::IO_LINK]] is used.
export fn fsync(
	sqe: *sqe,
	fd: int,
	fsync_flags: fsync_flags,
	flags: sqe_flags...
) void = {
	preprw(sqe, op::FSYNC, fd, null, 0, 0, flags...);
	sqe.fsync_flags = fsync_flags;
};

// Adds a request to poll a file descriptor for the given set of poll events.
// This will only happen once, the poll request must be submitted with a new SQE
// to re-poll the file descriptor later. The caller must call [[setuser]] to
// provide a user data field in order to use [[poll_remove]] to remove this poll
// request later.
export fn poll_add(
	sqe: *sqe,
	fd: int,
	poll_mask: uint,
	flags: sqe_flags...
) void = {
	preprw(sqe, op::POLL_ADD, fd, null, 0, 0, flags...);
	assert(endian::host == &endian::little); // TODO?
	sqe.poll32_events = poll_mask: u32;
};

// Removes an existing poll request by matching the SQE's user_data field.
export fn poll_remove(sqe: *sqe, user_data: *void, flags: sqe_flags...) void = {
	preprw(sqe, op::POLL_REMOVE, -1, null, 0, 0, flags...);
	set_user(sqe, user_data);
};

// Prepares a sendmsg operation for an [[sqe]], equivalent to the sendmsg(2)
// system call.
export fn sendmsg(
	sqe: *sqe,
	fd: int,
	msghdr: *rt::msghdr,
	sendmsg_flags: int,
	flags: sqe_flags...
) void = {
	preprw(sqe, op::SENDMSG, fd, msghdr, 0, 0, flags...);
	sqe.msg_flags = sendmsg_flags;
};

// Prepares a recvmsg operation for an [[sqe]], equivalent to the recvmsg(2)
// system call.
export fn recvmsg(
	sqe: *sqe,
	fd: int,
	msghdr: *rt::msghdr,
	recvmsg_flags: int,
	flags: sqe_flags...
) void = {
	preprw(sqe, op::RECVMSG, fd, msghdr, 0, 0, flags...);
	sqe.msg_flags = recvmsg_flags;
};

// Prepares a send operation for an [[sqe]], equivalent to the send(2) system
// call.
export fn send(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	send_flags: int,
	flags: sqe_flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::SEND, fd, buf, count: u32, 0, flags...);
	sqe.msg_flags = send_flags;
};

// Prepares a recv operation for an [[sqe]], equivalent to the recv(2) system
// call.
export fn recv(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	recv_flags: int,
	flags: sqe_flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::RECV, fd, buf, count: u32, 0, flags...);
	sqe.msg_flags = recv_flags;
};
