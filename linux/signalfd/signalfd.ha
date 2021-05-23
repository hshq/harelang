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
) (int | errors::opaque) = {
	return match (rt::signalfd(fd, mask, flags)) {
		fd: int => fd,
		err: rt::errno => errors::errno(err),
	};
};

// Reads pending signal info from a signalfd.
export fn readsignal(fd: int) (siginfo | errors::opaque) = {
	let si = siginfo { ... };
	return match (rt::read(fd, &si, size(siginfo))) {
		err: rt::errno => errors::errno(err),
		z: size => {
			assert(z == size(siginfo));
			return si;
		},
	};
};
