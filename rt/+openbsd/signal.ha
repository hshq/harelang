// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export fn sigemptyset(set: *sigset) void = {
	*set = 0;
};

export fn sigaddset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return *__errno(): errno;
	};
	*set |= 1u << (signum: uint - 1);
};

export fn sigdelset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return *__errno(): errno;
	};
	*set &= ~(1u << (signum: uint - 1));
};

export fn sigismember(set: *sigset, signum: int) (bool | errno) = {
	if (signum < 1 || signum > NSIG) {
		return *__errno(): errno;
	};
	return (*set & (1u << (signum: uint - 1))) != 0;
};

export fn sigfillset(set: *sigset) (void | errno) = {
	*set = ~0u;
};

// Test sigset operations do not fail for valid signal numbers.
@test fn sigset_valid_signum() void = {
	let set: sigset = 0;
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
	let set: sigset = 0;
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
