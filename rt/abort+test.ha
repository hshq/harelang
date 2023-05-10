// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

export type abort_reason = struct {
	loc: str,
	msg: str,
};

export let jmp: nullable *jmpbuf = null;
export let reason: abort_reason = abort_reason { ... };

export @noreturn @symbol("rt.abort") fn _abort(msg: str) void = {
	match (jmp) {
	case let j: *jmpbuf =>
		reason = abort_reason { loc = "", msg = msg };
		longjmp(j, 1);
	case null =>
		platform_abort(msg);
	};
};

// See harec:include/gen.h
const reasons: [_]str = [
	"slice or array access out of bounds",			// 0
	"type assertion failed",				// 1
	"out of memory",					// 2
	"static insert/append exceeds slice capacity",		// 3
	"execution reached unreachable code (compiler bug)",	// 4
	"slice allocation capacity smaller than initializer"	// 5
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	match (jmp) {
	case let j: *jmpbuf =>
		reason = abort_reason { loc = loc, msg = reasons[i] };
		longjmp(j, 1);
	case null =>
		platform_abort(reasons[i]);
	};
};
