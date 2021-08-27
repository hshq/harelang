use errors;
use fs;
use io;
use os;

// Return either /dev/tty or stdin, whichever is accessible and is a tty.
export fn open() (*io::stream | error) = {
	match (os::open("/dev/tty", fs::flags::RDWR, fs::flags::CLOEXEC)) {
		i: *io::stream => return i,
		fs::error => void,
	};

	if (isatty(os::stdout)) {
		return os::stdout;
	};

	return errors::noentry;
};
