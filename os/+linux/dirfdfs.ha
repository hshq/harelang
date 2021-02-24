use fs;
use io;
use rt;
use strings;

// Controls how symlinks are followed (or not) in a dirfd filesystem. Support
// for this feature varies, you should gate usage of this enum behind a build
// tag.
//
// Note that on Linux, specifying BENEATH or IN_ROOT will also disable magic
// symlinks.
export type resolve = enum {
	NORMAL,

	// Does not allow symlink resolution to occur for any symlinks which
	// would refer to any anscestor of the fd directory. This disables all
	// absolute symlinks, and any call to open or create with an absolute
	// path.
	BENEATH,

	// Treat the directory fd as the root directory. This affects
	// open/create for absolute paths, as well as absolute path resolution
	// of symlinks. The effects are similar to chroot.
	IN_ROOT,

	// Disables symlink resolution entirely.
	NO_SYMLINKS,

	// Disallows traversal of mountpoints during path resolution. This is
	// not recommended for general use, as bind mounts are extensively used
	// on many systems.
	NO_XDEV,
};

type os_filesystem = struct {
	fs: fs::fs,
	dirfd: int,
	resolve: resolve,
};

fn static_dirfdopen(fd: int, filesystem: *os_filesystem) *fs::fs = {
	*filesystem = os_filesystem {
		fs = fs::fs {
			open = &fs_open,
			create = &fs_create,
			iter = &fs_iter,
			stat = &fs_stat,
			subdir = &fs_subdir,
			...
		},
		dirfd = fd,
	};
	return &filesystem.fs;
};

// Opens a file descriptor as an [fs::fs]. This file descriptor must be a
// directory file.
export fn dirfdopen(fd: int, resolve: resolve...) *fs::fs = {
	let fs = alloc(os_filesystem { ... });
	let fsfs = static_dirfdopen(fd, fs);
	for (let i = 0z; i < len(resolve); i += 1) {
		fs.resolve |= resolve[i];
	};
	return fsfs;
};

// Clones a dirfd filesystem, optionally adding additional [resolve]
// constraints.
export fn dirfs_clone(fs: *fs::fs, resolve: resolve...) *fs::fs = {
	assert(fs.open == &fs_open);
	let fs = fs: *os_filesystem;
	let new = alloc(*fs);
	for (let i = 0z; i < len(resolve); i += 1) {
		new.resolve |= resolve[i];
	};
	new.dirfd = rt::dup(new.dirfd) as int;
	return &new.fs;
};

fn _fs_open(
	fs: *fs::fs,
	path: fs::path,
	mode: io::mode,
	oh: *rt::open_how,
) (*io::stream | fs::error) = {
	let fs = fs: *os_filesystem;

	oh.resolve = 0u64;
	if (fs.resolve & resolve::BENEATH == resolve::BENEATH) {
		oh.resolve |= rt::RESOLVE_BENEATH | rt::RESOLVE_NO_MAGICLINKS;
	};
	if (fs.resolve & resolve::IN_ROOT == resolve::IN_ROOT) {
		oh.resolve |= rt::RESOLVE_IN_ROOT | rt::RESOLVE_NO_MAGICLINKS;
	};
	if (fs.resolve & resolve::NO_SYMLINKS == resolve::NO_SYMLINKS) {
		oh.resolve |= rt::RESOLVE_NO_SYMLINKS;
	};
	if (fs.resolve & resolve::NO_XDEV == resolve::NO_XDEV) {
		oh.resolve |= rt::RESOLVE_NO_XDEV;
	};

	const p: []u8 = match (path) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>",
	};

	let fd = match (rt::openat2(fs.dirfd, p: *[*]u8: *const char,
			oh, size(rt::open_how))) {
		err: rt::errno => return errno_to_io(err),
		fd: int => fd,
	};

	return fdopen(fd, name, mode);
};

fn fs_open(fs: *fs::fs, path: fs::path, mode: io::mode) (*io::stream | fs::error) = {
	let oflags = rt::O_NOCTTY | rt::O_CLOEXEC;
	if (mode & io::mode::RDWR == io::mode::RDWR) {
		oflags |= rt::O_RDWR;
	} else if (mode & io::mode::READ == io::mode::READ) {
		oflags |= rt::O_RDONLY;
	} else if (mode & io::mode::WRITE == io::mode::WRITE) {
		oflags |= rt::O_WRONLY;
	};

	let oh = rt::open_how {
		flags = oflags: u64,
		...
	};
	return _fs_open(fs, path, mode, &oh);
};

fn fs_create(fs: *fs::fs, path: fs::path, mode: io::mode) (*io::stream | fs::error) = {
	let oflags = rt::O_NOCTTY | rt::O_CLOEXEC | rt::O_CREATE;
	if (mode & io::mode::RDWR == io::mode::RDWR) {
		oflags |= rt::O_RDWR;
	} else if (mode & io::mode::READ == io::mode::READ) {
		oflags |= rt::O_RDONLY;
	} else if (mode & io::mode::WRITE == io::mode::WRITE) {
		oflags |= rt::O_WRONLY;
	};

	let oh = rt::open_how {
		flags = oflags: u64,
		...
	};
	return _fs_open(fs, path, mode, &oh);
};

fn fs_iter(fs: *fs::fs, path: fs::path) (*fs::iterator | fs::error) = {
	abort();
};

fn fs_stat(fs: *fs::fs, path: fs::path) (fs::filestat | fs::error) = {
	abort();
};

fn fs_subdir(fs: *fs::fs, path: fs::path) (*fs::fs | fs::error) = {
	abort();
};
