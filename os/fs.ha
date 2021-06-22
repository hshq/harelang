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

// Reads all entries from a directory. The caller must free the return value
// with [[fs::dirents_free]].
export fn readdir(path: str) ([]fs::dirent | fs::error) = fs::readdir(cwd, path);

// Returns file information for a given path.
export fn stat(path: str) (fs::filestat | fs::error) = fs::stat(cwd, path);

// Opens a directory as a filesystem.
export fn diropen(path: str) (*fs::fs | fs::error) = fs::subdir(cwd, path);

// Creates a directory.
export fn mkdir(path: str) (void | fs::error) = fs::mkdir(cwd, path);

// Creates a directory, and all non-extant directories in its path.
export fn mkdirs(path: str) (void | fs::error) = fs::mkdirs(cwd, path);

// Removes a directory. The target directory must be empty; see [[rmdirall]] to
// remove its contents as well.
export fn rmdir(path: str) (void | fs::error) = fs::rmdir(cwd, path);

// Removes a directory, and anything in it.
export fn rmdirall(path: str) (void | fs::error) = fs::rmdirall(cwd, path);

// Creates a directory and returns a subdir for it. Some filesystems support
// doing this operation atomically, but if not, a fallback is used.
export fn mksubdir(path: str) (*fs::fs | fs::error) = fs::mksubdir(cwd, path);

// Changes mode flags on a file or directory. Type bits are discared.
export fn chmod(path: str, mode: fs::mode) (void | fs::error) = fs::chmod(cwd, path, mode);

// Changes ownership of a file.
export fn chown(path: str, uid: uint, gid: uint) (void | fs::error) = fs::chown(cwd, path, uid, gid);

// Resolves a path to its absolute, normalized value. This consoldates ./ and
// ../ sequences, roots the path, and returns a new path. The caller must free
// the return value.
export fn resolve(path: str) str = fs::resolve(cwd, path);

// Opens a file.
//
// If no flags are provided, [[fs::flags::RDONLY]], [[fs::flags::NOCTTY]],
// [[fs::flags::CLOEXEC]] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
export fn open(path: str, flags: fs::flags...) (*io::stream | fs::error) =
	fs::open(cwd, path, flags...);

// Creates a new file and opens it for writing.
//
// If no flags are provided, [[fs::flags::WRONLY]], [[fs::flags::NOCTTY]],
// [[fs::flags::CLOEXEC]] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
//
// Only the permission bits of the mode are used. If other bits are set, they
// are discarded.
export fn create(
	path: str,
	mode: fs::mode,
	flags: fs::flags...
) (*io::stream | fs::error) = fs::create(cwd, path, mode, flags...);
