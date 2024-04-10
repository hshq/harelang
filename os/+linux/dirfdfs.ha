// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use errors;
use fs;
use io;
use path;
use rt;
use strings;
use time;
use types::c;

// Controls how symlinks are followed (or not) in a dirfd filesystem. Support
// for this feature varies, you should gate usage of this enum behind a build
// tag.
//
// Note that on Linux, specifying BENEATH or IN_ROOT will also disable magic
// symlinks.
export type resolve_flag = enum u64 {
	NORMAL = 0,

	// Does not allow symlink resolution to occur for any symlinks which
	// would refer to any anscestor of the fd directory. This disables all
	// absolute symlinks, and any call to open or create with an absolute
	// path.
	BENEATH = rt::RESOLVE_BENEATH | rt::RESOLVE_NO_MAGICLINKS,

	// Treat the directory fd as the root directory. This affects
	// open/create for absolute paths, as well as absolute path resolution
	// of symlinks. The effects are similar to chroot.
	IN_ROOT = rt::RESOLVE_IN_ROOT | rt::RESOLVE_NO_MAGICLINKS,

	// Disables symlink resolution entirely.
	NO_SYMLINKS = rt::RESOLVE_NO_SYMLINKS,

	// Disallows traversal of mountpoints during path resolution. This is
	// not recommended for general use, as bind mounts are extensively used
	// on many systems.
	NO_XDEV = rt::RESOLVE_NO_XDEV,
};

type os_filesystem = struct {
	fs: fs::fs,
	dirfd: int,
	resolve: resolve_flag,
	getdents_bufsz: size,
};

// Opens a file descriptor as an [[fs::fs]]. This file descriptor must be a
// directory file. The file will be closed when the fs is closed.
export fn dirfdopen(
	fd: io::file,
	resolve_flags: resolve_flag = resolve_flag::NORMAL,
) *fs::fs = {
	let ofs = alloc(os_filesystem { resolve = resolve_flags, ... });
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
			fstat = &fs_fstat,
			readlink = &fs_readlink,
			mkdir = &fs_mkdir,
			rmdir = &fs_rmdir,
			chmod = &fs_chmod,
			fchmod = &fs_fchmod,
			chown = &fs_chown,
			fchown = &fs_fchown,
			chtimes = &fs_chtimes,
			fchtimes = &fs_fchtimes,
			resolve = &fs_resolve,
			link = &fs_link,
			symlink = &fs_symlink,
			...
		},
		dirfd = fd,
		getdents_bufsz = 32768, // 32 KiB
		...
	};
	return &filesystem.fs;
};

// Clones a dirfd filesystem, optionally adding additional [[resolve_flag]]
// constraints.
export fn dirfs_clone(
	fs: *fs::fs,
	resolve_flags: resolve_flag = resolve_flag::NORMAL,
) *fs::fs = {
	assert(fs.open == &fs_open);
	let fs = fs: *os_filesystem;
	let new = alloc(*fs);
	fs.resolve |= resolve_flags;
	new.dirfd = rt::fcntl(new.dirfd, rt::F_DUPFD_CLOEXEC, 0) as int;
	return &new.fs;
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

fn errno_to_fs(err: rt::errno) fs::error = {
	switch (err) {
	case rt::ENOENT =>
		return errors::noentry;
	case rt::EEXIST =>
		return errors::exists;
	case rt::EACCES =>
		return errors::noaccess;
	case rt::EBUSY =>
		return errors::busy;
	case rt::ENOTDIR =>
		return fs::wrongtype;
	case rt::EOPNOTSUPP, rt::ENOSYS =>
		return errors::unsupported;
	case rt::EXDEV =>
		return fs::cannotrename;
	case =>
		return errors::errno(err);
	};
};

fn _fs_open(
	fs: *fs::fs,
	path: str,
	oh: *rt::open_how,
) (io::file | fs::error) = {
	let fs = fs: *os_filesystem;

	oh.resolve = fs.resolve;

	let fd = match (rt::openat2(fs.dirfd, path, oh, size(rt::open_how))) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let fd: int =>
		yield fd;
	};

	return io::fdopen(fd);
};

fn fs_open_file(
	fs: *fs::fs,
	path: str,
	flags: fs::flag,
) (io::file | fs::error) = {
	flags ^= fs::flag::CTTY | fs::flag::NOCLOEXEC; // invert NOCTTY/CLOEXEC

	if ((flags & fs::flag::DIRECTORY) == fs::flag::DIRECTORY) {
		// This is arch-specific
		flags &= ~fs::flag::DIRECTORY;
		flags |= rt::O_DIRECTORY: fs::flag;
	};

	let oh = rt::open_how {
		flags = flags: u64,
		...
	};
	return _fs_open(fs, path, &oh);
};

fn fs_open(
	fs: *fs::fs,
	path: str,
	flags: fs::flag,
) (io::handle | fs::error) = fs_open_file(fs, path, flags)?;

fn fs_create_file(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flag,
) (io::file | fs::error) = {
	flags ^= fs::flag::CTTY | fs::flag::NOCLOEXEC; // invert NOCTTY/CLOEXEC
	flags |= fs::flag::CREATE;

	let oh = rt::open_how {
		flags = flags: u64,
		mode = mode: u64,
		...
	};
	return _fs_open(fs, path, &oh)?;
};

fn fs_create(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flag,
) (io::handle | fs::error) = {
	return fs_create_file(fs, path, mode, flags)?;
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
	match (rt::renameat(fs.dirfd, oldpath, fs.dirfd, newpath, 0)) {
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
	return st_to_filestat(&st);
};

fn fs_fstat(fs: *fs::fs, fd: io::file) (fs::filestat | fs::error) = {
	let fs = fs: *os_filesystem;
	let st = rt::st { ... };
	match (rt::fstatat(fd, "", &st, rt::AT_EMPTY_PATH)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
	return st_to_filestat(&st);
};

fn st_to_filestat(st: *rt::st) fs::filestat = {
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
		sz = st.sz,
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
		switch (err) {
		case rt::EINVAL =>
			return fs::wrongtype;
		case =>
			return errno_to_fs(err);
		};
	case let z: size =>
		yield z;
	};
	return strings::fromutf8(buf[..z])!;
};

fn fs_rmdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::unlinkat(fs.dirfd, path, rt::AT_REMOVEDIR)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_mkdir(fs: *fs::fs, path: str, mode: fs::mode) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::mkdirat(fs.dirfd, path, mode: uint)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
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

fn fs_fchmod(fd: io::file, mode: fs::mode) (void | fs::error) = {
	match (rt::fchmod(fd, mode: uint)) {
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

fn fs_fchown(fd: io::file, uid: uint, gid: uint) (void | fs::error) = {
	match (rt::fchown(fd, uid, gid)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn instant_to_timespec(time: (time::instant | void)) rt::timespec = {
	match (time) {
	case let t: time::instant =>
		return time::instant_to_timespec(t);
	case void =>
		return rt::timespec{
			tv_sec = rt::UTIME_OMIT,
			tv_nsec = rt::UTIME_OMIT
		};
	};
};

fn fs_chtimes(fs: *fs::fs, path: str, atime: (time::instant | void),
		mtime: (time::instant | void)) (void | fs::error) = {
	let utimes: [2]rt::timespec = [
		instant_to_timespec(atime),
		instant_to_timespec(mtime),
	];
        let fs = fs: *os_filesystem;
        match (rt::utimensat(fs.dirfd, path, &utimes, 0)) {
        case let err: rt::errno =>
                return errno_to_fs(err);
        case void => void;
        };
};

fn fs_fchtimes(fd: io::file, atime: (time::instant | void),
		mtime: (time::instant | void)) (void | fs::error) = {
	let utimes: [2]rt::timespec = [
		instant_to_timespec(atime),
		instant_to_timespec(mtime),
	];
        match (rt::futimens(fd, &utimes)) {
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
	path::set(&buf, getcwd(), path)!;
	return path::string(&buf);
};

fn fs_link(fs: *fs::fs, old: str, new: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::linkat(fs.dirfd, old, fs.dirfd, new, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_symlink(fs: *fs::fs, target: str, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::symlinkat(target, fs.dirfd, path)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_close(fs: *fs::fs) void = {
	let fs = fs: *os_filesystem;
	rt::close(fs.dirfd)!;
	free(fs);
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
	let oh = rt::open_how {
		flags = (rt::O_RDONLY | rt::O_CLOEXEC | rt::O_DIRECTORY): u64,
		...
	};
	let fd: int = match (rt::openat2(fs.dirfd, path,
			&oh, size(rt::open_how))) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case let fd: int =>
		yield fd;
	};

	let buf = match (rt::malloc(fs.getdents_bufsz)) {
	case let v: *opaque =>
		yield v: *[*]u8;
	case null =>
		return errors::nomem;
	};
	let iter = alloc(os_iterator {
		iter = fs::iterator {
			next = &iter_next,
			finish = &iter_finish,
		},
		fd = fd,
		buf = buf[..fs.getdents_bufsz],
		...
	});
	return &iter.iter;
};

fn iter_next(iter: *fs::iterator) (fs::dirent | done | fs::error) = {
	let iter = iter: *os_iterator;
	if (iter.buf_pos >= iter.buf_end) {
		let n = match (rt::getdents64(iter.fd,
			iter.buf: *[*]u8, len(iter.buf))) {
		case let err: rt::errno =>
			return errno_to_fs(err);
		case let n: size =>
			yield n;
		};
		if (n == 0) {
			return done;
		};
		iter.buf_end = n;
		iter.buf_pos = 0;
	};
	let de = &iter.buf[iter.buf_pos]: *rt::dirent64;
	iter.buf_pos += de.d_reclen;
	let name = c::tostr(&de.d_name: *const c::char)?;
	if (name == "." || name == "..") {
		return iter_next(iter);
	};

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

fn iter_finish(iter: *fs::iterator) void = {
	let iter = iter: *os_iterator;
	rt::close(iter.fd)!;
	free(iter.buf);
	free(iter);
};
