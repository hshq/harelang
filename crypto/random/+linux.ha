use rt;
use io;

// Fills the given buffer with cryptographically random data. If the system is
// unable to provide random data, abort. If you need to handle errors or want to
// use whatever random data the system can provide, even if less than the
// requested amont, use [stream] instead.
export fn buffer(buf: []u8) void = {
	let n = 0z;
	for (n < len(buf)) {
		match (rt::getrandom(buf[n..]: *[*]u8, len(buf), 0)) {
			err: rt::errno => switch (err) {
				rt::EINTR => void,
				* => abort(),
			},
			z: size => n += z,
		};
	};
};

fn rand_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s == stream);
	return match (rt::getrandom(buf: *[*]u8, len(buf), 0)) {
		err: rt::errno => errno_to_io(err),
		n: size => n,
	};
};

fn io_errstr(data: *void) str = {
	const errno = data: uintptr: int: rt::errno;
	return rt::errstr(errno);
};

fn errno_to_io(err: rt::errno) io::error = {
	let e = io::os_error {
		string = &io_errstr,
		data   = err: uintptr: *void,
	};
	return e: io::error;
};
