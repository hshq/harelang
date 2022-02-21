// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// TODO: work when _NSIG != 32

export fn sigemptyset(set: *sigset) int = {
	for (let i = 0z; i < len(set.__bits); i += 1) {
		set.__bits[i] = 0;
	};
	return 0;
};

export fn sigaddset(set: *sigset, signum: int) (int | errno) = {
	if (signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__bits[signum >> 5] |= (1 << signum): u32;
	return 0;
};

export fn sigdelset(set: *sigset, signum: int) (int | errno) = {
	if (signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	set.__bits[signum >> 5] &= ~(1 << signum: u32);
	return 0;
};

export fn sigismember(set: *sigset, signum: int) (int | errno) = {
	if (signum > NSIG) {
		return EINVAL;
	};
	signum -= 1;
	if ((set.__bits[signum >> 5] & (1 << signum: u32)) != 0) {
		return 1;
	} else {
		return 0;
	};
};

export fn sigfillset(set: *sigset) (int | errno) = {
	for (let i = 0z; i < len(set.__bits); i += 1) {
		set.__bits[i] = ~0u32;
	};
	return 0;
};
