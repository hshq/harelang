use io;
use rt;

fn io_errstr(data: *void) str = {
	const errno = data: uintptr: int: rt::errno;
	return rt::errstr(errno);
};

// TODO: Implement the inverse of this and make it public
fn errno_to_io(err: rt::errno) io::error = {
	let err = io::os_error {
		string = &io_errstr,
		data = err: uintptr: *void,
	};
	return err: io::error;
};
