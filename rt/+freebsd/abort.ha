// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

fn platform_abort(loc: str, msg: str) void = {
	const prefix = "Abort: ";
	const sep = ": ";
	const linefeed = "\n";
	write(STDERR_FILENO, *(&prefix: **void): *const char, len(prefix)): void;
	write(STDERR_FILENO, *(&loc: **void): *const char, len(loc)): void;
	write(STDERR_FILENO, *(&sep: **void): *const char, len(sep)): void;
	write(STDERR_FILENO, *(&msg: **void): *const char, len(msg)): void;
	write(STDERR_FILENO, *(&linefeed: **void): *const char, 1): void;
	kill(getpid(), SIGABRT): void;
	for (true) void;
};
