// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use errors;
use io;
use rt;

// Configures a new signal handler, returning the old details (which can be
// passed to [[restore]] to restore its behavior).
//
// The variadic parameters specify either [[flag]] to enable or a signal mask
// to use via [[sigset]]; if the latter is provided no more than one may be
// used.
export fn handle(
	signum: signal,
	handler: *handler,
	opt: (flag | sigset)...
) sigaction = {
	let sa_mask = newset();

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
		sa_sigaction = handler: *fn(_: int, _: *rt::siginfo, _: *void) void,
		sa_mask = sa_mask,
		sa_flags = sa_flags,
		// Filled in by rt:
		sa_restorer = null: *fn () void,
	};
	let old = rt::sigact { ... };
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

export type sigaction = rt::sigact;

export type sigset = rt::sigset;

// Creates a new signal set filled in with the provided signals (or empty if
// none are provided).
export fn newset(items: signal...) sigset = {
	let set = sigset { ... };
	rt::sigemptyset(&set);
	set_add(&set, items...);
	return set;
};

// Sets a [[sigset]] to empty.
export fn set_empty(set: *sigset) void = {
	rt::sigemptyset(set);
};

// Adds signals to a [[sigset]].
export fn set_add(set: *sigset, items: signal...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigaddset(set, items[i])!;
	};
};

// Removes signals from a [[sigset]].
export fn set_del(set: *sigset, items: signal...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		rt::sigdelset(set, items[i])!;
	};
};

// Returns true if the given signal is a member of this [[sigset]].
export fn set_member(set: *sigset, item: signal) bool = {
	return rt::sigismember(set, item)! == 1;
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
		// TODO: Add enum type for this
		code: int,
	},
	// Pads the structure out to the length used by the kernel; do not use.
	_si_pad: [128 - 3 * size(int)]u8,
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

// Creates a signal file.
export fn signalfd(opt: (flag | sigset)...) (io::file | errors::error) = {
	let sa_mask = newset();

	let sa_flags = 0, nmask = 0;
	for (let i = 0z; i < len(opt); i += 1) {
		match (opt[i]) {
		case let flag: flag =>
			sa_flags |= flag;
		case let mask: sigset =>
			assert(nmask == 0, "Multiple signal masks provided to signal::signalfd");
			nmask += 1;
			sa_mask = mask;
		};
	};

	match (rt::signalfd(-1, &sa_mask, sa_flags)) {
	case let fd: int =>
		return fd;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Updates a signalfd with new options.
export fn update(
	fd: io::file,
	opt: (flag | sigset)...
) (void | errors::error) = {
	let sa_mask = newset();

	let sa_flags = 0, nmask = 0;
	for (let i = 0z; i < len(opt); i += 1) {
		match (opt[i]) {
		case let flag: flag =>
			sa_flags |= flag;
		case let mask: sigset =>
			assert(nmask == 0, "Multiple signal masks provided to signal::update");
			nmask += 1;
			sa_mask = mask;
		};
	};

	match (rt::signalfd(fd, &sa_mask, sa_flags)) {
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
		code = si.ssi_code,
		...
	};
};

// Hangup.
export def SIGHUP: signal = rt::SIGHUP;
// Terminal signalerrupt signal.
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
