use rt;
use io;
use os;

// Returns whether the given stream is connected to a terminal.
export fn isatty(stream: *io::stream) bool = {
	let fd = match (io::unwrapfd(stream)) {
		void => return false,
		fd: int => fd,
	};
	let wsz = rt::winsize { ... };
	return match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
		e: rt::errno => false,
		r: int => if (r == 0) true else false,
	};
};
