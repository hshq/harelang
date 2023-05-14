// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export @noreturn @symbol("rt.abort") fn _abort(loc: str, msg: str) void = {
	platform_abort(loc, msg);
};

// See harec:include/gen.h
const reasons: [_]str = [
	"slice or array access out of bounds",			// 0
	"type assertion failed",				// 1
	"out of memory",					// 2
	"static insert/append exceeds slice capacity",		// 3
	"execution reached unreachable code (compiler bug)",	// 4
	"slice allocation capacity smaller than initializer"	// 5
	"assertion failed",					// 6
	"error occured",					// 7
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	// TODO: This is also platform-specific
	const prefix = "Abort: ";
	const sep = ": ";
	const linefeed = "\n";
	write(STDERR_FILENO, *(&prefix: **void): *const u8, len(prefix)): void;
	write(STDERR_FILENO, *(&loc: **void): *const u8, len(loc)): void;
	write(STDERR_FILENO, *(&sep: **void): *const u8, len(sep)): void;
	write(STDERR_FILENO, *(&reasons[i]: **void): *const u8, len(reasons[i])): void;
	write(STDERR_FILENO, *(&linefeed: **void): *const u8, 1): void;
	kill(getpid(), SIGABRT): void;
	for (true) void;
};
