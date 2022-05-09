// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Jon Eskin <eskinjp@gmail.com>
use fs;
use io;
use path;

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

// Creates an [[fs::iterator]] for a given directory to read its contents.
export fn iter(path: str) (*fs::iterator | fs::error) = fs::iter(cwd, path);

// Frees state associated with a directory iterator.
export fn finish(iter: *fs::iterator) void = fs::finish(iter);

// Reads all entries from a directory. The caller must free the return value
// with [[fs::dirents_free]].
export fn readdir(path: str) ([]fs::dirent | fs::error) = fs::readdir(cwd, path);

// Returns file information for a given path. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(path: str) (fs::filestat | fs::error) = fs::stat(cwd, path);

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

// Changes ownership of a file.
export fn chown(path: str, uid: uint, gid: uint) (void | fs::error) = fs::chown(cwd, path, uid, gid);

// Resolves a path to its absolute, normalized value. Relative paths will be
// rooted (if supported by the host filesystem), and "." and ".." components
// will be reduced. This function does not follow symlinks; see [[realpath]] if
// you need this behavior. The return value is statically allocated; use
// [[strings::dup]] to extend its lifetime.
export fn resolve(path: str) str = fs::resolve(cwd, path);

// Returns the path referred to by a symbolic link. The return value is
// statically allocated and will be overwritten on subsequent calls.
export fn readlink(path: str) (str | fs::error) = fs::readlink(cwd, path);

// Opens a file.
//
// If no flags are provided, [[fs::flags::RDONLY]] is used when opening the
// file.
export fn open(path: str, flags: fs::flags...) (io::file | fs::error) =
	fs::open_file(cwd, path, flags...);

// Creates a new file and opens it for writing.
//
// If no flags are provided, [[fs::flags::WRONLY]] is used when opening the
// file.
//
// Only the permission bits of the mode are used. If other bits are set, they
// are discarded.
export fn create(
	path: str,
	mode: fs::mode,
	flags: fs::flags...
) (io::file | fs::error) = fs::create_file(cwd, path, mode, flags...);

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components.
//
// This function is a thin shim over [[fs::realpath]], and the return value is
// statically allocated by [[fs::realpath]]. Thus, calls to this function or to
// [[fs::realpath]] will overwrite the return value of either function.
export fn realpath(path: str) (str | fs::error) = fs::realpath(cwd, path);

// Opens a directory as a filesystem.
export fn diropen(path: str) (*fs::fs | fs::error) = {
	const file = open(path, fs::flags::DIRECTORY | fs::flags::RDONLY)?;
	return dirfdopen(file);
};
