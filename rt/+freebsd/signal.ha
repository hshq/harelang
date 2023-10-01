// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: work when _NSIG != 32

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
