use rt;
use io;
use os;

// Returns whether the given stream is connected to a terminal.
export fn isatty(stream: *io::stream) bool = {
	let fd = io::fd(stream);
	let wsz = rt::winsize { ... };
	return match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
		e: rt::errno => false,
		r: int => if (r == 0) true else false,
	};
};
