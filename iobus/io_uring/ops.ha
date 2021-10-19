use io;
use linux::io_uring;

// Prepares an asynchronous read operation.
export fn read(bus: *bus, file: file, buf: []u8) (handle | queuefull) = {
	let sqe = match (io_uring::get_sqe(&bus.uring)) {
	case null =>
		return queuefull;
	case sqe: *io_uring::sqe =>
		yield sqe;
	};
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::read(sqe, fd, buf: *[*]u8, len(buf), -1, flags);
	io_uring::set_user(sqe, sqe);
	return sqe: handle;
};

// Returns the result of a completed read operation.
export fn endread(res: result) (size | io::EOF | error) = {
	assert(handleof(res).opcode == io_uring::op::READ,
		"endread called for non-read iobus::result");
	let z = io_uring::result(res)?: size;
	if (z == 0) {
		return io::EOF;
	};
	return z;
};

// Prepares an asynchronous write operation.
export fn write(bus: *bus, file: file, buf: []u8) (handle | queuefull) = {
	let sqe = match (io_uring::get_sqe(&bus.uring)) {
	case null =>
		return queuefull;
	case sqe: *io_uring::sqe =>
		yield sqe;
	};
	let flags = io_uring::flags::NONE;
	let fd = match (file) {
	case file: io::file =>
		yield file: i32;
	case file: registered_file =>
		flags |= io_uring::flags::FIXED_FILE;
		yield file: i32;
	};
	io_uring::write(sqe, fd, buf: *[*]u8, len(buf), 0, flags);
	io_uring::set_user(sqe, sqe);
	return sqe: handle;
};

// Returns the result of a completed write operation.
export fn endwrite(res: result) (size | error) = {
	assert(handleof(res).opcode == io_uring::op::WRITE,
		"endwrite called for non-write iobus::result");
	return io_uring::result(res)?: size;
};
