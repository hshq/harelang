// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use errors;
use encoding::utf8;
use fs;
use io;
use path;
use rt;
use strings;
use time;

type os_filesystem = struct {
	fs: fs::fs,
	dirfd: int,
	getdents_bufsz: size,
};

// Opens a file descriptor as an [[fs::fs]]. This file descriptor must be a
// directory file. The file will be closed when the fs is closed.
//
// If no other flags are provided to [[fs::open]] and [[fs::create]] when used with
// a dirfdfs, [[fs::flags::NOCTTY]] and [[fs::flags::CLOEXEC]] are used when opening
// the file. If you pass your own flags, it is recommended that you add these
// unless you know that you do not want them.
export fn dirfdopen(fd: io::file) *fs::fs = {
	let ofs = alloc(os_filesystem { ... });
	let fs = static_dirfdopen(fd, ofs);
	fs.close = &fs_close;
	return fs;
};

fn static_dirfdopen(fd: io::file, filesystem: *os_filesystem) *fs::fs = {
	*filesystem = os_filesystem {
		fs = fs::fs {
			open = &fs_open,
			openfile = &fs_open_file,
			create = &fs_create,
			createfile = &fs_create_file,
			remove = &fs_remove,
			rename = &fs_rename,
			iter = &fs_iter,
			stat = &fs_stat,
			readlink = &fs_readlink,
			subdir = &fs_subdir,
			mkdir = &fs_mkdir,
			rmdir = &fs_rmdir,
			chmod = &fs_chmod,
			chown = &fs_chown,
			resolve = &fs_resolve,
			...
		},
		dirfd = fd,
		getdents_bufsz = 32768, // 32 KiB
	};
	return &filesystem.fs;
};

// Sets the buffer size to use with the getdents(2) system call, for use with
// [[fs::iter]]. A larger buffer requires a larger runtime allocation, but can
// scan large directories faster. The default buffer size is 32 KiB.
//
// This function is not portable.
export fn dirfdfs_set_getdents_bufsz(fs: *fs::fs, sz: size) void = {
	assert(fs.open == &fs_open);
	let fs = fs: *os_filesystem;
	fs.getdents_bufsz = sz;
};

// Returns an [[io::file]] for this filesystem. This function is not portable.
export fn dirfile(fs: *fs::fs) io::file = {
	assert(fs.open == &fs_open);
	let fs = fs: *os_filesystem;
	return fs.dirfd;
};

fn errno_to_fs(err: rt::errno) fs::error = switch (err) {
case rt::ENOENT =>
	yield errors::noentry;
case rt::EEXIST =>
	yield errors::exists;
case rt::EACCES =>
	yield errors::noaccess;
case rt::EBUSY =>
	yield errors::busy;
case rt::ENOTDIR =>
	yield fs::wrongtype;
case rt::EOPNOTSUPP, rt::ENOSYS =>
	yield errors::unsupported;
case rt::EXDEV =>
	yield fs::cannotrename;
case =>
	yield errors::errno(err);
};

fn _fs_open(
	fs: *fs::fs,
	path: str,
	flags: int,
	mode: uint,
) (io::file | fs::error) = {
	let fs = fs: *os_filesystem;

	let fd = match (rt::openat(fs.dirfd, path, flags, mode)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let fd: int =>
		yield fd;
	};

	return io::fdopen(fd);
};

fn fsflags_to_bsd(flags: fs::flags) int = {
	let out = 0;
	if (flags & fs::flags::WRONLY > 0) {
		out |= rt::O_WRONLY;
	};
	if (flags & fs::flags::RDWR > 0) {
		out |= rt::O_RDWR;
	};
	if (flags & fs::flags::CREATE > 0) {
		out |= rt::O_CREAT;
	};
	if (flags & fs::flags::EXCL > 0) {
		out |= rt::O_EXCL;
	};
	if (flags & fs::flags::NOCTTY > 0) {
		out |= rt::O_NOCTTY;
	};
	if (flags & fs::flags::TRUNC > 0) {
		out |= rt::O_TRUNC;
	};
	if (flags & fs::flags::APPEND > 0) {
		out |= rt::O_APPEND;
	};
	if (flags & fs::flags::NONBLOCK > 0) {
		out |= rt::O_NONBLOCK;
	};
	if (flags & fs::flags::DSYNC > 0) {
		out |= rt::O_DSYNC;
	};
	if (flags & fs::flags::SYNC > 0) {
		out |= rt::O_SYNC;
	};
	if (flags & fs::flags::RSYNC > 0) {
		out |= rt::O_SYNC;
	};
	if (flags & fs::flags::DIRECTORY > 0) {
		out |= rt::O_DIRECTORY;
	};
	if (flags & fs::flags::NOFOLLOW > 0) {
		out |= rt::O_NOFOLLOW;
	};
	if (flags & fs::flags::CLOEXEC > 0) {
		out |= rt::O_CLOEXEC;
	};
	if (flags & fs::flags::PATH > 0) {
		abort("fs::flags::PATH is not supported on FreeBSD");
	};
	if (flags & fs::flags::NOATIME > 0) {
		abort("fs::flags::NOATIME is not supported on FreeBSD");
	};
	if (flags & fs::flags::TMPFILE > 0) {
		abort("fs::flags::TMPFILE is not supported on FreeBSD");
	};
	return out;
};

fn fs_open_file(
	fs: *fs::fs,
	path: str,
	flags: fs::flags...
) (io::file | fs::error) = {
	let oflags = fs::flags::RDONLY;
	if (len(flags) == 0z) {
		oflags |= fs::flags::NOCTTY | fs::flags::CLOEXEC;
	};
	for (let i = 0z; i < len(flags); i += 1z) {
		oflags |= flags[i];
	};
	return _fs_open(fs, path, fsflags_to_bsd(oflags), 0);
};

fn fs_open(
	fs: *fs::fs,
	path: str,
	flags: fs::flags...
) (io::handle | fs::error) = fs_open_file(fs, path, flags...)?;

fn fs_create_file(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flags...
) (io::file | fs::error) = {
	let oflags = fs::flags::RDONLY;
	if (len(flags) == 0z) {
		oflags |= fs::flags::NOCTTY | fs::flags::CLOEXEC;
	};
	for (let i = 0z; i < len(flags); i += 1z) {
		oflags |= flags[i];
	};
	oflags |= fs::flags::CREATE;
	return _fs_open(fs, path, fsflags_to_bsd(oflags), mode)?;
};

fn fs_create(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flags...
) (io::handle | fs::error) = {
	return fs_create_file(fs, path, mode, flags...)?;
};

fn fs_remove(fs: *fs::fs, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::unlinkat(fs.dirfd, path, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_rename(fs: *fs::fs, oldpath: str, newpath: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::renameat(fs.dirfd, oldpath, fs.dirfd, newpath)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_stat(fs: *fs::fs, path: str) (fs::filestat | fs::error) = {
	let fs = fs: *os_filesystem;
	let st = rt::st { ... };
	match (rt::fstatat(fs.dirfd, path, &st, rt::AT_SYMLINK_NOFOLLOW)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
	return fs::filestat {
		mask = fs::stat_mask::UID
			| fs::stat_mask::GID
			| fs::stat_mask::SIZE
			| fs::stat_mask::INODE
			| fs::stat_mask::ATIME
			| fs::stat_mask::MTIME
			| fs::stat_mask::CTIME,
		mode = st.mode: fs::mode,
		uid = st.uid,
		gid = st.gid,
		sz = st.sz: size,
		inode = st.ino,
		atime = time::instant {
			sec = st.atime.tv_sec,
			nsec = st.atime.tv_nsec,
		},
		mtime = time::instant {
			sec = st.mtime.tv_sec,
			nsec = st.mtime.tv_nsec,
		},
		ctime = time::instant {
			sec = st.ctime.tv_sec,
			nsec = st.ctime.tv_nsec,
		},
	};
};

fn fs_readlink(fs: *fs::fs, path: str) (str | fs::error) = {
	let fs = fs: *os_filesystem;
	static let buf: [rt::PATH_MAX]u8 = [0...];
	let z = match (rt::readlinkat(fs.dirfd, path, buf[..])) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let z: size =>
		yield z;
	};
	return strings::fromutf8(buf[..z]);
};

fn fs_subdir(fs: *fs::fs, path: str) (*fs::fs | fs::error) = {
	let fs = fs: *os_filesystem;
	let flags = rt::O_RDONLY | rt::O_CLOEXEC | rt::O_DIRECTORY;

	let fd: int = match (rt::openat(fs.dirfd, path, flags, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let fd: int =>
		yield fd;
	};

	return dirfdopen(fd);
};

fn fs_rmdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::unlinkat(fs.dirfd, path, rt::AT_REMOVEDIR)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_mkdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::mkdirat(fs.dirfd, path, 0o755)) {
	case let err: rt::errno =>
		switch (err) {
		case rt::EISDIR =>
			return errors::exists;
		case =>
			return errno_to_fs(err);
		};
	case void => void;
	};
};

fn fs_chmod(fs: *fs::fs, path: str, mode: fs::mode) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::fchmodat(fs.dirfd, path, mode: uint, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_chown(fs: *fs::fs, path: str, uid: uint, gid: uint) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::fchownat(fs.dirfd, path, uid, gid, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_resolve(fs: *fs::fs, path: str) str = {
	if (path::abs(path)) {
		return path;
	};
	// XXX: This approach might not be right if this fs is based on a subdir
	static let buf = path::buffer { ... };
	path::set(&buf, os::getcwd(), path)!;
	return path::string(&buf);
};

fn fs_close(fs: *fs::fs) void = {
	let fs = fs: *os_filesystem;
	rt::close(fs.dirfd)!;
};

// Based on musl's readdir
type os_iterator = struct {
	iter: fs::iterator,
	fd: int,
	buf_pos: size,
	buf_end: size,
	buf: []u8,
};

fn fs_iter(fs: *fs::fs, path: str) (*fs::iterator | fs::error) = {
	let fs = fs: *os_filesystem;
	let flags = rt::O_RDONLY | rt::O_CLOEXEC | rt::O_DIRECTORY;
	let fd: int = match (rt::openat(fs.dirfd, path, flags, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let fd: int =>
		yield fd;
	};

	let buf = match (rt::malloc(fs.getdents_bufsz)) {
	case let v: *void =>
		yield v: *[*]u8;
	case null =>
		return errors::nomem;
	};
	let iter = alloc(os_iterator {
		iter = fs::iterator {
			next = &iter_next,
		},
		fd = fd,
		buf = buf[..fs.getdents_bufsz],
		...
	});
	return &iter.iter;
};

fn iter_next(iter: *fs::iterator) (fs::dirent | void) = {
	let iter = iter: *os_iterator;
	if (iter.buf_pos >= iter.buf_end) {
		let n = rt::getdents(iter.fd,
			iter.buf: *[*]u8, len(iter.buf)) as size;
		if (n == 0) {
			rt::close(iter.fd)!;
			free(iter.buf);
			free(iter);
			return;
		};
		iter.buf_end = n;
		iter.buf_pos = 0;
	};
	let de = &iter.buf[iter.buf_pos]: *rt::freebsd11_dirent;
	iter.buf_pos += de.d_reclen;
	let name = strings::fromc(&de.d_name: *const char);

	let ftype: fs::mode = switch (de.d_type) {
	case rt::DT_UNKNOWN =>
		yield fs::mode::UNKNOWN;
	case rt::DT_FIFO =>
		yield fs::mode::FIFO;
	case rt::DT_CHR =>
		yield fs::mode::CHR;
	case rt::DT_DIR =>
		yield fs::mode::DIR;
	case rt::DT_BLK =>
		yield fs::mode::BLK;
	case rt::DT_REG =>
		yield fs::mode::REG;
	case rt::DT_LNK =>
		yield fs::mode::LINK;
	case rt::DT_SOCK =>
		yield fs::mode::SOCK;
	case =>
		yield fs::mode::UNKNOWN;
	};
	return fs::dirent {
		name = name,
		ftype = ftype,
	};
};
