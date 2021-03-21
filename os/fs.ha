use fs;
use path;

// Provides an implementation of [fs::fs] for the host filesystem.
export let root: *fs::fs = null: *fs::fs;

// Provides an implementation of [fs::fs] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;

// Removes a file.
export fn remove(path: str) (void | fs::error) = fs::remove(cwd, path);

// Creates an [fs::iterator] for a given directory to read its contents.
export fn iterdir(path: str) (*fs::iterator | fs::error) = fs::iter(cwd, path);

// Reads all entries from a directory. The caller must free the return value
// with [fs::dirents_free].
export fn readdir(path: str) ([]fs::dirent | fs::error) = fs::readdir(cwd, path);

// Returns file information for a given path.
export fn stat(path: str) (fs::filestat | fs::error) = fs::stat(cwd, path);

// Opens a directory as a filesystem.
export fn diropen(path: str) (*fs::fs | fs::error) = fs::subdir(cwd, path);

// Creates a directory.
export fn mkdir(path: str) (void | fs::error) = fs::mkdir(cwd, path);

// Creates a directory, and all non-extant directories in its path.
export fn mkdirs(path: str) (void | fs::error) = fs::mkdirs(cwd, path);

// Removes a directory. The target directory must be empty; see [rmdirall] to
// remove its contents as well.
export fn rmdir(path: str) (void | fs::error) = fs::rmdir(cwd, path);

// Removes a directory, and anything in it.
export fn rmdirall(path: str) (void | fs::error) = fs::rmdirall(cwd, path);

// Creates a directory and returns a subdir for it. Some filesystems support
// doing this operation atomically, but if not, a fallback is used.
export fn mksubdir(path: str) (*fs::fs | fs::error) = fs::mksubdir(cwd, path);

// Changes mode flags on a file or directory. Type bits are discared.
export fn chmod(path: str, mode: fs::mode) (void | fs::error) = fs::chmod(cwd, path, mode);

// Resolves a path to its absolute, normalized value. This consoldates ./ and
// ../ sequences, roots the path, and returns a new path. The caller must free
// the return value.
export fn resolve(path: str) str = fs::resolve(cwd, path);
