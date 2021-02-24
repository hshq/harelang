use fs;
use rt;

@init fn init() void = {
	static let root_fs = os_filesystem { ... };
	let dirfd = rt::open("/": *const char,
		rt::O_RDONLY | rt::O_DIRECTORY | rt::O_CLOEXEC, 0u) as int;
	root = static_dirfdopen(dirfd, &root_fs);

	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(rt::AT_FDCWD, &cwd_fs);
};
