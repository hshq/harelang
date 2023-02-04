// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use errors;
use io;
use rt;
use strings;
use os;
use unix;

export type platform_cmd = io::file;

// Forks the current process, returning the [[process]] of the child (to the
// parent) and void (to the child), or an error.
export fn fork() (process | void | error) = {
	match (rt::fork()) {
	case let err: rt::errno  =>
		return errors::errno(err);
	case let i: int =>
		return i: process;
	case void =>
		return void;
	};
};

// Creates an anonymous pipe for use with [[addfile]]. Any data written to the
// second file may be read from the first file. The caller should close one or
// both of the file descriptors after they have transferred them to another
// process, and after they have finished using them themselves, if applicable.
//
// This function will abort the process if the system is unable to allocate the
// resources for a pipe. If you need to handle this error gracefully, you may
// call [[unix::pipe]] yourself, but this may reduce the portability of your
// software.
//
// To capture the standard output of a process:
//
// 	let pipe = exec::pipe();
// 	exec::addfile(&cmd, pipe.1, os::stdout_file);
// 	let proc = exec::start(&cmd)!;
// 	io::close(pipe.1)!;
//
// 	let data = io::drain(pipe.0)!;
// 	io::close(pipe.0)!;
// 	exec::wait(&proc)!;
export fn pipe() (io::file, io::file) = {
	return unix::pipe()!;
};

fn open(path: str) (platform_cmd | error) = {
	// TODO: This is racy, rewrite with TOCTOU
	match (rt::access(path, rt::X_OK)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let b: bool =>
		if (!b) {
			return errors::noaccess;
		};
	};
	match (rt::open(path, rt::O_RDONLY, 0u)) {
	case let fd: int =>
		return fd;
	case let err: rt::errno =>
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

	let need_devnull = false;
	for (let i = 0z; i < len(cmd.files); i += 1) {
		const from = match (cmd.files[i].0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			need_devnull = true;
			continue;
		case closefd =>
			continue;
		};

		cmd.files[i].0 = match (rt::fcntl(from, rt::F_DUPFD_CLOEXEC, 0)) {
		case let fd: int =>
			yield fd;
		case let err: rt::errno =>
			return errors::errno(err);
		};
	};

	const devnull: io::file = if (need_devnull) {
		yield os::open("/dev/null")!;
	} else -1;

	for (let i = 0z; i < len(cmd.files); i += 1) {
		const from = match (cmd.files[i].0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			yield devnull;
		case closefd =>
			io::close(cmd.files[i].1)?;
			continue;
		};

		if (cmd.files[i].1 == from) {
			let flags = match (rt::fcntl(from, rt::F_GETFD, 0)) {
			case let flags: int =>
				yield flags;
			case let e: rt::errno =>
				return errors::errno(e);
			};
			rt::fcntl(from, rt::F_SETFD, flags & ~rt::FD_CLOEXEC)!;
		} else {
			match (rt::dup2(from, cmd.files[i].1)) {
			case int => void;
			case let e: rt::errno =>
				return errors::errno(e);
			};
		};
	};

	if (cmd.dir != "") {
		os::chdir(cmd.dir)?;
	};

	return errors::errno(rt::fexecve(cmd.platform,
		argv: *[*]nullable *const char, envp: *[*]nullable *const char));
};

fn platform_start(cmd: *command) (process | errors::error) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (rt::pipe2(&pipe, rt::O_CLOEXEC)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};

	match (rt::fork()) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		rt::close(pipe[1])!;
		let errno: int = 0;
		match (rt::read(pipe[0], &errno, size(int))) {
		case let err: rt::errno =>
			return errors::errno(err);
		case let n: size =>
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
		rt::write(pipe[1], err, size(int))!;
		rt::exit(1);
	};
};
