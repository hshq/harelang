use errors;
use fs;
use path;
use rt;
use strings;

@init fn init() void = {
	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(rt::AT_FDCWD, &cwd_fs);
};

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = strings::fromc(rt::getcwd() as *const char);

// Change the current working directory.
export fn chdir(target: (*fs::fs | str)) (void | fs::error) = {
	const path: str = match (target) {
		fs: *fs::fs => {
			assert(fs.open == &fs_open);
			let fs = fs: *os_filesystem;
			return match (rt::fchdir(fs.dirfd)) {
				err: rt::errno => errors::errno(err),
				_: void => void,
			};
		},
		s: str  => s,
	};
	return match (rt::chdir(path)) {
		err: rt::errno => errors::errno(err),
		_: void => void,
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: str) (void | fs::error) = {
	return match (rt::chroot(target)) {
		err: rt::errno => errors::errno(err),
		_: void => void,
	};
};
