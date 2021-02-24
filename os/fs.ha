use fs;

// Provides an implementation of [fs::fs] for the host filesystem.
export let root: *fs::fs = null: *fs::fs;

// Provides an implementation of [fs::fs] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;

// Creates an [fs::iterator] for a given directory to read its contents.
export fn iterdir(path: fs::path) (*fs::iterator | fs::error) =
	fs::iter(cwd, path);

// Reads all entries from a directory. The caller must free the return value
// with [fs::dirents_free].
export fn readdir(path: fs::path) ([]fs::dirent | fs::error) = 
	fs::readdir(cwd, path);

// Returns file information for a given path.
export fn stat(path: fs::path) (fs::filestat | fs::error) = fs::stat(cwd, path);

// Opens a directory as a filesystem.
export fn diropen(path: fs::path) (*fs::fs | fs::error) = fs::subdir(cwd, path);
