use errors;
use rt;
use strings;
use os;

export type platform_cmd = int;

// Forks the current process, returning the pid of the child (to the parent) and
// void (to the child), or an error.
export fn fork() (int | void | error) = {
	match (rt::fork()) {
	case err: rt::errno  =>
		return errors::errno(err);
	case i: (int | void) =>
		return i;
	};
};

fn open(path: str) (platform_cmd | error) = {
	match (rt::access(path, rt::X_OK)) {
	case err: rt::errno =>
		return errors::errno(err);
	case b: bool =>
		if (!b) {
			return errors::noaccess;
		};
	};
	// XXX: FreeBSD does not support O_PATH
	match (rt::open(path, rt::O_RDONLY, 0u)) {
	case fd: int =>
		return fd;
	case err: rt::errno =>
		return errors::errno(err);
	};
};

fn platform_finish(cmd: *command) void = rt::close(cmd.platform)!;

fn platform_exec(cmd: *command) error = {
	// We don't worry about freeing the return values from strings::to_c
	// because once we exec(2) our heap is fried anyway
	let argv: []nullable *const char = alloc([], len(cmd.argv) + 1z);
	for (let i = 0z; i < len(cmd.argv); i += 1z) {
		append(argv, strings::to_c(cmd.argv[i]));
	};
	append(argv, null);

	let envp: nullable *[*]nullable *const char = null;
	if (len(cmd.env) != 0) {
		let env: []nullable *const char = alloc([], len(cmd.env) + 1);
		for (let i = 0z; i < len(cmd.env); i += 1) {
			append(env, strings::to_c(cmd.env[i]));
		};
		append(env, null);
		envp = env: *[*]nullable *const char;
	};

	return errors::errno(rt::fexecve(cmd.platform,
		argv: *[*]nullable *const char, envp));
};

fn platform_start(cmd: *command) (process | errors::error) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (rt::pipe2(&pipe, rt::O_CLOEXEC)) {
	case err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};

	match (rt::fork()) {
	case err: rt::errno =>
		return errors::errno(err);
	case pid: int =>
		rt::close(pipe[1])!;
		let errno: int = 0;
		match (rt::read(pipe[0], &errno, size(int))) {
		case err: rt::errno =>
			return errors::errno(err);
		case n: size =>
			switch (n) {
			case size(int) =>
				return errors::errno(errno);
			case 0 =>
				return pid;
			case =>
				abort("Unexpected rt::read result");
			};
		};
	case void =>
		rt::close(pipe[0])!;
		let err = platform_exec(cmd);
		if (!(err is errors::opaque)) {
			rt::exit(1);
		};
		let err = err as errors::opaque;
		let err = &err.data: *rt::errno;
		rt::write(pipe[1], &err, size(int))!;
		rt::exit(1);
	};
};
