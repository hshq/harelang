// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use os;
use rt;
use types::c;
use unix;

// Forks the current process, returning the [[process]] of the child (to the
// parent) and void (to the child), or an error.
export fn fork() (process | void | error) = {
	match (rt::fork()) {
	case let err: rt::errno  =>
		return errors::errno(err);
	case let i: rt::pid_t =>
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
// 	exec::addfile(&cmd, os::stdout_file, pipe.1);
// 	let proc = exec::start(&cmd)!;
// 	io::close(pipe.1)!;
//
// 	let data = io::drain(pipe.0)!;
// 	io::close(pipe.0)!;
// 	exec::wait(&proc)!;
//
// To write to the standard input of a process:
//
// 	let pipe = exec::pipe();
// 	exec::addfile(&cmd, os::stdin_file, pipe.0);
// 	let proc = exec::start(&cmd)!;
//
// 	io::writeall(data)!;
// 	io::close(pipe.1)!;
// 	io::close(pipe.0)!;
// 	exec::wait(&proc)!;
export fn pipe() (io::file, io::file) = {
	return unix::pipe()!;
};

fn open(path: str) (platform_cmd | error) = {
	// O_PATH is used because it allows us to use an executable for which we
	// have execute permissions, but not read permissions.
	let fd = match (rt::open(path, rt::O_PATH, 0u)) {
	case let fd: int =>
		yield fd;
	case let err: rt::errno =>
		return errors::errno(err);
	};
	let success = false;
	defer if (!success) rt::close(fd)!;
	match (rt::faccessat(fd, "", rt::X_OK, rt::AT_EMPTY_PATH)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let b: bool =>
		if (!b) {
			return errors::noaccess;
		};
	};
	// Make sure we are not trying to execute anything weird. fstat()
	// already dereferences symlinks, so if this is anything other than a
	// regular file it cannot be executed.
	let s = rt::st { ... };
	match (rt::fstat(fd, &s)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		if (s.mode & rt::S_IFREG == 0) {
			return errors::noaccess;
		};
	};
	success = true;
	return fd;
};

fn platform_finish(cmd: *command) void = rt::close(cmd.platform)!;

fn platform_exec(cmd: *command) error = {
	// We don't worry about freeing the return values from c::fromstr
	// because once we exec(2) our heap is fried anyway
	let argv: []nullable *const c::char = alloc([], len(cmd.argv) + 1z);
	for (let arg .. cmd.argv) {
		append(argv, c::fromstr(arg));
	};
	append(argv, null);

	let envp: nullable *[*]nullable *const c::char = null;
	if (len(cmd.env) != 0) {
		let env: []nullable *const c::char = alloc([], len(cmd.env) + 1);
		for (let e .. cmd.env) {
			append(env, c::fromstr(e));
		};
		append(env, null);
		envp = env: *[*]nullable *const c::char;
	};

	let need_devnull = false;
	for (let file &.. cmd.files) {
		const from = match (file.0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			need_devnull = true;
			continue;
		case closefd =>
			continue;
		};

		file.0 = match (rt::fcntl(from, rt::F_DUPFD_CLOEXEC, 0)) {
		case let fd: int =>
			yield fd;
		case let err: rt::errno =>
			return errors::errno(err);
		};
	};

	const devnull: io::file = if (need_devnull) {
		yield os::open("/dev/null")!;
	} else -1;

	for (let file .. cmd.files) {
		const from = match (file.0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			yield devnull;
		case closefd =>
			io::close(file.1)?;
			continue;
		};

		if (file.1 == from) {
			let flags = match (rt::fcntl(from, rt::F_GETFD, 0)) {
			case let flags: int =>
				yield flags;
			case let e: rt::errno =>
				return errors::errno(e);
			};
			rt::fcntl(from, rt::F_SETFD, flags & ~rt::FD_CLOEXEC)!;
		} else {
			match (rt::dup2(from, file.1)) {
			case int => void;
			case let e: rt::errno =>
				return errors::errno(e);
			};
		};
	};

	if (cmd.dir != "") {
		os::chdir(cmd.dir)?;
	};

	return errors::errno(rt::execveat(cmd.platform,
		"\0", argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8, rt::AT_EMPTY_PATH));
};

fn platform_start(cmd: *command) (process | errors::error) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (rt::pipe2(&pipe, rt::O_CLOEXEC)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};

	match (rt::clone(null, rt::SIGCHLD, null, null, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		rt::close(pipe[1])!;
		defer rt::close(pipe[0])!;
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
		if (!(err is errors::opaque_)) {
			rt::exit(1);
		};
		let err = err as errors::opaque_;
		let err = &err.data: *rt::errno;
		rt::write(pipe[1], err, size(int))!;
		rt::exit(1);
	};
};
