// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use path;
use time;

// Closes a filesystem. The fs cannot be used after this function is called.
export fn close(fs: *fs) void = {
	match (fs.close) {
	case null => void;
	case let f: *closefunc =>
		f(fs);
	};
};

// Opens a file.
//
// [[flag::CREATE]] isn't very useful with this function, since the new file's
// mode is set to zero. For this use-case, use [[create]] instead.
export fn open(
	fs: *fs,
	path: str,
	flags: flag = flag::RDONLY,
) (io::handle | error) = {
	match (fs.open) {
	case null =>
		return errors::unsupported;
	case let f: *openfunc =>
		return f(fs, path, flags);
	};
};

// Opens a file, as an [[io::file]]. This file will be backed by an open file
// handle on the host operating system, which may not be possible with all
// filesystem implementations (such cases will return [[io::unsupported]]).
//
// [[flag::CREATE]] isn't very useful with this function, since the new file's
// mode is set to zero. For this use-case, use [[create_file]] instead.
export fn open_file(
	fs: *fs,
	path: str,
	flags: flag = flag::RDONLY,
) (io::file | error) = {
	match (fs.openfile) {
	case null =>
		return errors::unsupported;
	case let f: *openfilefunc =>
		return f(fs, path, flags);
	};
};

// Creates a new file with the given mode if it doesn't already exist, and opens
// it for writing.
export fn create(
	fs: *fs,
	path: str,
	mode: mode,
	flags: flag = flag::WRONLY | flag::TRUNC,
) (io::handle | error) = {
	match (fs.create) {
	case null =>
		return errors::unsupported;
	case let f: *createfunc =>
		return f(fs, path, mode, flags);
	};
};

// Creates a new file with the given mode if it doesn't already exist, and opens
// it as an [[io::file]] for writing. This file will be backed by an open file
// handle on the host operating system, which may not be possible with all
// filesystem implementations (such cases will return [[io::unsupported]]).
export fn create_file(
	fs: *fs,
	path: str,
	mode: mode,
	flags: flag = flag::WRONLY | flag::TRUNC,
) (io::file | error) = {
	match (fs.createfile) {
	case null =>
		return errors::unsupported;
	case let f: *createfilefunc =>
		return f(fs, path, mode, flags);
	};
};

// Removes a file.
export fn remove(fs: *fs, path: str) (void | error) = {
	match (fs.remove) {
	case null =>
		return errors::unsupported;
	case let f: *removefunc =>
		return f(fs, path);
	};
};

// Renames a file. This generally only works if the source and destination path
// are both on the same filesystem. See [[move]] for an implementation which
// falls back on a "copy & remove" procedure in this situation.
export fn rename(fs: *fs, oldpath: str, newpath: str) (void | error) = {
	match (fs.rename) {
	case null =>
		return errors::unsupported;
	case let f: *renamefunc =>
		return f(fs, oldpath, newpath);
	};
};

// Moves a file. This will use [[rename]] if possible, and will fall back to
// copy and remove if necessary.
export fn move(fs: *fs, oldpath: str, newpath: str) (void | error) = {
	match (rename(fs, oldpath, newpath)) {
	case (cannotrename | errors::unsupported) => void; // Fallback
	case let err: error =>
		return err;
	case void =>
		return; // Success
	};
	// TODO:
	// - Move non-regular files
	let st = stat(fs, oldpath)?;
	assert(isfile(st.mode), "TODO: move non-regular files");
	let old = open(fs, oldpath)?;
	let new = match (create(fs, newpath, st.mode)) {
	case let h: io::handle =>
		yield h;
	case let err: error =>
		io::close(old): void;
		return err;
	};
	match (io::copy(new, old)) {
	case let err: io::error =>
		io::close(new): void;
		io::close(old): void;
		remove(fs, newpath)?;
		return err;
	case size => void;
	};
	io::close(new)?;
	io::close(old)?;
	remove(fs, oldpath)?;
};

// Returns an iterator for a path, which yields the contents of a directory.
// Pass empty string to yield from the root. The order in which entries are
// returned is undefined. The return value must be finished with [[finish]].
export fn iter(fs: *fs, path: str) (*iterator | error) = {
	match (fs.iter) {
	case null =>
		return errors::unsupported;
	case let f: *iterfunc =>
		return f(fs, path);
	};
};

// Frees state associated with an [[iterator]].
export fn finish(iter: *iterator) void = {
	match (iter.finish) {
	case null => void;
	case let f: *finishfunc =>
		return f(iter);
	};
};

// Obtains information about a file or directory. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(fs: *fs, path: str) (filestat | error) = {
	match (fs.stat) {
	case null =>
		return errors::unsupported;
	case let f: *statfunc =>
		return f(fs, path);
	};
};

// Obtains information about an [[io::file]].
export fn fstat(fs: *fs, fd: io::file) (filestat | error) = {
	match (fs.fstat) {
	case null =>
		return errors::unsupported;
	case let f: *fstatfunc =>
		return f(fs, fd);
	};
};

// Returns true if a node exists at the given path, or false if not.
//
// Note that testing for file existence before using the file can often lead to
// race conditions. If possible, prefer to simply attempt to use the file (e.g.
// via "open"), and handle the resulting error should the file not exist.
export fn exists(fs: *fs, path: str) bool = {
	match (stat(fs, path)) {
	case filestat =>
		return true;
	case error =>
		return false;
	};
};

// Returns the path referred to by a symbolic link. The return value is
// statically allocated and will be overwritten on subsequent calls.
export fn readlink(fs: *fs, path: str) (str | error) = {
	match (fs.readlink) {
	case null =>
		return errors::unsupported;
	case let f: *readlinkfunc =>
		return f(fs, path);
	};
};

// Creates a directory.
export fn mkdir(fs: *fs, path: str, mode: mode) (void | error) = {
	match (fs.mkdir) {
	case null =>
		return errors::unsupported;
	case let f: *mkdirfunc =>
		return f(fs, path, mode);
	};
};

// Makes a directory, and all non-extant directories in its path.
export fn mkdirs(fs: *fs, path: str, mode: mode) (void | error) = {
	let parent = path::dirname(path);
	if (path != parent) {
		match (mkdirs(fs, parent, mode)) {
		case errors::exists => void;
		case void => void;
		case let err: error =>
			return err;
		};
	};
	match (mkdir(fs, path, mode)) {
	case errors::exists => void;
	case void => void;
	case let err: error =>
		return err;
	};
};

// Removes a directory. The target directory must be empty; see [[rmdirall]] to
// remove its contents as well.
export fn rmdir(fs: *fs, path: str) (void | error) = {
	if (path == "") {
		return errors::invalid;
	};
	match (fs.rmdir) {
	case null =>
		return errors::unsupported;
	case let f: *rmdirfunc =>
		return f(fs, path);
	};
};

// Changes mode flags on a file or directory.
export fn chmod(fs: *fs, path: str, mode: mode) (void | error) = {
	match (fs.chmod) {
	case null =>
		return errors::unsupported;
	case let f: *chmodfunc =>
		return f(fs, path, mode);
	};
};

// Changes mode flags on a [[io::file]].
export fn fchmod(fs: *fs, fd: io::file, mode: mode) (void | error) = {
	match (fs.fchmod) {
	case null =>
		return errors::unsupported;
	case let f: *fchmodfunc =>
		return f(fd, mode);
	};
};

// Changes ownership of a file.
export fn chown(fs: *fs, path: str, uid: uint, gid: uint) (void | error) = {
	match (fs.chown) {
	case null =>
		return errors::unsupported;
	case let f: *chownfunc =>
		return f(fs, path, uid, gid);
	};
};

// Changes ownership of a [[io::file]].
export fn fchown(fs: *fs, fd: io::file, uid: uint, gid: uint) (void | error) = {
	match (fs.fchown) {
	case null =>
		return errors::unsupported;
	case let f: *fchownfunc =>
		return f(fd, uid, gid);
	};
};

// Changes the access and modification time of a file. A void value will leave
// the corresponding time unchanged.
export fn chtimes(
	fs: *fs,
	path: str,
	atime: (time::instant | void),
	mtime: (time::instant | void)
) (void | error) = {
	match (fs.chtimes) {
	case null =>
		return errors::unsupported;
	case let f: *chtimesfunc =>
		return f(fs, path, atime, mtime);
	};
};

// Changes the access and modification time of an [[io::file]]. A void value
// will leave the corresponding time unchanged.
export fn fchtimes(
	fs: *fs,
	fd: io::file,
	atime: (time::instant | void),
	mtime: (time::instant | void)
) (void | error) = {
	match (fs.fchtimes) {
	case null =>
		return errors::unsupported;
	case let f: *fchtimesfunc =>
		return f(fd, atime, mtime);
	};
};

// Resolves a path to its absolute, normalized value. Relative paths will be
// rooted (if supported by the fs implementation), and "." and ".." components
// will be reduced. This function does not follow symlinks; see [[realpath]] if
// you need this behavior. The return value is statically allocated; use
// [[strings::dup]] to extend its lifetime.
export fn resolve(fs: *fs, path: str) str = {
	match (fs.resolve) {
	case null => void;
	case let f: *resolvefunc =>
		return f(fs, path);
	};
	static let buf = path::buffer { ... };
	path::set(&buf, path)!;
	return path::string(&buf);
};

// Creates a new (hard) link at 'new' for the file at 'old'.
export fn link(fs: *fs, old: str, new: str) (void | error) = {
	match (fs.link) {
	case null =>
		return errors::unsupported;
	case let f: *linkfunc =>
		return f(fs, old, new);
	};
};

// Creates a new symbolic link at 'path' which points to 'target'.
export fn symlink(fs: *fs, target: str, path: str) (void | error) = {
	match (fs.symlink) {
	case null =>
		return errors::unsupported;
	case let f: *symlinkfunc =>
		return f(fs, target, path);
	};
};

// Returns the next directory entry from an iterator, or void if none remain.
// '.' and '..' are skipped. It is a programming error to call this again after
// it has returned void. Calling this again after an error is safe. The list is
// not guaranteed to be complete when an error has been returned. The file stat
// returned may only have the type bits set on the file mode; callers should
// call [[stat]] to obtain the detailed file mode.
export fn next(iter: *iterator) (dirent | done | error) = iter.next(iter);
