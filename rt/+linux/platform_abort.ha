// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

@noreturn fn platform_abort(loc: str, msg: str) void = {
	const prefix = "Abort: ";
	const sep = ": ";
	const linefeed = "\n";
	write(STDERR_FILENO, *(&prefix: **opaque): *const u8, len(prefix)): void;
	write(STDERR_FILENO, *(&loc: **opaque): *const u8, len(loc)): void;
	write(STDERR_FILENO, *(&sep: **opaque): *const u8, len(sep)): void;
	write(STDERR_FILENO, *(&msg: **opaque): *const u8, len(msg)): void;
	write(STDERR_FILENO, *(&linefeed: **opaque): *const u8, 1): void;
	kill(getpid(), SIGABRT): void;
	for (true) void;
};
