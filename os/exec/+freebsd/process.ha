// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use rt;
use time;
use unix;
use unix::signal;

// Stores information about a child process.
export type process = unix::pid;

// Returns the currently running [[process]].
export fn self() process = {
	return unix::getpid();
};

// Stores information about an exited process.
export type status = struct {
	status: int,
	// Not all of these members are supported on all operating systems.
	// Only utime and stime are guaranteed to be available.
	rusage: struct {
		utime: time::instant,
		stime: time::instant,
		maxrss: i64,
		ixrss: i64,
		idrss: i64,
		isrss: i64,
		minflt: i64,
		majflt: i64,
		nswap: i64,
		inblock: i64,
		oublock: i64,
		msgsnd: i64,
		msgrcv: i64,
		nsignals: i64,
		nvcsw: i64,
		nivcsw: i64,
	},
};

fn rusage(st: *status, ru: *rt::rusage) void = {
	st.rusage.utime = time::instant {
		sec = ru.ru_utime.tv_sec,
		nsec = ru.ru_utime.tv_usec * time::MICROSECOND: i64,
	};
	st.rusage.stime = time::instant {
		sec = ru.ru_stime.tv_sec,
		nsec = ru.ru_stime.tv_usec * time::MICROSECOND: i64,
	};
	st.rusage.maxrss = ru.ru_maxrss;
	st.rusage.ixrss = ru.ru_ixrss;
	st.rusage.idrss = ru.ru_idrss;
	st.rusage.isrss = ru.ru_isrss;
	st.rusage.minflt = ru.ru_minflt;
	st.rusage.majflt = ru.ru_majflt;
	st.rusage.nswap = ru.ru_nswap;
	st.rusage.inblock = ru.ru_inblock;
	st.rusage.oublock = ru.ru_oublock;
	st.rusage.msgsnd = ru.ru_msgsnd;
	st.rusage.msgrcv = ru.ru_msgrcv;
	st.rusage.nsignals = ru.ru_nsignals;
	st.rusage.nvcsw = ru.ru_nvcsw;
	st.rusage.nivcsw = ru.ru_nivcsw;
};

// Waits for a process to complete, then returns its status information.
export fn wait(proc: *process) (status | error) = {
	let ru: rt::rusage = rt::rusage { ... };
	let st: status = status { ... };
	match (rt::wait4(*proc, &st.status, 0, &ru)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		assert(pid == *proc: int);
	};
	rusage(&st, &ru);
	return st;
};

// Waits for the first child process to complete, then returns its process info
// and status
export fn waitany() ((process, status) | error) = {
	let ru: rt::rusage = rt::rusage { ... };
	let st: status = status { ... };
	match (rt::wait4(-1, &st.status, 0, &ru)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		rusage(&st, &ru);
		return (pid: process, st);
	};
};

// Waits for all children to terminate succesfully. If a child process exits
// with a nonzero status, returns its process info and exit status immediately,
// not waiting for the remaining children.
export fn waitall() (uint | error | !(process, exit_status)) = {
	let st: status = status { ... };
	let ru: rt::rusage = rt::rusage { ... };
	for (let i = 0u; true; i += 1) match (rt::wait4(-1, &st.status, 0, &ru)) {
	case let err: rt::errno =>
		if (err == rt::ECHILD) {
			return i;
		} else {
			return errors::errno(err);
		};
	case let pid: int =>
		match (check(&st)) {
		case void => void;
		case let es: !exit_status =>
			return (pid: process, es);
		};
	};
};

// Checks for process completion, returning its status information on
// completion, or void if it is still running.
export fn peek(proc: *process) (status | void | error) = {
	let ru: rt::rusage = rt::rusage { ... };
	let st: status = status { ... };
	match (rt::wait4(*proc, &st.status, rt::WNOHANG, &ru)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		switch (pid) {
		case 0 =>
			return;
		case =>
			assert(pid == *proc: int);
		};
	};
	rusage(&st, &ru);
	return st;
};

// Checks if any child process has completed, returning its process info and
// status if so.
export fn peekany() ((process, status) | void | error) = {
	let ru: rt::rusage = rt::rusage { ... };
	let st: status = status { ... };
	match (rt::wait4(-1, &st.status, rt::WNOHANG, &ru)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let pid: int =>
		switch (pid) {
		case 0 =>
			return;
		case =>
			return (pid: process, st);
		};
	};
};

// The exit status code of a process.
export type exited = int;

// The signal number which caused a process to terminate.
export type signaled = signal::sig;

// The exit status of a process.
export type exit_status = (exited | signaled);

// Returns a human friendly string describing the exit status. The string is
// statically allocated; use [[strings::dup]] to extend its lifetime.
export fn exitstr(status: exit_status) const str = {
	static let buf: [1024]u8 = [0...];
	match (status) {
	case let i: exited =>
		switch (i) {
		case 0 =>
			return "exited normally";
		case =>
			return fmt::bsprintf(buf, "exited with status {}",
				i: int);
		};
	case let s: signaled =>
		return fmt::bsprintf(buf, "exited with signal {}",
			signal::signame(s));
	};
};

// Returns the exit status of a completed process.
export fn exit(stat: *status) exit_status = {
	if (rt::wifexited(stat.status)) {
		return rt::wexitstatus(stat.status): exited;
	};
	if (rt::wifsignaled(stat.status)) {
		return rt::wtermsig(stat.status): signaled;
	};
	abort("Unexpected exit status");
};

// Checks the exit status of a completed process, returning void if successful,
// or its status code as an error type if not.
export fn check(stat: *status) (void | !exit_status) = {
	if (rt::wifexited(stat.status)) {
		switch (rt::wexitstatus(stat.status)) {
		case 0 =>
			return void;
		case =>
			return exit(stat);
		};
	};
	return exit(stat);
};

// Terminates a process. On FreeBSD, this sends [[unix::signal::sig::TERM]] to
// the process.
export fn kill(proc: process) (void | errors::error) = {
	return sig(proc, signal::sig::TERM);
};

// Sends a signal to a child process. This function is only supported on
// Unix-like systems.
export fn sig(proc: process, sig: signal::sig) (void | errors::error) = {
	match (rt::kill(proc, sig)) {
	case let errno: rt::errno =>
		return errors::errno(errno);
	case void =>
		return;
	};
};
