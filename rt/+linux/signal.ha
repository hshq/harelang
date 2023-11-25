// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: work when _NSIG != 64

export fn sigemptyset(set: *sigset) void = {
	set.__val[0] = 0;
};

export fn sigaddset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__val[0] |= (1 << signum): u64;
};

export fn sigdelset(set: *sigset, signum: int) (void | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__val[0] &= ~(1 << signum: u64);
};

export fn sigismember(set: *sigset, signum: int) (bool | errno) = {
	if (signum < 1 || signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	return (set.__val[0] & (1 << signum: u64)) != 0;
};

export fn sigfillset(set: *sigset) void = {
	set.__val[0] = ~0u64;
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
