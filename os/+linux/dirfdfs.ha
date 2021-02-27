use encoding::utf8;
use fs;
use io;
use path;
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
// directory file. The file will be closed when the fs is closed.
export fn dirfdopen(fd: int, resolve: resolve...) *fs::fs = {
	let ofs = alloc(os_filesystem { ... });
	let fs = static_dirfdopen(fd, ofs);
	for (let i = 0z; i < len(resolve); i += 1) {
		ofs.resolve |= resolve[i];
	};
	fs.close = &fs_close;
	return fs;
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
	path: path::path,
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

	const name: str = match (path) {
		s: str  => s,
		b: []u8 => "<open([]u8)>",
	};

	let fd = match (rt::openat2(fs.dirfd, path, oh, size(rt::open_how))) {
		err: rt::errno => return errno_to_io(err),
		fd: int => fd,
	};

	return fdopen(fd, name, mode);
};

fn fs_open(fs: *fs::fs, path: path::path, mode: io::mode) (*io::stream | fs::error) = {
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

fn fs_create(fs: *fs::fs, path: path::path, mode: io::mode) (*io::stream | fs::error) = {
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

fn fs_stat(fs: *fs::fs, path: path::path) (fs::filestat | fs::error) = {
	let fs = fs: *os_filesystem;
	let st = rt::st { ... };
	match (rt::fstatat(fs.dirfd, path, &st, rt::AT_SYMLINK_NOFOLLOW)) {
		err: rt::errno => return errno_to_io(err),
		void => void,
	};
	return fs::filestat {
		mask = fs::stat_mask::UID
			| fs::stat_mask::GID
			| fs::stat_mask::SIZE
			| fs::stat_mask::INODE,
		mode = st.mode: fs::mode,
		uid = st.uid,
		uid = st.gid,
		sz = st.sz,
		inode = st.ino,
	};
};

fn fs_subdir(fs: *fs::fs, path: path::path) (*fs::fs | fs::error) = {
	let fs = fs: *os_filesystem;
	let oh = rt::open_how {
		flags = (rt::O_RDONLY | rt::O_CLOEXEC | rt::O_DIRECTORY): u64,
		...
	};

	let fd: int = match (rt::openat2(fs.dirfd, path,
			&oh, size(rt::open_how))) {
		err: rt::errno => return errno_to_io(err),
		n: int => n,
	};

	return dirfdopen(fd);
};

fn fs_close(fs: *fs::fs) void = {
	let fs = fs: *os_filesystem;
	rt::close(fs.dirfd);
};

def BUFSIZ: size = 2048;

// Based on musl's readdir
type os_iterator = struct {
	iter: fs::iterator,
	fd: int,
	buf_pos: size,
	buf_end: size,
	buf: [BUFSIZ]u8,
};

fn fs_iter(fs: *fs::fs, path: path::path) (*fs::iterator | fs::error) = {
	let fs = fs: *os_filesystem;
	let oh = rt::open_how {
		flags = (rt::O_RDONLY | rt::O_CLOEXEC | rt::O_DIRECTORY): u64,
		...
	};
	let fd: int = match (rt::openat2(fs.dirfd, path,
			&oh, size(rt::open_how))) {
		err: rt::errno => {
			if (err: int == rt::ENOTDIR) {
				return fs::wrongtype;
			};
			return errno_to_io(err);
		},
		n: int => n,
	};

	let iter = alloc(os_iterator {
		iter = fs::iterator {
			next = &iter_next,
		},
		fd = fd,
		...
	});
	return &iter.iter;
};

fn iter_next(iter: *fs::iterator) (fs::dirent | void) = {
	let iter = iter: *os_iterator;
	if (iter.buf_pos >= iter.buf_end) {
		let n = rt::getdents64(iter.fd, &iter.buf, BUFSIZ) as size;
		if (n == 0) {
			rt::close(iter.fd);
			free(iter);
			return;
		};
		iter.buf_end = n;
		iter.buf_pos = 0;
	};
	let de = &iter.buf[iter.buf_pos]: *rt::dirent64;
	iter.buf_pos += de.d_reclen;
	let ln = strings::c_strlen(&de.d_name: *const char);
	let name = &de.d_name: *[*]u8;
	let name = if (!utf8::valid(name[..ln])) {
		name[..ln];
	} else {
		strings::from_utf8_unsafe(name[..ln]);
	};

	let ftype: fs::mode = switch (de.d_type) {
		rt::DT_UNKNOWN => fs::mode::UNKNOWN,
		rt::DT_FIFO => fs::mode::FIFO,
		rt::DT_CHR  => fs::mode::CHR,
		rt::DT_DIR  => fs::mode::DIR,
		rt::DT_BLK  => fs::mode::BLK,
		rt::DT_REG  => fs::mode::REG,
		rt::DT_LNK  => fs::mode::LINK,
		rt::DT_SOCK => fs::mode::SOCK,
		* => fs::mode::UNKNOWN,
	};
	return fs::dirent {
		name = name,
		ftype = ftype,
	};
};
