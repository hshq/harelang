export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	const prefix = "Abort: ";
	write(2, prefix: *const char, len(prefix));
	write(2, msg: *const char, len(msg));
	write(2, "\n": *const char, 1);
	kill(getpid(), SIGABRT);
};

// See harec:include/gen.h
const reasons: [_]str = [
	"slice or array access out of bounds",	// 0
	"type assertion failed",		// 1
	"out of memory",			// 2
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	const prefix = "Abort: ";
	const sep = ": ";
	write(2, prefix: *const char, len(prefix));
	write(2, loc: *const char, len(loc));
	write(2, sep: *const char, len(sep));
	write(2, reasons[i]: *const char, len(reasons[i]));
	write(2, "\n": *const char, 1);
	kill(getpid(), SIGABRT);
};
