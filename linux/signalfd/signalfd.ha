// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

// TODO: Incorporate this model into a top-level 'signal' module and generalize
// it a bit.
use errors;
use rt;

// Value populated by calls to read(2) for the signalfd.
export type siginfo = struct {
	signo: u32,
	errno: i32,
	code: i32,
	pid: u32,
	uid: u32,
	fd: int,
	tid: u32,
	band: u32,
	overrun: u32,
	trapno: u32,
	status: i32,
	int_: i32,
	ptr: u64,
	utime: u64,
	stime: u64,
	addr: u64,
	addr_lsb: u16,
	pad2: u16,
	ssi_syscall: i32,
	call_addr: u64,
	arch: u32,
	pad: [128 - 14 * 4 - 5 * 8 - 2 * 2]u8,
};

// Creates or updates a signalfd. Pass -1 to create a new signalfd, or an
// existing signalfd to update it.
export fn signalfd(
	fd: int,
	mask: *const rt::sigset,
	flags: int,
) (int | errors::error) = {
	match (rt::signalfd(fd, mask, flags)) {
	case let fd: int =>
		return fd;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Reads pending signal info from a signalfd.
export fn readsignal(fd: int) (siginfo | errors::error) = {
	let si = siginfo { ... };
	match (rt::read(fd, &si, size(siginfo))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let z: size =>
		assert(z == size(siginfo));
		return si;
	};
};
