use io;

// Closes a filesystem. The fs cannot be used after this function is called.
export fn close(fs: *fs) void = {
	match (fs.close) {
		null => void,
		f: *closefunc => f(fs),
	};
};

// Opens a file.
export fn open(fs: *fs, path: path, mode: io::mode) (*io::stream | error) = {
	return match (fs.open) {
		null => io::unsupported,
		f: *openfunc => f(fs, path, mode),
	};
};

// Creates a new file.
export fn create(fs: *fs, path: path, mode: io::mode) (*io::stream | error) = {
	return match (fs.create) {
		null => io::unsupported,
		f: *createfunc => f(fs, path, mode),
	};
};

// Returns an iterator for a path, which yields the contents of a directory.
// Pass empty string to yield from the root.
export fn iter(fs: *fs, path: path) (*iterator | error) = {
	return match (fs.iter) {
		null => io::unsupported,
		f: *iterfunc => f(fs, path),
	};
};

// Obtains information about a file or directory. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(fs: *fs, path: path) (filestat | error) = {
	return match (fs.stat) {
		null => io::unsupported,
		f: *statfunc => f(fs, path),
	};
};

// Opens a new filesystem for a subdirectory.
export fn subdir(fs: *fs, path: path) (*fs | error) = {
	return match (fs.subdir) {
		null => io::unsupported,
		f: *subdirfunc => f(fs, path),
	};
};
