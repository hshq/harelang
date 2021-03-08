use io;
use path;

// Closes a filesystem. The fs cannot be used after this function is called.
export fn close(fs: *fs) void = {
	match (fs.close) {
		null => void,
		f: *closefunc => f(fs),
	};
};

// Opens a file.
export fn open(fs: *fs, path: path::path, mode: io::mode) (*io::stream | error) = {
	return match (fs.open) {
		null => io::unsupported,
		f: *openfunc => f(fs, path, mode),
	};
};

// Creates a new file. The default file permissions are implementation defined.
export fn create(fs: *fs, path: path::path, mode: io::mode) (*io::stream | error) = {
	return match (fs.create) {
		null => io::unsupported,
		f: *createfunc => f(fs, path, mode),
	};
};

// Returns an iterator for a path, which yields the contents of a directory.
// Pass empty string to yield from the root. The order in which entries are
// returned is undefined.
export fn iter(fs: *fs, path: path::path) (*iterator | error) = {
	return match (fs.iter) {
		null => io::unsupported,
		f: *iterfunc => f(fs, path),
	};
};

// Obtains information about a file or directory. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(fs: *fs, path: path::path) (filestat | error) = {
	return match (fs.stat) {
		null => io::unsupported,
		f: *statfunc => f(fs, path),
	};
};

// Opens a new filesystem for a subdirectory. The subdirectory must be closed
// separately from the parent filesystem, and its lifetime can outlive that of
// its parent.
export fn subdir(fs: *fs, path: path::path) (*fs | error) = {
	return match (fs.subdir) {
		null => io::unsupported,
		f: *subdirfunc => f(fs, path),
	};
};

// Creates a directory.
export fn mkdir(fs: *fs, path: path::path) (void | error) = {
	return match (fs.mkdir) {
		null => io::unsupported,
		f: *mkdirfunc => f(fs, path),
	};
};

// Makes a directory, and all non-extant directories in its path.
export fn mkdirs(fs: *fs, path: path::path) (void | error) = {
	let parent = path::dirname(path);
	if (!path::equal(path, parent)) {
		match (mkdirs(fs, parent)) {
			exists => void,
			err: error => return err,
			void => void,
		};
	};
	return mkdir(fs, path);
};

// Creates a directory and returns a subdir for it. Some filesystems support
// doing this operation atomically, but if not, a fallback is used.
export fn mksubdir(fs: *fs, path: path::path) (*fs | error) = {
	return match (fs.mksubdir) {
		null => {
			mkdir(fs, path)?;
			subdir(fs, path);
		},
		f: *mksubdirfunc => f(fs, path),
	};
};

// Resolves a path to its absolute, normalized value. This consoldates ./ and
// ../ sequences, roots the path, and returns a new [path::path]. The caller
// must free the return value.
export fn resolve(fs: *fs, path: path::path) path::path = {
	match (fs.resolve) {
		f: *resolvefunc => return f(fs, path),
		null => void,
	};
	abort(); // TODO
};

// Returns the next directory entry from an interator, or void if none remain.
// It is a programming error to call this again after it has returned void. The
// file stat returned may only have the type bits set on the file mode; callers
// should call [fs::stat] to obtain the detailed file mode.
export fn next(iter: *iterator) (dirent | void) = iter.next(iter);
