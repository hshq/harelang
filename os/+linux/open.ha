use io;
use rt;
use strings;

export type flags = enum {
	NONE		= 0,
	CREATE		= 0o100,
	EXCLUSIVE	= 0o200,
	NOCTTY		= 0o400,
	TRUNC		= 0o1000,
	APPEND		= 0o2000,
	NONBLOCK	= 0o4000,
	DSYNC		= 0o10000,
	SYNC		= 0o4010000,
	RSYNC		= 0o4010000,
	DIRECTORY	= 0o200000,
	NOFOLLOW	= 0o400000,
	CLOEXEC		= 0o2000000,
};

// Opens a file from the filesystem.
//
// If no flags are provided, the default is NOCTTY | CLOEXEC.
export fn open(
	path: (str | []u8),
	mode: io::mode,
	flag: flags...
) (*io::stream | io::error) = {
	// Verify that these line up with the Linux ABI:
	static assert(io::mode::RDONLY: int == 0);
	static assert(io::mode::WRONLY: int == 1);
	static assert(io::mode::RDWR: int == 2);

	const p: []u8 = match (path) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>",
	};

	let m = mode: int;
	if (len(flag) == 0z) {
		m |= flags::NOCTTY: int | flags::CLOEXEC: int;
	};
	for (let i = 0z; i < len(flag); i += 1z) {
		m |= flag[i]: int;
	};

	let r = rt::open(p: *[*]u8: *const char, m, 0u);
	let fd: int = match (rt::wrap_return(r)) {
		err: rt::errno => return errno_to_io(err),
		n: size => n: int,
	};

	return fdopen(fd, name, mode);
};
