use errors;
use rt;
use fmt;
// TODO: Add function to wait on all/any children

// Stores information about a child process.
export type process = int;

// Stores information about an exited process.
export type status = struct {
	status: int,
	// Not all of these members are supported on all operating systems.
	// Only utime and stime are guaranteed to be available.
	rusage: struct {
		// TODO: utime, stime
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
	case err: rt::errno =>
		return errors::errno(err);
	case pid: int =>
		assert(pid == *proc);
	};
	rusage(&st, &ru);
	return st;
};

// Checks for process completion, returning its status information on
// completion, or void if it is still running.
export fn peek(proc: *process) (status | void | error) = {
	let ru: rt::rusage = rt::rusage { ... };
	let st: status = status { ... };
	match (rt::wait4(*proc, &st.status, 0, &ru)) {
	case err: rt::errno =>
		return errors::errno(err);
	case pid: int =>
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

// The exit status code of a process.
export type exited = int;

// The signal number which caused a process to terminate.
export type signaled = int;

// The exit status of a process.
export type exit_status = (exited | signaled);

// Returns a human friendly string describing the exit status.
export fn exitstr(status: exit_status) const str = {
	static let buf: [1024]u8 = [0...];
	match (status) {
	case i: exited =>
		switch (i) {
		case 0 =>
			return "exited normally";
		case =>
			return fmt::bsprintf(buf, "exited with status {}",
				i: int);
		};
	case s: signaled =>
		// TODO: Add signal name
		return fmt::bsprintf(buf, "exited with signal {}", s: int);
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
