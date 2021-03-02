use rt;
use strings;
use os;

// Forks the current process, returning the pid of the child (to the parent) and
// void (to the child), or an error.
export fn fork() (int | void | error) = match (rt::fork()) {
	err: rt::errno  => errno_to_os(err),
	i: (int | void) => i,
};

fn errno_errstr(data: *void) str = {
	const errno = data: uintptr: int: rt::errno;
	return rt::errstr(errno);
};

fn errno_to_os(err: rt::errno) os_error = {
	return os_error {
		string = &errno_errstr,
		data   = err: uintptr: *void,
	};
};

fn open(path: str) (platform_cmd | os_error) = {
	match (rt::access(path, rt::X_OK)) {
		err: rt::errno => errno_to_os(err),
		b: bool => if (!b) {
			return errno_to_os(rt::EACCES);
		},
	};
	// O_PATH is used because it allows us to use an executable for which we
	// have execute permissions, but not read permissions.
	return match (rt::open(path, rt::O_PATH, 0u)) {
		fd: int => fd,
		err: rt::errno => errno_to_os(err),
	};
};

fn platform_finish(cmd: *command) void = rt::close(cmd.platform);

fn platform_exec(cmd: *command) os_error = {
	// We don't worry about freeing the return values from strings::to_c
	// because once we exec(2) our heap is fried anyway
	let argv: []nullable *const char = alloc([], len(cmd.argv) + 1z);
	for (let i = 0z; i < len(cmd.argv); i += 1z) {
		append(argv, strings::to_c(cmd.argv[i]));
	};
	append(argv, null);

	let envp: nullable *[*]nullable *const char = null;
	if (len(cmd.envp) != 0) {
		let env: []nullable *const char = alloc([], len(cmd.envp) + 1);
		for (let i = 0z; i < len(cmd.envp); i += 1) {
			append(env, strings::to_c(cmd.envp[i]));
		};
		append(env, null);
		envp = env: *[*]nullable *const char;
	};

	return errno_to_os(rt::execveat(cmd.platform, strings::c_empty,
		argv: *[*]nullable *const char, envp, rt::AT_EMPTY_PATH));
};

fn platform_start(cmd: *command) (os_error | process) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (rt::pipe2(&pipe, rt::O_CLOEXEC)) {
		err: rt::errno => return errno_to_os(err),
		void => void,
	};

	match (rt::clone(null, 0, null, null, 0)) {
		err: rt::errno => return errno_to_os(err),
		pid: int => {
			rt::close(pipe[1]);
			let errno: int = 0;
			return match (rt::read(pipe[0], &errno, size(int))) {
				err: rt::errno => errno_to_os(err),
				n: size => switch (n) {
					size(int) => errno_to_os(errno),
					* => abort("Unexpected rt::read result"),
					0 => pid,
				},
			};
		},
		void => {
			rt::close(pipe[0]);
			let err = platform_exec(cmd);
			let errno = err.data: uintptr: int;
			rt::write(pipe[1], &errno, size(int));
			rt::exit(1);
		},
	};
};
