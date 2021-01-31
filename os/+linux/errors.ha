use io;

fn io_errstr(data: *void) str = {
	return "TODO: insert errno description here";
};

// TODO: Implement the inverse of this and make it public
fn errno_to_io(err: rt::errno) io::error = {
	let e: io::os_error = struct {
		string: *fn(data: *void) str = &io_errstr,
		data: *void = err: uintptr: *void,
	};
	return e: io::error;
};
