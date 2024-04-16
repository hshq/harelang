// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use io;
use path;
use time;

// Provides an implementation of [[fs::fs]] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;

// Removes a file.
export fn remove(path: str) (void | fs::error) = fs::remove(cwd, path);

// Renames a file. This generally only works if the source and destination path
// are both on the same filesystem. See [[move]] for an implementation which
// falls back on a "copy & remove" procedure in this situation.
export fn rename(oldpath: str, newpath: str) (void | fs::error) =
	fs::rename(cwd, oldpath, newpath);

// Moves a file. This will use [[rename]] if possible, and will fall back to
// copy and remove if necessary.
export fn move(oldpath: str, newpath: str) (void | fs::error) =
	fs::move(cwd, oldpath, newpath);

// Creates an [[fs::iterator]] for a given directory to read its contents. The
// user should call [[fs::next]] to enumerate entries, and [[fs::finish]] when
// done using the object.
export fn iter(path: str) (*fs::iterator | fs::error) = fs::iter(cwd, path);

// Reads all entries from a directory. The caller must free the return value
// with [[fs::dirents_free]].
export fn readdir(path: str) ([]fs::dirent | fs::error) = fs::readdir(cwd, path);

// Returns file information for a given path. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(path: str) (fs::filestat | fs::error) = fs::stat(cwd, path);

// Returns file information for an [[io::file]].
export fn fstat(fd: io::file) (fs::filestat | fs::error) = fs::fstat(cwd, fd);

// Returns true if a node exists at the given path, or false if not.
//
// Note that testing for file existence before using the file can often lead to
// race conditions. If possible, prefer to simply attempt to use the file (e.g.
// via "open"), and handle the resulting error should the file not exist.
export fn exists(path: str) bool = fs::exists(cwd, path);

// Creates a directory.
export fn mkdir(path: str, mode: fs::mode) (void | fs::error) = fs::mkdir(cwd, path, mode);

// Creates a directory, and all non-extant directories in its path.
export fn mkdirs(path: str, mode: fs::mode) (void | fs::error) = fs::mkdirs(cwd, path, mode);

// Removes a directory. The target directory must be empty; see [[rmdirall]] to
// remove its contents as well.
export fn rmdir(path: str) (void | fs::error) = fs::rmdir(cwd, path);

// Removes a directory, and anything in it.
export fn rmdirall(path: str) (void | fs::error) = fs::rmdirall(cwd, path);

// Changes mode flags on a file or directory. Type bits are discared.
export fn chmod(path: str, mode: fs::mode) (void | fs::error) = fs::chmod(cwd, path, mode);

// Changes mode flags on a [[io::file]]. Type bits are discared.
export fn fchmod(fd: io::file, mode: fs::mode) (void | fs::error) = fs::fchmod(cwd, fd, mode);

// Changes ownership of a file.
export fn chown(path: str, uid: uint, gid: uint) (void | fs::error) = fs::chown(cwd, path, uid, gid);

// Changes ownership of a [io::file]].
export fn fchown(fd: io::file, uid: uint, gid: uint) (void | fs::error) = fs::fchown(cwd, fd, uid, gid);

// Changes the access and modification time of a file. A void value will leave
// the corresponding time unchanged.
export fn chtimes(
	path: str,
	atime: (time::instant | void),
	mtime: (time::instant | void)
) (void | fs::error) = fs::chtimes(cwd, path, atime, mtime);

// Changes the access and modification time of an [[io::file]]. A void value
// will leave the corresponding time unchanged.
export fn fchtimes(
        fd: io::file,
        atime: (time::instant | void),
        mtime: (time::instant | void)
) (void | fs::error) = fs::fchtimes(cwd, fd, atime, mtime);

// Resolves a path to its absolute, normalized value. Relative paths will be
// rooted (if supported by the host filesystem), and "." and ".." components
// will be reduced. This function does not follow symlinks; see [[realpath]] if
// you need this behavior. The return value is statically allocated; use
// [[strings::dup]] to extend its lifetime.
export fn resolve(path: str) str = fs::resolve(cwd, path);

// Returns the path referred to by a symbolic link. The return value is
// statically allocated and will be overwritten on subsequent calls.
export fn readlink(path: str) (str | fs::error) = fs::readlink(cwd, path);

// Creates a new (hard) link at 'new' for the file at 'old'.
export fn link(old: str, new: str) (void | fs::error) = fs::link(cwd, old, new);

// Creates a new symbolic link at 'path' which points to 'target'.
export fn symlink(target: str, path: str) (void | fs::error) =
	fs::symlink(cwd, target, path);

// Opens a file.
//
// [[fs::flag::CREATE]] isn't very useful with this function, since the new
// file's mode is set to zero. For this use-case, use [[create]] instead.
export fn open(
	path: str,
	flags: fs::flag = fs::flag::RDONLY,
) (io::file | fs::error) = fs::open_file(cwd, path, flags);

// Creates a new file with the given mode if it doesn't already exist and opens
// it for writing.
//
// Only the permission bits of the mode are used. If other bits are set, they
// are discarded.
//
// To create a file without opening it, see [[mkfile]].
export fn create(
	path: str,
	mode: fs::mode,
	flags: fs::flag = fs::flag::WRONLY | fs::flag::TRUNC,
) (io::file | fs::error) = fs::create_file(cwd, path, mode, flags);

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components.
//
// This function is a thin shim over [[fs::realpath]], and the return value is
// statically allocated by [[fs::realpath]]. Thus, calls to this function or to
// [[fs::realpath]] will overwrite the return value of either function.
export fn realpath(path: str) (str | fs::error) = fs::realpath(cwd, path);

// Opens a directory as a filesystem.
export fn diropen(path: str) (*fs::fs | fs::error) = {
	const file = open(path, fs::flag::DIRECTORY | fs::flag::RDONLY)?;
	return dirfdopen(file);
};
