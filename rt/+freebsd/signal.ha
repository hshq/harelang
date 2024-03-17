// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: work when _NSIG != 32

export fn alarm(sec: uint) uint = {
	let nval = itimerval { ... };
	let oval = itimerval { ... };
	nval.it_value.tv_sec = sec: time_t;
	setitimer(ITIMER_REAL, &nval, &oval)!;
	if (oval.it_value.tv_usec != 0) {
		oval.it_value.tv_sec += 1;
	};
	return oval.it_value.tv_sec: uint;
};

export def ITIMER_REAL: int = 0;
export def ITIMER_VIRTUAL: int = 1;
export def ITIMER_PROF: int = 2;

export type itimerval = struct {
	it_interval: timeval,
	it_value: timeval,
};

export fn getitimer(
	which: int,
	cur: *itimerval,
) (void | errno) = {
	wrap_return(syscall2(SYS_getitimer, which: u64, cur: uintptr: u64))?;
};

export fn setitimer(
	which: int,
	newval: *itimerval,
	oldval: nullable *itimerval,
) (void | errno) = {
	wrap_return(syscall3(SYS_setitimer,
			which: u64,
			newval: uintptr: u64,
			oldval: uintptr: u64))?;
};

export fn sigwait(set: *sigset, sig: *int) (void | errno) = {
	*sig = sigwaitinfo(set, null)?;
};

export fn sigwaitinfo(
	set: *sigset,
	info: nullable *siginfo,
) (int | errno) = {
	return wrap_return(syscall2(SYS_sigwaitinfo,
		set: uintptr: u64,
		info: uintptr: u64,
	))?: int;
};

export fn sigtimedwait(
	set: *sigset,
	info: nullable *siginfo,
	timeout: nullable *timespec,
) (int | errno) = {
	return wrap_return(syscall3(SYS_sigtimedwait,
		set: uintptr: u64,
		info: uintptr: u64,
		timeout: uintptr: u64,
	))?: int;
};

export fn sigemptyset(set: *sigset) void = {
	for (let i = 0z; i < len(set.__bits); i += 1) {
		set.__bits[i] = 0;
	};
};

export fn sigaddset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__bits[signum >> 5] |= (1 << signum): u32;
};

export fn sigdelset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__bits[signum >> 5] &= ~(1 << signum: u32);
};

export fn sigismember(set: *sigset, signum: int) (bool | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	return (set.__bits[signum >> 5] & (1 << signum: u32)) != 0;
};

export fn sigfillset(set: *sigset) (void | errno) = {
	for (let i = 0z; i < len(set.__bits); i += 1) {
		set.__bits[i] = ~0u32;
	};
};

// Test sigset operations do not fail for valid signal numbers.
@test fn sigset_valid_signum() void = {
	let set: sigset = sigset { ... };
	sigemptyset(&set);

	assert(!(sigismember(&set, 1) is errno), "Unexpected error");
	assert(!(sigismember(&set, 15) is errno), "Unexpected error");
	assert(!(sigismember(&set, NSIG) is errno), "Unexpected error");

	assert(!(sigaddset(&set, 1) is errno), "Unexpected error");
	assert(!(sigaddset(&set, 15) is errno), "Unexpected error");
	assert(!(sigaddset(&set, NSIG) is errno), "Unexpected error");

	// It's ok to add a signal that is already present in the set.
	assert(!(sigaddset(&set, 1) is errno), "Unexpected error");

	assert(!(sigdelset(&set, 1) is errno), "Unexpected error");
	assert(!(sigdelset(&set, 15) is errno), "Unexpected error");
	assert(!(sigdelset(&set, NSIG) is errno), "Unexpected error");

	// It's ok to delete a signal that is not present in the set.
	assert(!(sigdelset(&set, 10) is errno), "Unexpected error");
};

// Test sigset operations fail for invalid signal numbers.
@test fn sigset_invalid_signum() void = {
	let set: sigset = sigset { ... };
	sigemptyset(&set);

	assert(sigismember(&set, -1) is errno, "Expected error");
	assert(sigismember(&set, 0) is errno, "Expected error");
	assert(sigismember(&set, NSIG + 1) is errno, "Expected error");

	assert(sigaddset(&set, -1) is errno, "Expected error");
	assert(sigaddset(&set, 0) is errno, "Expected error");
	assert(sigaddset(&set, NSIG + 1) is errno, "Expected error");

	assert(sigdelset(&set, -1) is errno, "Expected error");
	assert(sigdelset(&set, 0) is errno, "Expected error");
	assert(sigdelset(&set, NSIG + 1) is errno, "Expected error");
};
