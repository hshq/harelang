// License: MPL-2.0
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use errors;
use rt;
use fmt;
use unix::signal;

// Stores information about a child process.
export type process = int;

// Returns the currently running [[process]].
export fn self() process = {
	return rt::getpid();
};

// Stores information about an exited process.
export type status = struct {
	status: int,
	// Not all of these members are supported on all operating systems.
	// Only utime and stime are guaranteed to be available.
	rusage: struct {
		// TODO: utime, stime
		maxrss: u64,
		minflt: u64,
		majflt: u64,
		inblock: u64,
		oublock: u64,
		nvcsw: u64,
		nivcsw: u64,
	},
};

fn rusage(st: *status, ru: *rt::rusage) void = {
	st.rusage.maxrss = ru.ru_maxrss;
	st.rusage.minflt = ru.ru_minflt;
	st.rusage.majflt = ru.ru_majflt;
	st.rusage.inblock = ru.ru_inblock;
	st.rusage.oublock = ru.ru_oublock;
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
		assert(pid == *proc);
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
		return (pid, st);
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
		if (err: int == rt::ECHILD) {
			return i;
		} else {
			return errors::errno(err);
		};
	case let pid: int =>
		match (check(&st)) {
		case void => void;
		case let es: !exit_status =>
			return (pid, es);
		};
	};
	abort("unreachable");
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
			assert(pid == *proc);
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
			return (pid, st);
		};
	};
};

// The exit status code of a process.
export type exited = int;

// The signal number which caused a process to terminate.
export type signaled = int;

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

// An enumeration of all known signals. Only a subset of these are defined by
// POSIX, consult the specification for details:
//
// https://pubs.opengroup.org/onlinepubs/009695399/basedefs/signal.h.html
export type signal = enum int {
	SIGHUP = rt::SIGHUP,
	SIGINT = rt::SIGINT,
	SIGQUIT = rt::SIGQUIT,
	SIGILL = rt::SIGILL,
	SIGTRAP = rt::SIGTRAP,
	SIGABRT = rt::SIGABRT,
	SIGBUS = rt::SIGBUS,
	SIGFPE = rt::SIGFPE,
	SIGKILL = rt::SIGKILL,
	SIGUSR1 = rt::SIGUSR1,
	SIGSEGV = rt::SIGSEGV,
	SIGUSR2 = rt::SIGUSR2,
	SIGPIPE = rt::SIGPIPE,
	SIGALRM = rt::SIGALRM,
	SIGTERM = rt::SIGTERM,
	SIGSTKFLT = rt::SIGSTKFLT,
	SIGCHLD = rt::SIGCHLD,
	SIGCONT = rt::SIGCONT,
	SIGSTOP = rt::SIGSTOP,
	SIGTSTP = rt::SIGTSTP,
	SIGTTIN = rt::SIGTTIN,
	SIGTTOU = rt::SIGTTOU,
	SIGURG = rt::SIGURG,
	SIGXCPU = rt::SIGXCPU,
	SIGXFSZ = rt::SIGXFSZ,
	SIGVTALRM = rt::SIGVTALRM,
	SIGPROF = rt::SIGPROF,
	SIGWINCH = rt::SIGWINCH,
	SIGIO = rt::SIGIO,
	SIGPOLL = rt::SIGPOLL,
	SIGPWR = rt::SIGPWR,
	SIGSYS = rt::SIGSYS,
};

// Sends a signal to a child process. If no variadic arguments are provided, the
// program is terminated in a platform-specific manner. You may provide exactly
// one variadic argument, the [[signal]] you wish to send, but this is only
// supported on Unix-like systems.
export fn kill(proc: process, sig: signal...) (void | errors::error) = {
	const sig = if (len(sig) == 0) {
		yield signal::SIGTERM;
	} else if (len(sig) == 1) {
		yield sig[0];
	} else {
		abort("os::exec::signal illegally called with more than one signal");
	};
	match (rt::kill(proc, sig)) {
	case let errno: rt::errno =>
		return errors::errno(errno);
	case void =>
		return;
	};
};
