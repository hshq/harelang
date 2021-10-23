use fs;
use io;
use linux::io_uring;
use net::ip;
use os;
use rt;
use strings;
use unix::poll;

// TODO: Seek to de-duplicate more of the SQE prep code

fn getsqe(bus: *bus) (*io_uring::sqe | queuefull) = {
	match (io_uring::get_sqe(&bus.uring)) {
	case null =>
		return queuefull;
	case sqe: *io_uring::sqe =>
		return sqe;
	};
};

// This value may be passed to [[read]] and [[write]] to use (and update) the
// current file offset, with the caveat that parallel reads or writes may clash.
export def CUR: u64 = -1: u64;

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
	let z = cqe_result(res)?: size;
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
	return cqe_result(res)?: size;
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
	cqe_result(res)?;
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
	const file = cqe_result(res)?: io::file;
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

// Prepares an asynchronous poll operation for a file.
export fn poll(
	bus: *bus,
	file: file,
	events: poll::event,
) (handle | queuefull) = {
	// TODO: Support IORING_POLL_ADD_MULTI
	let sqe = getsqe(bus)?;
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::poll_add(sqe, fd, events: uint, flags);
	return handle { sqe = sqe, ...  };
};

// Returns the revents for a [[poll]] operation.
export fn endpoll(bus: *bus, res: result) (poll::event | error) = {
	let handle = handleof(res);
	assert(handle.sqe.opcode == io_uring::op::POLL_ADD,
		"endpoll called for non-poll iobus::result");
	return cqe_result(res)?: poll::event;
};

// TODO: poll_remove

// Prepares an asynchronous open operation.
//
// If no flags are provided, [[fs::flags::RDONLY]], [[fs::flags::NOCTTY]],
// [[fs::flags::CLOEXEC]] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
export fn open(
	bus: *bus,
	path: str,
	flags: fs::flags...
) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let handle = handle {
		sqe = sqe,
		cstring = strings::to_c(path),
		...
	};
	let oflags = 0;
	if (len(flags) == 0z) {
		oflags |= (fs::flags::NOCTTY
			| fs::flags::CLOEXEC
			| fs::flags::RDONLY): int;
	};
	for (let i = 0z; i < len(flags); i += 1z) {
		oflags |= flags[i]: int;
	};
	io_uring::openat(sqe, os::dirfile(os::cwd), handle.cstring, oflags, 0);
	return handle;
};

// Returns the new file handle from an [[open]] operation.
export fn endopen(bus: *bus, res: result) (io::file | error) = {
	let handle = handleof(res);
	assert(handle.sqe.opcode == io_uring::op::OPENAT,
		"endopen called for non-open iobus::result");
	free(handle.cstring);
	return cqe_result(res)?: io::file;
};

// Prepares an asynchronous file creation operation.
//
// If no flags are provided, [[fs::flags::WRONLY]], [[fs::flags::NOCTTY]],
// [[fs::flags::CLOEXEC]] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
export fn create(
	bus: *bus,
	path: str,
	mode: fs::mode,
	flags: fs::flags...
) (handle | queuefull) = {
	let sqe = getsqe(bus)?;
	let oflags = 0;
	if (len(flags) == 0z) {
		oflags |= (fs::flags::NOCTTY
			| fs::flags::CLOEXEC
			| fs::flags::WRONLY): int;
	};
	for (let i = 0z; i < len(flags); i += 1z) {
		oflags |= flags[i]: int;
	};
	oflags |= fs::flags::CREATE: int;
	let handle = handle {
		sqe = sqe,
		cstring = strings::to_c(path),
		...
	};
	io_uring::openat(sqe, os::dirfile(os::cwd), handle.cstring, oflags, mode);
	return handle;
};

// Returns the new file handle from an [[create]] operation.
export fn endcreate(bus: *bus, res: result) (io::file | error) = {
	let handle = handleof(res);
	assert(handle.sqe.opcode == io_uring::op::OPENAT,
		"endcreate called for non-create iobus::result");
	free(handle.cstring);
	return cqe_result(res)?: io::file;
};
