use io;
use rt;
use strings;

// Opens a file from the filesystem.
export fn open(path: (str | []u8), mode: io::mode) (*io::stream | io::error) = {
	// Verify that these line up with the Linux ABI:
	static assert(io::mode::RDONLY: uint == 0u);
	static assert(io::mode::WRONLY: uint == 1u);
	static assert(io::mode::RDWR: uint == 2u);

	const p: []u8 = match (path) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>", // TODO: try to decode it?
	};

	// TODO: Cast slice to array
	let r = rt::open((&p: *types::slice).data: *const char, mode: int, 0u);
	let fd: int = match (rt::wrap_return(r)) {
		err: rt::errno => return errno_to_io(err),
		n: size => n: int,
	};

	// TODO: Pass mode flags along to fd_stream
	return fdopen(fd, name);
};
