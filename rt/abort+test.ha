// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	reason = abort_reason { loc = "", msg = msg };
	longjmp(&jmp, 1);
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
	reason = abort_reason { loc = loc, msg = reasons[i] };
	longjmp(&jmp, 1);
};
