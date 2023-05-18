// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use errors;
use io;
use rt;

// Configures a new signal handler, returning the old details (which can be
// passed to [[restore]] to restore its behavior).
//
// The variadic parameters specify either [[flag]]s to enable or a signal mask
// to use via [[sigset]]; if the latter is provided no more than one may be
// used.
export fn handle(
	signum: signal,
	handler: *handler,
	opt: (flag | sigset)...
) sigaction = {
	let sa_mask = newsigset();

	let sa_flags = 0u64, nmask = 0;
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
		sa_sigaction = handler: *fn(int, *rt::siginfo, *void) void,
		sa_mask = sa_mask,
		sa_flags = sa_flags,
		// Filled in by rt:
		sa_restorer = null: *fn () void,
	};
	let old = rt::sigact {
		// Filled in by rt:
		sa_sigaction = null: *fn(int, *rt::siginfo, *void) void,
		sa_restorer = null: *fn() void,
		...
	};
	match (rt::sigaction(signum, &new, &old)) {
	case int =>
		yield;
	case rt::errno =>
		abort("sigaction failed (invalid signal?)");
	};
	return old;
};

// Restores previous signal behavior following [[handle]].
export fn restore(signum: signal, action: *sigaction) void = {
	match (rt::sigaction(signum, action, null)) {
	case int =>
		yield;
	case rt::errno =>
		abort("sigaction failed (invalid signal?)");
	};
};

// Unregisters signal handlers for the specified signal.
export fn reset(signum: signal) void = {
	handle(signum, rt::SIG_DFL: *handler);
};

// Unregisters all signal handlers.
export fn resetall() void = {
	// SIGKILL and SIGSTOP deliberately omitted; see sigaction(2)
	reset(SIGHUP);
	reset(SIGINT);
	reset(SIGQUIT);
	reset(SIGILL);
	reset(SIGTRAP);
	reset(SIGABRT);
	reset(SIGBUS);
	reset(SIGFPE);
	reset(SIGUSR1);
	reset(SIGSEGV);
	reset(SIGUSR2);
	reset(SIGPIPE);
	reset(SIGALRM);
	reset(SIGTERM);
	reset(SIGCHLD);
	reset(SIGCONT);
	reset(SIGTSTP);
	reset(SIGTTIN);
	reset(SIGTTOU);
	reset(SIGURG);
	reset(SIGXCPU);
	reset(SIGXFSZ);
	reset(SIGVTALRM);
	reset(SIGPROF);
	reset(SIGWINCH);
	reset(SIGIO);
	reset(SIGPOLL);
	reset(SIGPWR);
	reset(SIGSYS);
};

// Prevents given signal from arriving to the current process.
// One common use case is to ignore SIGCHLD to avoid zombie child processes.
export fn ignore(signum: signal) void = {
	handle(signum, rt::SIG_IGN: *handler);
};

// Adds the given list of signals to the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn block(signals: signal...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::BLOCK, &new);
};

// Removes the given list of signals from the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn unblock(signals: signal...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::UNBLOCK, &new);
};

// Sets the process's signal mask, returning the previous mask.
export fn setprocmask(how: how, mask: *sigset) sigset = {
	let old = sigset { ... };
	rt::sigprocmask(how, mask, &old)!;
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
export fn newsigset(items: signal...) sigset = {
	let set = sigset { ... };
	rt::sigemptyset(&set);
	sigset_add(&set, items...);
	return set;
};

// Sets a [[sigset]] to empty.
export fn sigset_empty(set: *sigset) void = {
	rt::sigemptyset(set);
};

// Adds signals to a [[sigset]].
export fn sigset_add(set: *sigset, items: signal...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigaddset(set, items[i])!;
	};
};

// Removes signals from a [[sigset]].
export fn sigset_del(set: *sigset, items: signal...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigdelset(set, items[i])!;
	};
};

// Returns true if the given signal is a member of this [[sigset]].
export fn sigset_member(set: *sigset, item: signal) bool = {
	return rt::sigismember(set, item)!;
};

// Provides additional information about signal deliveries. Only the members
// defined by POSIX are available here; cast to [[rt::siginfo]] to access
// non-portable members.
//
// TODO: Expand this with more portable options
export type siginfo = union {
	struct {
		// The signal number being delivered.
		signo: signal,
		// The errno, if any, associated with this signal. See
		// [[errors::errno]] to convert to a Hare-native error.
		errno: rt::errno,
		// The signal code, if any.
		code: code,
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

	ILLOPC = 1, // SIGILL: illegal opcode
	ILLOPN = 2, // SIGILL: illegal operand
	ILLADR = 3, // SIGILL: illegal addressing mode
	ILLTRP = 4, // SIGILL: illegal trap
	PRVOPC = 5, // SIGILL: privileged opcode
	PRVREG = 6, // SIGILL: privileged register
	COPROC = 7, // SIGILL: coprocessor error
	BADSTK = 8, // SIGILL: internal stack error

	INTDIV = 1, // SIGFPE: integer divide by zero
	INTOVF = 2, // SIGFPE: integer overflow
	FLTDIV = 3, // SIGFPE: floating-point divide by zero
	FLTOVF = 4, // SIGFPE: floating-point overflow
	FLTUND = 5, // SIGFPE: floating-point underflow
	FLTRES = 6, // SIGFPE: floating-point inexact result
	FLTINV = 7, // SIGFPE: invalid floating-point operation
	FLTSUB = 8, // SIGFPE: subscript out of range

	MAPERR = 1, // SIGSEGV: address not mapped to object
	ACCERR = 2, // SIGSEGV: invalid permissions for mapped object
	BNDERR = 3, // SIGSEGV: failed address bound checks
	PKUERR = 4, // SIGSEGV: access was denied by memory protection keys
	MTEAERR = 8, // SIGSEGV
	MTESERR = 9, // SIGSEGV

	ADRALN = 1, // SIGBUS: invalid address alignment
	ADRERR = 2, // SIGBUS: nonexistent physical address
	OBJERR = 3, // SIGBUS: object-specific hardware error
	MCEERR_AR = 4, // SIGBUS: hardware memory error consumed on a machine check; action required
	MCEERR_AO = 5, // SIGBUS: hardware memory error detected in process but not consumed; action optional

	BRKPT = 1, // SIGTRAP: process breakpoint
	TRACE = 2, // SIGTRAP: process trace trap
	BRANCH = 3, // SIGTRAP: process taken branch trap
	HWBKPT = 4, // SIGTRAP: hardware breakpoint/watchpoint
	UNK = 5, // SIGTRAP

	EXITED = 1, // SIGCHLD: child exited
	KILLED = 2, // SIGCHLD: child terminated abnormally without a core file
	DUMPED = 3, // SIGCHLD: child terminated abnormally with a core file
	TRAPPED = 4, // SIGCHLD: traced child has trapped
	STOPPED = 5, // SIGCHLD: child has stopped
	CONTINUED = 6, // SIGCHLD: stopped child has continued

	IN = 1, // SIGPOLL: data input available
	OUT = 2, // SIGPOLL: output buffers available
	MSG = 3, // SIGPOLL: input message available
	ERR = 4, // SIGPOLL: I/O error
	PRI = 5, // SIGPOLL: high priority input available
	HUP = 6, // SIGPOLL: device disconnected
};

// Flags used to configure the behavior of a signal handler.
export type flag = enum int {
	// For use with [[SIGCHLD]]. Prevents notifications when child processes
	// stop (e.g. via [[SIGSTOP]]) or resume (i.e. [[SIGCONT]]).
	NOCLDSTOP = rt::SA_NOCLDSTOP: int,
	// For use with [[SIGCHLD]]. Do not transform children into zombies when
	// they terminate. Note that POSIX leaves the delivery of [[SIGCHLD]]
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

export type signal = int;

// Creates a signal file that handles the given set of signals.
export fn signalfd(signals: signal...) (io::file | errors::error) = {
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
export fn update(fd: io::file, signals: signal...) (void | errors::error) = {
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
		signo = si.ssi_signo: signal,
		errno = si.ssi_errno: rt::errno,
		code = si.ssi_code: code,
		...
	};
};

// Hangup.
export def SIGHUP: signal = rt::SIGHUP;
// Terminal interrupt signal.
export def SIGINT: signal = rt::SIGINT;
// Terminal quit signal.
export def SIGQUIT: signal = rt::SIGQUIT;
// Illegal instruction.
export def SIGILL: signal = rt::SIGILL;
// Trace/breakposignal trap.
export def SIGTRAP: signal = rt::SIGTRAP;
// Process abort signal.
export def SIGABRT: signal = rt::SIGABRT;
// Access to an undefined portion of a memory object.
export def SIGBUS: signal = rt::SIGBUS;
// Erroneous arithmetic operation.
export def SIGFPE: signal = rt::SIGFPE;
// Kill (cannot be caught or ignored).
export def SIGKILL: signal = rt::SIGKILL;
// User-defined signal 1.
export def SIGUSR1: signal = rt::SIGUSR1;
// Invalid memory reference.
export def SIGSEGV: signal = rt::SIGSEGV;
// User-defined signal 2.
export def SIGUSR2: signal = rt::SIGUSR2;
// Write on a pipe with no one to read it.
export def SIGPIPE: signal = rt::SIGPIPE;
// Alarm clock.
export def SIGALRM: signal = rt::SIGALRM;
// Termination signal.
export def SIGTERM: signal = rt::SIGTERM;
// Child process terminated, stopped, or continued.
export def SIGCHLD: signal = rt::SIGCHLD;
// Continue executing, if stopped.
export def SIGCONT: signal = rt::SIGCONT;
// Stop executing (cannot be caught or ignored).
export def SIGSTOP: signal = rt::SIGSTOP;
// Terminal stop signal.
export def SIGTSTP: signal = rt::SIGTSTP;
// Background process attempting read.
export def SIGTTIN: signal = rt::SIGTTIN;
// Background process attempting write.
export def SIGTTOU: signal = rt::SIGTTOU;
// High bandwidth data is available at a socket.
export def SIGURG: signal = rt::SIGURG;
// CPU time limit exceeded.
export def SIGXCPU: signal = rt::SIGXCPU;
// File size limit exceeded.
export def SIGXFSZ: signal = rt::SIGXFSZ;
// Virtual timer expired.
export def SIGVTALRM: signal = rt::SIGVTALRM;
// Profiling timer expired.
export def SIGPROF: signal = rt::SIGPROF;
// Window resize signal.
export def SIGWINCH: signal = rt::SIGWINCH;
// I/O now possible.
export def SIGIO: signal = rt::SIGIO;
// Pollable event.
export def SIGPOLL: signal = rt::SIGPOLL;
// Power failure.
export def SIGPWR: signal = rt::SIGPWR;
// Bad system call.
export def SIGSYS: signal = rt::SIGSYS;

// Returns the human friendly name of a given signal.
export fn signame(sig: signal) const str = {
	switch (sig) {
	case SIGHUP =>
		return "SIGHUP";
	case SIGINT =>
		return "SIGINT";
	case SIGQUIT =>
		return "SIGQUIT";
	case SIGILL =>
		return "SIGILL";
	case SIGTRAP =>
		return "SIGTRAP";
	case SIGABRT =>
		return "SIGABRT";
	case SIGBUS =>
		return "SIGBUS";
	case SIGFPE =>
		return "SIGFPE";
	case SIGKILL =>
		return "SIGKILL";
	case SIGUSR1 =>
		return "SIGUSR1";
	case SIGSEGV =>
		return "SIGSEGV";
	case SIGUSR2 =>
		return "SIGUSR2";
	case SIGPIPE =>
		return "SIGPIPE";
	case SIGALRM =>
		return "SIGALRM";
	case SIGTERM =>
		return "SIGTERM";
	case SIGCHLD =>
		return "SIGCHLD";
	case SIGCONT =>
		return "SIGCONT";
	case SIGSTOP =>
		return "SIGSTOP";
	case SIGTSTP =>
		return "SIGTSTP";
	case SIGTTIN =>
		return "SIGTTIN";
	case SIGTTOU =>
		return "SIGTTOU";
	case SIGURG =>
		return "SIGURG";
	case SIGXCPU =>
		return "SIGXCPU";
	case SIGXFSZ =>
		return "SIGXFSZ";
	case SIGVTALRM =>
		return "SIGVTALRM";
	case SIGPROF =>
		return "SIGPROF";
	case SIGWINCH =>
		return "SIGWINCH";
	case SIGIO =>
		return "SIGIO";
	case SIGPOLL =>
		return "SIGPOLL";
	case SIGPWR =>
		return "SIGPWR";
	case SIGSYS =>
		return "SIGSYS";
	case => abort(); // unreachable
	};
};
