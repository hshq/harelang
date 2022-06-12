// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	platform_abort(msg);
};

// See harec:include/gen.h
const reasons: [_]str = [
	"slice or array access out of bounds",			// 0
	"type assertion failed",				// 1
	"out of memory",					// 2
	"static insert/append exceeds slice capacity",		// 3
	"execution reached unreachable code (compiler bug)",	// 4
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	// TODO: This is also platform-specific
	const prefix = "Abort: ";
	const sep = ": ";
	const linefeed = "\n";
	write(STDERR_FILENO, *(&prefix: **void): *const char, len(prefix)): void;
	write(STDERR_FILENO, *(&loc: **void): *const char, len(loc)): void;
	write(STDERR_FILENO, *(&sep: **void): *const char, len(sep)): void;
	write(STDERR_FILENO, *(&reasons[i]: **void): *const char, len(reasons[i])): void;
	write(STDERR_FILENO, *(&linefeed: **void): *const char, 1): void;
	kill(getpid(), SIGABRT): void;
	for (true) void;
};
