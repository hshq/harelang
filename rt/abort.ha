export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	platform_abort(msg);
};

// See harec:include/gen.h
const reasons: [_]str = [
	"slice or array access out of bounds",	// 0
	"type assertion failed",		// 1
	"out of memory",			// 2
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	// TODO: This is also platform-specific
	const prefix = "Abort: ";
	const sep = ": ";
	const linefeed = "\n";
	write(2, *(&prefix: **void): *const char, len(prefix))!;
	write(2, *(&loc: **void): *const char, len(loc))!;
	write(2, *(&sep: **void): *const char, len(sep))!;
	write(2, *(&reasons[i]: **void): *const char, len(reasons[i]))!;
	write(2, *(&linefeed: **void): *const char, 1)!;
	kill(getpid(), SIGABRT)!;
};
