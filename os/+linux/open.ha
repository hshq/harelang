use io;
use rt;
use strings;

// Flags to use for opening a file. Not all operating systems support all flags;
// at a minimum, RDONLY, WRONLY, RDWR, and CREATE will be supported.
export type flags = enum int {
	RDONLY		= 0,
	WRONLY		= 1,
	RDWR		= 2,
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
// If no flags are provided, the default for +linux is RDONLY | NOCTTY | CLOEXEC.
export fn open(
	path: (str | []u8),
	flag: flags...
) (*io::stream | io::error) = {
	const p: []u8 = match (path) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>",
	};

	let oflags = 0;
	let iomode = io::mode::NONE;
	if (len(flag) == 0z) {
		oflags |= (flags::NOCTTY | flags::CLOEXEC | flags::RDONLY): int;
	};
	for (let i = 0z; i < len(flag); i += 1z) {
		oflags |= flag[i]: int;
	};

	if (oflags: flags & flags::RDWR == flags::RDWR) {
		iomode = io::mode::RDWR;
	} else if (oflags: flags & flags::RDONLY == flags::RDONLY) {
		iomode = io::mode::READ;
	} else if (oflags: flags & flags::RDONLY == flags::RDONLY) {
		iomode = io::mode::WRITE;
	};

	let fd: int = match (rt::open(p: *[*]u8: *const char, oflags, 0u)) {
		err: rt::errno => return errno_to_io(err),
		n: int => n,
	};

	return fdopen(fd, name, iomode);
};

// Equivalent to [open], but allows the caller to specify a file mode for the
// new file. If no other flag is given, the default read/write mode is WRONLY.
export fn create(
	path: (str | []u8),
	mode: uint,
	flag: flags...
) (*io::stream | io::error) = {
	const p: []u8 = match (path) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>",
	};

	let oflags = 0;
	let iomode = io::mode::NONE;
	if (len(flag) == 0z) {
		oflags |= (flags::NOCTTY | flags::CLOEXEC | flags::WRONLY): int;
	};
	for (let i = 0z; i < len(flag); i += 1z) {
		oflags |= flag[i]: int;
	};
	oflags |= flags::CREATE: int;

	if (oflags: flags & flags::RDWR == flags::RDWR) {
		iomode = io::mode::RDWR;
	} else if (oflags: flags & flags::RDONLY == flags::RDONLY) {
		iomode = io::mode::READ;
	} else if (oflags: flags & flags::RDONLY == flags::RDONLY) {
		iomode = io::mode::WRITE;
	};

	let fd: int = match (rt::open(p: *[*]u8: *const char, oflags, mode)) {
		err: rt::errno => return errno_to_io(err),
		n: int => n,
	};

	return fdopen(fd, name, iomode);
};
