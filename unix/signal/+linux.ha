// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;
use time;
use unix;

// Requests that [[sig::ALRM]] is delivered to the calling process in (about)
// "sec" seconds. Returns the number of seconds until the previously scheduled
// alarm, or zero if none was scheduled.
export fn alarm(sec: uint) uint = {
	return rt::alarm(sec);
};

// Configures a new signal handler, returning the old details (which can be
// passed to [[restore]] to restore its behavior).
//
// The variadic parameters specify either [[flag]]s to enable or a signal mask
// to use via [[sigset]]; if the latter is provided no more than one may be
// used.
export fn handle(
	signum: sig,
	handler: *handler,
	opt: (flag | sigset)...
) sigaction = {
	let sa_mask = newsigset();

	let sa_flags = rt::SA_SIGINFO, nmask = 0;
	for (let i = 0z; i < len(opt); i += 1) {
		match (opt[i]) {
		case let flag: flag =>
			sa_flags |= flag: u64;
		case let mask: sigset =>
			assert(nmask == 0, "Multiple signal masks provided to signal::handle");
			nmask += 1;
			sa_mask = mask;
		};
	};

	let new = rt::sigact {
		sa_sigaction = handler: *fn(int, *rt::siginfo, *opaque) void,
		sa_mask = sa_mask,
		sa_flags = sa_flags,
		// Filled in by rt:
		sa_restorer = null: *fn () void,
	};
	let old = rt::sigact {
		// Filled in by rt:
		sa_sigaction = null: *fn(int, *rt::siginfo, *opaque) void,
		sa_restorer = null: *fn() void,
		...
	};
	match (rt::sigaction(signum, &new, &old)) {
	case rt::errno =>
		abort("sigaction failed (invalid signal?)");
	case int => void;
	};
	return old;
};

// Restores previous signal behavior following [[handle]].
export fn restore(signum: sig, action: *sigaction) void = {
	match (rt::sigaction(signum, action: *rt::sigact, null)) {
	case rt::errno =>
		abort("sigaction failed (invalid signal?)");
	case int => void;
	};
};

// Unregisters signal handlers for the specified signal.
export fn reset(signum: sig) void = {
	handle(signum, rt::SIG_DFL: *handler);
};

// Unregisters all signal handlers.
export fn resetall() void = {
	// sig::KILL and sig::STOP deliberately omitted; see sigaction(2)
	reset(sig::HUP);
	reset(sig::INT);
	reset(sig::QUIT);
	reset(sig::ILL);
	reset(sig::TRAP);
	reset(sig::ABRT);
	reset(sig::BUS);
	reset(sig::FPE);
	reset(sig::USR1);
	reset(sig::SEGV);
	reset(sig::USR2);
	reset(sig::PIPE);
	reset(sig::ALRM);
	reset(sig::TERM);
	reset(sig::CHLD);
	reset(sig::CONT);
	reset(sig::TSTP);
	reset(sig::TTIN);
	reset(sig::TTOU);
	reset(sig::URG);
	reset(sig::XCPU);
	reset(sig::XFSZ);
	reset(sig::VTALRM);
	reset(sig::PROF);
	reset(sig::WINCH);
	reset(sig::POLL);
	reset(sig::PWR);
	reset(sig::SYS);
};

// Prevents given signal from arriving to the current process.
// One common use case is to ignore SIGCHLD to avoid zombie child processes.
export fn ignore(signum: sig) void = {
	handle(signum, rt::SIG_IGN: *handler);
};

// Adds the given list of signals to the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn block(signals: sig...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::BLOCK, &new);
};

// Removes the given list of signals from the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn unblock(signals: sig...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::UNBLOCK, &new);
};

// Sets the process's signal mask, returning the previous mask.
export fn setprocmask(how: how, mask: *sigset) sigset = {
	let old = sigset { ... };
	rt::sigprocmask(how, mask: *rt::sigset, &old)!;
	return old;
};

// Gets the current process's signal mask.
export fn getprocmask() sigset = {
	let old = sigset { ... };
	rt::sigprocmask(how::SETMASK, null, &old)!;
	return old;
};

// Defines the modes of operation for [[setprocmask]].
export type how = enum int {
	// Adds the given set of signals to the current mask.
	BLOCK = rt::SIG_BLOCK,
	// Removes the given set of signals from the current mask.
	UNBLOCK = rt::SIG_UNBLOCK,
	// Sets the process mask to the given set.
	SETMASK = rt::SIG_SETMASK,
};

export type sigaction = rt::sigact;

export type sigset = rt::sigset;

// Creates a new signal set filled in with the provided signals (or empty if
// none are provided).
export fn newsigset(items: sig...) sigset = {
	let set = sigset { ... };
	rt::sigemptyset(&set);
	sigset_add(&set, items...);
	return set;
};

// Sets a [[sigset]] to empty.
export fn sigset_empty(set: *sigset) void = {
	rt::sigemptyset(set: *rt::sigset);
};

// Adds signals to a [[sigset]].
export fn sigset_add(set: *sigset, items: sig...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigaddset(set: *rt::sigset, items[i])!;
	};
};

// Removes signals from a [[sigset]].
export fn sigset_del(set: *sigset, items: sig...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigdelset(set: *rt::sigset, items[i])!;
	};
};

// Adds all platform-defined signals to a [[sigset]].
export fn sigset_fill(set: *sigset) void = {
	rt::sigfillset(set: *rt::sigset);
};

// Returns true if the given signal is a member of this [[sigset]].
export fn sigset_member(set: *sigset, item: sig) bool = {
	return rt::sigismember(set: *rt::sigset, item)!;
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the signal number.
//
// If a signal is received while waiting, [[errors::interrupted]] is returned.
// Most consumers of this function will likely wish to block all signals and
// handle them exclusively through [[wait]] et al, in which case this error
// cannot occur.
//
// See also [[waitinfo]] and [[timedwait]].
export fn wait(set: *sigset) (sig | errors::interrupted) = {
	let signal = 0i;
	match (rt::sigwait(set: *rt::sigset, &signal)) {
	case let err: rt::errno =>
		assert(err == rt::EINTR);
		return errors::interrupted;
	case void =>
		return signal: sig;
	};
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the corresponding [[siginfo]] data.
//
// See notes on [[wait]] regarding the [[errors::interrupted]] case.
//
// This function is designed to provide the portable subset of the semantics of
// sigwaitinfo(3) as defined by POSIX.1-2008. To access the complete siginfo_t
// structure provided by the underlying platform, use [[rt::sigwaitinfo]] and
// [[rt::siginfo_t]] directly.
//
// Note that this function is not supported on OpenBSD.
export fn waitinfo(set: *sigset) (siginfo | errors::interrupted) = {
	let info = rt::siginfo { ... };
	match (rt::sigwaitinfo(set: *rt::sigset, &info)) {
	case let err: rt::errno =>
		assert(err == rt::EINTR);
		return errors::interrupted;
	case int =>
		return *(&info: *siginfo);
	};
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the corresponding [[siginfo]] data.
//
// Returns a [[siginfo]] if a signal is successfully processed through this
// function, or [[errors::again]] if the timeout expired. See notes on [[wait]]
// regarding the [[errors::interrupted]] case.
//
// This function is designed to provide the portable subset of the semantics of
// sigtimedwait(3) as defined by POSIX.1-2008. To access the complete siginfo_t
// structure provided by the underlying platform, use [[rt::sigtimedwait]] and
// [[rt::siginfo_t]] directly.
//
// Note that this function is not supported on OpenBSD.
export fn timedwait(
	set: *sigset,
	timeout: time::duration,
) (siginfo | errors::interrupted | errors::again) = {
	let info = rt::siginfo { ... };
	let to = time::duration_to_timeval(timeout);
	match (rt::sigwaitinfo(set: *rt::sigset, &info)) {
	case let err: rt::errno =>
		switch (err) {
		case rt::EINTR =>
			return errors::interrupted;
		case rt::EAGAIN =>
			return errors::again;
		case => abort();
		};
	case int =>
		return *(&info: *siginfo);
	};
};

// Provides additional information about signal deliveries. Only the members
// defined by POSIX are available here; cast to [[rt::siginfo]] to access
// non-portable members.
export type siginfo = union {
	struct {
		// The signal number being delivered.
		signo: sig,
		// The errno, if any, associated with this signal. See
		// [[errors::errno]] to convert to a Hare-native error.
		errno: rt::errno,
		// The signal code, if any.
		code: code,

		union {
			struct {
				// Process ID of the sender.
				pid: unix::pid,
				// Real user ID of the sending process.
				uid: unix::uid,
				// Exit value or signal.
				status: int,
			},
			struct {
				// Address of the faulting instruction.
				addr: *opaque,
			},
		},
	},
	// Pads the structure out to the length used by the kernel; do not use.
	_si_pad: [128 - 3 * size(int)]u8,
};

// A code indicating why a signal was sent.
export type code = enum int {
	USER = 0, // sent by userspace program (kill)
	KERNEL = 128, // sent by kernel
	QUEUE = -1, // sent by sigqueue
	TIMER = -2, // generated by expiration of a timer
	MESQ = -3, // generated by arrival of a message on an empty queue
	ASYNCIO = -4, // generated by completion of an asynchronous I/O request
	SIGIO = -5,
	TKILL = -6, // sent by userspace program (tkill, tgkill)
	ASYNCNL = -60,

	ILLOPC = 1, // sig::ILL: illegal opcode
	ILLOPN = 2, // sig::ILL: illegal operand
	ILLADR = 3, // sig::ILL: illegal addressing mode
	ILLTRP = 4, // sig::ILL: illegal trap
	PRVOPC = 5, // sig::ILL: privileged opcode
	PRVREG = 6, // sig::ILL: privileged register
	COPROC = 7, // sig::ILL: coprocessor error
	BADSTK = 8, // sig::ILL: internal stack error

	INTDIV = 1, // sig::FPE: integer divide by zero
	INTOVF = 2, // sig::FPE: integer overflow
	FLTDIV = 3, // sig::FPE: floating-point divide by zero
	FLTOVF = 4, // sig::FPE: floating-point overflow
	FLTUND = 5, // sig::FPE: floating-point underflow
	FLTRES = 6, // sig::FPE: floating-point inexact result
	FLTINV = 7, // sig::FPE: invalid floating-point operation
	FLTSUB = 8, // sig::FPE: subscript out of range

	MAPERR = 1, // sig::SEGV: address not mapped to object
	ACCERR = 2, // sig::SEGV: invalid permissions for mapped object
	BNDERR = 3, // sig::SEGV: failed address bound checks
	PKUERR = 4, // sig::SEGV: access was denied by memory protection keys
	MTEAERR = 8, // sig::SEGV
	MTESERR = 9, // sig::SEGV

	ADRALN = 1, // sig::BUS: invalid address alignment
	ADRERR = 2, // sig::BUS: nonexistent physical address
	OBJERR = 3, // sig::BUS: object-specific hardware error
	MCEERR_AR = 4, // sig::BUS: hardware memory error consumed on a machine check; action required
	MCEERR_AO = 5, // sig::BUS: hardware memory error detected in process but not consumed; action optional

	BRKPT = 1, // sig::TRAP: process breakpoint
	TRACE = 2, // sig::TRAP: process trace trap
	BRANCH = 3, // sig::TRAP: process taken branch trap
	HWBKPT = 4, // sig::TRAP: hardware breakpoint/watchpoint
	UNK = 5, // sig::TRAP

	EXITED = 1, // sig::CHLD: child exited
	KILLED = 2, // sig::CHLD: child terminated abnormally without a core file
	DUMPED = 3, // sig::CHLD: child terminated abnormally with a core file
	TRAPPED = 4, // sig::CHLD: traced child has trapped
	STOPPED = 5, // sig::CHLD: child has stopped
	CONTINUED = 6, // sig::CHLD: stopped child has continued

	IN = 1, // sig::POLL: data input available
	OUT = 2, // sig::POLL: output buffers available
	MSG = 3, // sig::POLL: input message available
	ERR = 4, // sig::POLL: I/O error
	PRI = 5, // sig::POLL: high priority input available
	HUP = 6, // sig::POLL: device disconnected
};

// Flags used to configure the behavior of a signal handler.
export type flag = enum int {
	// For use with sig::CHLD. Prevents notifications when child processes
	// stop (e.g. via sig::STOP) or resume (i.e. sig::CONT).
	NOCLDSTOP = rt::SA_NOCLDSTOP: int,
	// For use with sig::CHLD. Do not transform children into zombies when
	// they terminate. Note that POSIX leaves the delivery of sig::CHLD
	// unspecified when this flag is present; some systems will still
	// deliver a signal and others may not.
	NOCLDWAIT = rt::SA_NOCLDWAIT: int,
	// Uses an alternate stack when handling this signal. See
	// [[setaltstack]] and [[getaltstack]] for details.
	ONSTACK = rt::SA_ONSTACK: int,
	// Makes certain system calls restartable across signals. See signal(7)
	// or similar documentation for your local system for details.
	RESTART = rt::SA_RESTART: int,
	// Do not add the signal to the signal mask while executing the signal
	// handler. This can cause the same signal to be delivered again during
	// the execution of the signal handler.
	NODEFER = rt::SA_NODEFER: int,
	// Restore the signal handler to the default behavior upon entering the
	// signal handler.
	RESETHAND = rt::SA_RESETHAND: int,
};

// All possible signals.
export type sig = enum int {
	HUP = rt::SIGHUP, // Hangup.
	INT = rt::SIGINT, // Terminal interrupt.
	QUIT = rt::SIGQUIT, // Terminal quit.
	ILL = rt::SIGILL, // Illegal instruction.
	TRAP = rt::SIGTRAP, // Trace/breakpoint trap.
	ABRT = rt::SIGABRT, // Process abort.
	BUS = rt::SIGBUS, // Access to an undefined portion of a memory object.
	FPE = rt::SIGFPE, // Erroneous arithmetic operation.
	KILL = rt::SIGKILL, // Kill (cannot be caught or ignored).
	USR1 = rt::SIGUSR1, // User-defined signal 1.
	SEGV = rt::SIGSEGV, // Invalid memory reference.
	USR2 = rt::SIGUSR2, // User-defined signal 2.
	PIPE = rt::SIGPIPE, // Write on a pipe with no one to read it.
	ALRM = rt::SIGALRM, // Alarm clock.
	TERM = rt::SIGTERM, // Termination.
	CHLD = rt::SIGCHLD, // Child process terminated, stopped, or continued.
	CONT = rt::SIGCONT, // Continue executing if stopped.
	STOP = rt::SIGSTOP, // Stop executing (cannot be caught or ignored).
	TSTP = rt::SIGTSTP, // Terminal stop.
	TTIN = rt::SIGTTIN, // Background process attempting read.
	TTOU = rt::SIGTTOU, // Background process attempting write.
	URG = rt::SIGURG, // High bandwidth data is available at a socket.
	XCPU = rt::SIGXCPU, // CPU time limit exceeded.
	XFSZ = rt::SIGXFSZ, // File size limit exceeded.
	VTALRM = rt::SIGVTALRM, // Virtual timer expired.
	PROF = rt::SIGPROF, // Profiling timer expired.
	WINCH = rt::SIGWINCH, // Window resize signal.
	IO = rt::SIGIO, // I/O now possible (synonymous with sig::POLL).
	POLL = rt::SIGPOLL, // Pollable event.
	PWR = rt::SIGPWR, // Power failure.
	SYS = rt::SIGSYS, // Bad system call.
};

// Creates a signal file that handles the given set of signals.
export fn signalfd(signals: sig...) (io::file | errors::error) = {
	let sa_mask = newsigset(signals...);
	match (rt::signalfd(-1, &sa_mask, rt::SFD_CLOEXEC)) {
	case let fd: int =>
		return fd;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Updates a signalfd with a new set of signals. The signal set is overwritten,
// rather than appended to, with the provided set of signals.
export fn update(fd: io::file, signals: sig...) (void | errors::error) = {
	let sa_mask = newsigset(signals...);

	match (rt::signalfd(fd, &sa_mask, rt::SFD_CLOEXEC)) {
	case int =>
		return;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Reads pending signal info from a signalfd.
export fn read(fd: io::file) (siginfo | errors::error) = {
	let si = rt::signalfd_siginfo { ... };
	match (rt::read(fd, &si, size(rt::signalfd_siginfo))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let z: size =>
		assert(z == size(rt::signalfd_siginfo));
	};
	return siginfo {
		signo = si.ssi_signo: sig,
		errno = si.ssi_errno: rt::errno,
		code = si.ssi_code: code,
		...
	};
};

// Returns the human friendly name of a given signal.
export fn signame(sig: sig) const str = {
	switch (sig) {
	case sig::HUP =>
		return "SIGHUP";
	case sig::INT =>
		return "SIGINT";
	case sig::QUIT =>
		return "SIGQUIT";
	case sig::ILL =>
		return "SIGILL";
	case sig::TRAP =>
		return "SIGTRAP";
	case sig::ABRT =>
		return "SIGABRT";
	case sig::BUS =>
		return "SIGBUS";
	case sig::FPE =>
		return "SIGFPE";
	case sig::KILL =>
		return "SIGKILL";
	case sig::USR1 =>
		return "SIGUSR1";
	case sig::SEGV =>
		return "SIGSEGV";
	case sig::USR2 =>
		return "SIGUSR2";
	case sig::PIPE =>
		return "SIGPIPE";
	case sig::ALRM =>
		return "SIGALRM";
	case sig::TERM =>
		return "SIGTERM";
	case sig::CHLD =>
		return "SIGCHLD";
	case sig::CONT =>
		return "SIGCONT";
	case sig::STOP =>
		return "SIGSTOP";
	case sig::TSTP =>
		return "SIGTSTP";
	case sig::TTIN =>
		return "SIGTTIN";
	case sig::TTOU =>
		return "SIGTTOU";
	case sig::URG =>
		return "SIGURG";
	case sig::XCPU =>
		return "SIGXCPU";
	case sig::XFSZ =>
		return "SIGXFSZ";
	case sig::VTALRM =>
		return "SIGVTALRM";
	case sig::PROF =>
		return "SIGPROF";
	case sig::WINCH =>
		return "SIGWINCH";
	case sig::POLL =>
		return "SIGPOLL";
	case sig::PWR =>
		return "SIGPWR";
	case sig::SYS =>
		return "SIGSYS";
	};
};
