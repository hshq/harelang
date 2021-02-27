use fs;
use path;
use rt;
use strings;

@init fn init() void = {
	static let root_fs = os_filesystem { ... };
	let dirfd = rt::open("/",
		rt::O_RDONLY | rt::O_DIRECTORY | rt::O_CLOEXEC,
		0u) as int;
	root = static_dirfdopen(dirfd, &root_fs);

	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(rt::AT_FDCWD, &cwd_fs);
};

// Change the current working directory.
export fn chdir(target: (*fs::fs | ...path::path)) (void | fs::error) = {
	const path: []u8 = match (target) {
		fs: *fs::fs => {
			assert(fs.open == &fs_open);
			let fs = fs: *os_filesystem;
			return match (rt::fchdir(fs.dirfd)) {
				err: rt::errno => errno_to_io(err): fs::error,
				void => void,
			};
		},
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	return match (rt::chdir(path: *[*]u8: *const char)) {
		err: rt::errno => errno_to_io(err): fs::error,
		void => void,
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: path::path) (void | fs::error) = {
	const path: []u8 = match (target) {
		s: str  => strings::to_utf8(s),
		b: []u8 => b,
	};
	return match (rt::chroot(path: *[*]u8: *const char)) {
		err: rt::errno => errno_to_io(err): fs::error,
		void => void,
	};
};
