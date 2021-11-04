use errors;
use io;
use path;

// Closes a filesystem. The fs cannot be used after this function is called.
export fn close(fs: *fs) void = {
	match (fs.close) {
	case null => void;
	case f: *closefunc =>
		f(fs);
	};
};

// Opens a file. If no flags are provided, the default read/write mode is
// RDONLY.
export fn open(fs: *fs, path: str, flags: flags...) (io::handle | error) = {
	match (fs.open) {
	case null =>
		return errors::unsupported;
	case f: *openfunc =>
		return f(fs, path, flags...);
	};
};

// Opens a file, as an [[io::file]]. This file will be backed by an open file
// handle on the host operating system, which may not be possible with all
// filesystem implementations (such cases will return [[io::unsupported]]).
//
// If no flags are provided, the default read/write mode is RDONLY.
export fn open_file(fs: *fs, path: str, flags: flags...) (io::file | error) = {
	match (fs.openfile) {
	case null =>
		return errors::unsupported;
	case f: *openfilefunc =>
		return f(fs, path, flags...);
	};
};

// Creates a new file and opens it for writing. If no flags are provided, the
// default read/write mode is WRONLY.
export fn create(
	fs: *fs,
	path: str,
	mode: mode,
	flags: flags...
) (io::handle | error) = {
	match (fs.create) {
	case null =>
		return errors::unsupported;
	case f: *createfunc =>
		return f(fs, path, mode, flags...);
	};
};

// Creates a new file, as an [[io::file]], and opens it for writing. This file
// will be backed by an open file handle on the host operating system, which may
// not be possible with all filesystem implementations (such cases will return
// [[io::unsupported]]).
//
// If no flags are provided, the default read/write mode is WRONLY.
export fn create_file(
	fs: *fs,
	path: str,
	mode: mode,
	flags: flags...
) (io::file | error) = {
	match (fs.createfile) {
	case null =>
		return errors::unsupported;
	case f: *createfilefunc =>
		return f(fs, path, mode, flags...);
	};
};

// Removes a file.
export fn remove(fs: *fs, path: str) (void | error) = {
	match (fs.remove) {
	case null =>
		return errors::unsupported;
	case f: *removefunc =>
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
	case f: *renamefunc =>
		return f(fs, oldpath, newpath);
	};
};

// Moves a file. This will use [[rename]] if possible, and will fall back to
// copy and remove if necessary.
export fn move(fs: *fs, oldpath: str, newpath: str) (void | error) = {
	match (rename(fs, oldpath, newpath)) {
	case (cannotrename | errors::unsupported) => void; // Fallback
	case err: error =>
		return err;
	case void =>
		return; // Success
	};
	// TODO:
	// - If an error occurs, remove the new file.
	// - Move non-regular files
	let st = fs::stat(fs, oldpath)?;
	assert(isfile(st.mode), "TODO: move non-regular files");
	let new = fs::create(fs, newpath, st.mode)?;
	defer io::close(new);
	let old = fs::open(fs, oldpath)?;
	defer io::close(old);
	io::copy(new, old)?;
	fs::remove(fs, oldpath)?;
};

// Returns an iterator for a path, which yields the contents of a directory.
// Pass empty string to yield from the root. The order in which entries are
// returned is undefined.
export fn iter(fs: *fs, path: str) (*iterator | error) = {
	match (fs.iter) {
	case null =>
		return errors::unsupported;
	case f: *iterfunc =>
		return f(fs, path);
	};
};

// Obtains information about a file or directory. If the target is a symlink,
// information is returned about the link, not its target.
export fn stat(fs: *fs, path: str) (filestat | error) = {
	match (fs.stat) {
	case null =>
		return errors::unsupported;
	case f: *statfunc =>
		return f(fs, path);
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

// Returns the path referred to by a symbolic link. The caller must free the
// return value.
export fn readlink(fs: *fs, path: str) (str | error) = {
	match (fs.readlink) {
	case null =>
		return errors::unsupported;
	case f: *readlinkfunc =>
		return f(fs, path);
	};
};

// Opens a new filesystem for a subdirectory. The subdirectory must be closed
// separately from the parent filesystem, and its lifetime can outlive that of
// its parent.
export fn subdir(fs: *fs, path: str) (*fs | error) = {
	match (fs.subdir) {
	case null =>
		return errors::unsupported;
	case f: *subdirfunc =>
		return f(fs, path);
	};
};

// Creates a directory.
export fn mkdir(fs: *fs, path: str) (void | error) = {
	match (fs.mkdir) {
	case null =>
		return errors::unsupported;
	case f: *mkdirfunc =>
		return f(fs, path);
	};
};

// Makes a directory, and all non-extant directories in its path.
export fn mkdirs(fs: *fs, path: str) (void | error) = {
	let parent = path::dirname(path);
	if (path != parent) {
		match (mkdirs(fs, parent)) {
		case errors::exists => void;
		case void => void;
		case err: error =>
			return err;
		};
	};
	match (mkdir(fs, path)) {
	case errors::exists => void;
	case void => void;
	case err: error =>
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
	case f: *rmdirfunc =>
		return f(fs, path);
	};
};

// Removes a directory, and anything in it.
export fn rmdirall(fs: *fs, path: str) (void | error) = {
	let it = iter(fs, path)?;
	for (true) {
		match (next(it)) {
		case ent: dirent =>
			if (ent.name == "." || ent.name == "..") {
				continue;
			};
			let p = path::join(path, ent.name);
			defer free(p);

			switch (ent.ftype & mode::DIR) {
			case mode::DIR =>
				rmdirall(fs, p)?;
			case =>
				remove(fs, p)?;
			};
		case void =>
			break;
		};
	};
	if (path != "") {
		return rmdir(fs, path);
	};
};

// Creates a directory and returns a subdir for it. Some filesystems support
// doing this operation atomically, but if not, a fallback is used.
export fn mksubdir(fs: *fs, path: str) (*fs | error) = {
	match (fs.mksubdir) {
	case null =>
		mkdir(fs, path)?;
		return subdir(fs, path);
	case f: *mksubdirfunc =>
		return f(fs, path);
	};
};

// Changes mode flags on a file or directory.
export fn chmod(fs: *fs, path: str, mode: mode) (void | error) = {
	match (fs.chmod) {
	case null =>
		return errors::unsupported;
	case f: *chmodfunc =>
		return f(fs, path, mode);
	};
};

// Changes ownership of a file.
export fn chown(fs: *fs, path: str, uid: uint, gid: uint) (void | error) = {
	match (fs.chown) {
	case null =>
		return errors::unsupported;
	case f: *chownfunc =>
		return f(fs, path, uid, gid);
	};
};

// Resolves a path to its absolute, normalized value. This consoldates ./ and
// ../ sequences, roots the path, and returns a new path. The caller must free
// the return value.
export fn resolve(fs: *fs, path: str) str = {
	match (fs.resolve) {
	case null => void;
	case f: *resolvefunc =>
		return f(fs, path);
	};
	abort(); // TODO
};

// Returns the next directory entry from an interator, or void if none remain.
// It is a programming error to call this again after it has returned void. The
// file stat returned may only have the type bits set on the file mode; callers
// should call [[fs::stat]] to obtain the detailed file mode.
export fn next(iter: *iterator) (dirent | void) = iter.next(iter);
