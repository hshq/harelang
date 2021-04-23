use errors;
use fs;
use io;
use os;

// Return either /dev/tty or stdin, whichever is accessible and is a tty.
export fn open() (*io::stream | error) = {
	match (os::open("/dev/tty")) {
		i: *io::stream => return i,
		_: fs::error => void,
	};

	if (isatty(os::stdout)) {
		return os::stdout;
	};

	return errors::noentry;
};
