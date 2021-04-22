use rt;
use io;
use os;

// Returns true if the file descriptor underlying a stream is a terminal.
export fn isatty(stream: *io::stream) bool = {
	let fd = match (os::streamfd(stream, true)) {
		f: int => f,
		_: void => return false,
	};
	let wsz = rt::winsize { ... };
	return match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
		e: rt::errno => false,
		r: int => if (r == 0) true else false,
	};
};
