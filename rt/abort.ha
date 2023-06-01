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
	"slice allocation capacity smaller than initializer",	// 5
	"assertion failed",					// 6
	"error occured",					// 7
];

export @noreturn fn abort_fixed(loc: str, i: int) void = {
	platform_abort(loc, reasons[i]);
};
