use io;
use linux::io_uring;
use net::ip;
use net::unix;
use rt;
// TODO: Seek to de-duplicate some of the SQE prep code

fn getsqe(bus: *bus) (*io_uring::sqe | queuefull) = {
	match (io_uring::get_sqe(&bus.uring)) {
	case null =>
		return queuefull;
	case sqe: *io_uring::sqe =>
		return sqe;
	};
};

// Prepares an asynchronous read operation. The offset value may be set to -1 to
// advance the host's internal file offset, and must be set to zero for
// non-seekable files (such as network connections).
export fn read(
	bus: *bus,
	file: file,
	buf: []u8,
	offs: u64,
) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::read(sqe, fd, buf: *[*]u8, len(buf), offs, flags);
	return handle { sqe = sqe, ... };
};

// Returns the result of a completed read operation.
export fn endread(res: result) (size | io::EOF | error) = {
	assert(handleof(res).sqe.opcode == io_uring::op::READ,
		"endread called for non-read iobus::result");
	let z = io_uring::result(res)?: size;
	if (z == 0) {
		return io::EOF;
	};
	return z;
};

// Prepares an asynchronous write operation. The offset value may be set to -1
// to advance the host's internal file offset, and must be set to zero for
// non-seekable files (such as network connections).
export fn write(
	bus: *bus,
	file: file,
	buf: []u8,
	offs: u64,
) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::write(sqe, fd, buf: *[*]u8, len(buf), offs, flags);
	return handle { sqe = sqe, ... };
};

// Returns the result of a completed write operation.
export fn endwrite(res: result) (size | error) = {
	assert(handleof(res).sqe.opcode == io_uring::op::WRITE,
		"endwrite called for non-write iobus::result");
	return io_uring::result(res)?: size;
};

// Prepares an asynchronous close operation.
export fn close(bus: *bus, file: file) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::close(sqe, fd, flags);
	return handle { sqe = sqe, ... };
};

// Returns the result of a completed close operation.
export fn endclose(res: result) (void | error) = {
	assert(handleof(res).sqe.opcode == io_uring::op::CLOSE,
		"endclose called for non-close iobus::result");
	io_uring::result(res)?;
	return;
};

// List of options for [[endaccept]].
export type accept_opts = (*ip::addr | *u16);

// Prepares an asynchronous operation to accept a new connection from a network
// socket.
export fn accept(bus: *bus, file: file) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	let handle = handle {
		sqe = sqe,
		accept = accept_handle {
			sockaddr_sz = size(rt::sockaddr): uint,
			...
		},
		...
	};
	// sockaddr fields are set up in [[enqueue]]
	io_uring::accept(sqe, fd, null, null, rt::SOCK_CLOEXEC: uint, flags);
	return handle;
};

// Returns the result of a completed accept operation. Accepts a list of
// [[accept_opts]] which can be used to retrieve the peer's address or port.
export fn endaccept(res: result, opts: accept_opts...) (io::file | error) = {
	let handle = handleof(res);
	assert(handle.sqe.opcode == io_uring::op::ACCEPT,
		"endaccept called for non-accept iobus::result");
	const file = io_uring::result(res)?: io::file;
	for (let i = 0z; i < len(opts); i += 1) {
		match (opts[i]) {
		case addr: *ip::addr =>
			let peer = ip::from_native(handle.accept.sockaddr);
			*addr = peer.0;
		case port: *u16 =>
			let peer = ip::from_native(handle.accept.sockaddr);
			*port = peer.1;
		};
	};
	return file;
};
