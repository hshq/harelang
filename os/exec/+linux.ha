use rt;
use strings;
use os;

export type platform = int;

// An error provided by the operating system.
export type os_error = struct {
	string: *fn(data: *void) str,
	data: *void,
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

fn open(path: str) (platform | os_error) = {
	return match (rt::open(path: *const char, rt::O_RDONLY, 0u)) {
		fd: int => fd,
		err: rt::errno => errno_to_os(err),
	};
};

fn platform_finish(cmd: *command) void = {
	rt::close(cmd.data);
};

fn platform_exec(cmd: *command) os_error = {
	let argv = alloc([]nullable *const char, [], len(cmd.argv) + 1z);
	for (let i = 0z; i < len(cmd.argv); i += 1z) {
		append(argv, cmd.argv[i]: *const char);
	};
	append(argv, null);

	let envp: nullable *[*]nullable *const char = null;
	if (len(cmd.envp) != 0z) {
		let env = alloc([]nullable *const char, [], len(cmd.envp) + 1z);
		for (let i = 0z; i < len(cmd.envp); i += 1z) {
			append(env, cmd.envp[i]: *const char);
		};
		append(env, null);
		envp = env: *[*]nullable *const char;
	};

	return errno_to_os(rt::execveat(cmd.data, strings::c_empty,
		argv: *[*]nullable *const char, envp, rt::AT_EMPTY_PATH));
};

fn platform_start(cmd: *command) (os_error | void) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (rt::pipe2(&pipe, 0)) {
		err: rt::errno => return errno_to_os(err),
		void => void,
	};

	match (rt::clone(null, 0, null, null, 0u64)) {
		err: rt::errno => return errno_to_os(err),
		pid: int => {
			// TODO: Fill in some kind of process structure
			rt::close(pipe[1]);
			let errno: int = 0;
			match (rt::read(pipe[0], &errno, size(int))) {
				err: rt::errno => return errno_to_os(err),
				n: size => switch (n) {
					size(int) => return errno_to_os(errno),
					* => abort("Unexpected rt::read result"),
					0z => void,
				},
			};
			return;
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
