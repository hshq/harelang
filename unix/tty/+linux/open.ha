use errors;
use fs;
use io;
use os;

// Returns a stream connected to the TTY of the current process. The caller must
// close it using [[io::close]].
export fn open() (io::file | error) = {
	return match (os::open("/dev/tty", fs::flags::RDWR,
			fs::flags::CLOEXEC)) {
		f: io::file => f,
		fs::error => errors::noentry,
	};
};
