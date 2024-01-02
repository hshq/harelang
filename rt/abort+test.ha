// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Signature for abort handler function.
export type abort_handler = fn(
	path: *str,
	line: u64,
	col: u64,
	msg: str,
) never;

// Sets a new global runtime abort handler.
export fn onabort(handler: *abort_handler) void = {
	return; // no-op on +test (XXX: Do something here?)
};

export type abort_reason = struct {
	path: nullable *str,
	line: u64,
	col: u64,
	msg: str,
};

export let jmp: nullable *jmpbuf = null;
export let reason: abort_reason = abort_reason { ... };

export @symbol("rt.abort") fn _abort(
	path: *str,
	line: u64,
	col: u64,
	msg: str,
) void = {
	match (jmp) {
	case let j: *jmpbuf =>
		reason = abort_reason {
			path = path,
			line = line,
			col = col,
			msg = msg,
		};
		longjmp(j, 1); // test::status::ABORT
	case null =>
		platform_abort(path, line, col, msg);
	};
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
	"error occurred",					// 7
];

export fn abort_fixed(path: *str, line: u64, col: u64, i: u64) void = {
	_abort(path, line, col, reasons[i]);
};
