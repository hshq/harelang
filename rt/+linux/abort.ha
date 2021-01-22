export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	const prefix = "Abort: ";
	write(2, prefix: *const char, len(prefix));
	write(2, msg: *const char, len(msg));
	write(2, "\n": *const char, 1z);
	kill(getpid(), SIGABRT);
};

// See harec:include/gen.h
const reasons: [3]str = [
	"slice or array access out of bounds",	// 0
	"type assertion failed",		// 1
	"allocation failed",			// 2
];

export @noreturn fn abort_fixed(i: int) void = _abort(reasons[i]);
