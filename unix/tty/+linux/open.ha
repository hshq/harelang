use errors;
use fs;
use io;
use os;

// Returns a stream connected to the TTY of the current process. The caller must
// close it using [[io::close]].
export fn open() (io::file | error) = {
	match (os::open("/dev/tty", fs::flags::RDWR, fs::flags::CLOEXEC)) {
	case let f: io::file =>
		return f;
	case fs::error =>
		return errors::noentry;
	};
};
