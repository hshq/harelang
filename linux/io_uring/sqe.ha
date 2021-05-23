use endian;
use rt;
use types;

fn prep(sq: *sqe, op: op, flags: flags...) void = {
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
	flags: flags...
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
export fn nop(sqe: *sqe, flags: flags...) void = {
	prep(sqe, op::NOP, flags...);
};

// Prepares a vectored read operation for an [[sqe]].
export fn readv(
	sqe: *sqe,
	fd: int,
	iov: []rt::iovec,
	offs: size,
	flags: flags...
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
	flags: flags...
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
	offs: u64,
	flags: flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::READ, fd, buf, count: u32, offs, flags...);
};

// Prepares a write operation for an [[sqe]].
export fn write(
	sqe: *sqe,
	fd: int,
	buf: *void,
	count: size,
	offs: u64,
	flags: flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::WRITE, fd, buf, count: u32, offs, flags...);
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
	flags: flags...
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
	flags: flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::WRITE_FIXED, fd, buf, count: u32, 0, flags...);
	sqe.buf_index = index;
};

// Prepares an fsync operation for an [[sqe]]. Note that operations are executed
// in parallel and not are completed in submission order, so an fsync submitted
// after a write may not cause the write to be accounted for by the fsync unless
// [[flags::IO_LINK]] is used.
export fn fsync(
	sqe: *sqe,
	fd: int,
	fsync_flags: fsync_flags,
	flags: flags...
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
	flags: flags...
) void = {
	preprw(sqe, op::POLL_ADD, fd, null, 0, 0, flags...);
	assert(endian::host == &endian::little); // TODO?
	sqe.poll32_events = poll_mask: u32;
};

// Removes an existing poll request by matching the SQE's user_data field. See
// [[setuser]].
export fn poll_remove(sqe: *sqe, user_data: *void, flags: flags...) void = {
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
	flags: flags...
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
	flags: flags...
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
	flags: flags...
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
	flags: flags...
) void = {
	assert(count <= types::U32_MAX);
	preprw(sqe, op::RECV, fd, buf, count: u32, 0, flags...);
	sqe.msg_flags = recv_flags;
};

// Prepares a timeout operation for an [[sqe]]. "ts" should be a timespec
// describing the desired timeout, and "events" may optionally be used to define
// a number of completion events to wake after (or zero to wake only after the
// timeout expires). The caller must call [[setuser]] to provide a user data
// field in order to use [[timeout_remove]] to cancel this timeout later.
export fn timeout(
	sqe: *sqe,
	ts: *rt::timespec,
	events: uint,
	to_flags: timeout_flags,
	flags: flags...
) void = {
	preprw(sqe, op::TIMEOUT, 0, ts, 1, events, flags...);
	sqe.timeout_flags = to_flags;
};

// Removes an existing timeout request by matching the SQE's user_data field.
// See [[setuser]].
export fn timeout_remove(
	sqe: *sqe,
	user_data: *void,
	to_flags: timeout_flags,
	flags: flags...
) void = {
	preprw(sqe, op::TIMEOUT_REMOVE, 0, user_data, 0, 0, flags...);
	sqe.timeout_flags = to_flags;
};

// Updates an existing timeout request by matching the SQE's user_data field.
// See [[setuser]].
export fn timeout_update(
	sqe: *sqe,
	user_data: *void,
	ts: *rt::timespec,
	events: uint,
	to_flags: timeout_flags,
	flags: flags...
) void = {
	preprw(sqe, op::TIMEOUT_REMOVE, 0, user_data, 0, events, flags...);
	sqe.timeout_flags = to_flags | timeout_flags::UPDATE;
	sqe.addr2 = ts;
};

// Prepares a timeout operation for an [[sqe]] which is linked to the previous
// SQE, effectively setting an upper limit on how long that SQE can take to
// complete. "ts" should be a timespec describing the desired timeout. The
// caller must call [[setuser]] to provide a user data field in order to use
// [[timeout_remove]] to cancel this timeout later.
export fn link_timeout(
	sqe: *sqe,
	ts: *rt::timespec,
	to_flags: timeout_flags,
	flags: flags...
) void = {
	preprw(sqe, op::LINK_TIMEOUT, 0, ts, 1, 0, flags...);
	sqe.timeout_flags = to_flags;
};

// Prepares a socket accept operation for an [[sqe]]. Equivalent to accept4(2).
export fn accept(
	sqe: *sqe,
	fd: int,
	addr: nullable *rt::sockaddr,
	addrlen: nullable *uint,
	aflags: uint,
	flags: flags...
) void = {
	preprw(sqe, op::ACCEPT, fd, addr, 0, 0, flags...);
	sqe.accept_flags = aflags;
	sqe.addr2 = addrlen;
};

// Prepares an [[sqe]] operation which closes a file descriptor.
export fn close(sqe: *sqe, fd: int, flags: flags...) void = {
	preprw(sqe, op::CLOSE, fd, null, 0, 0, flags...);
};
