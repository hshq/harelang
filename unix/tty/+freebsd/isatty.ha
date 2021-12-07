use rt;
use io;
use os;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	let wsz = rt::winsize { ... };
	match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
	case let e: rt::errno =>
		return false;
	case let r: int =>
		return r == 0;
	};
};
