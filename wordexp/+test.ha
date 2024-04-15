// SPDX-License-Identifier: MIT
// (c) Hare authors <https://harelang.org>

use os;
use strings;

fn streq(a: []str, b: []str) bool = {
	if (len(a) != len(b)) {
		return false;
	};
	for (let i = 0z; i < len(a); i += 1) {
		if (a[i] != b[i]) {
			return false;
		};
	};
	return true;
};

@test fn wordexp() void = {
	os::setenv("TESTVAR", "test value")!;
	os::unsetenv("UNSET")!;
	static const cases: [_](str, []str) = [
		(``, []),
		(" \t\n", []),
		(`hello world`, ["hello", "world"]),
		(`hello $TESTVAR`, ["hello", "test", "value"]),
		(`hello "$TESTVAR"`, ["hello", "test value"]),
		(`hello $(echo world)`, ["hello", "world"]),
		(`hello $((2+2))`, ["hello", "4"]),
		(`hello $UNSET`, ["hello"]),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const (in, out) = cases[i];
		const words = wordexp(in)!;
		defer strings::freeall(words);
		assert(streq(words, out));
	};
};

@test fn wordexp_error() void = {
	os::unsetenv("UNSET")!;
	static const cases: [_](str, flag) = [
		(`hello $UNSET`, flag::UNDEF),
		(`hello $(`, 0),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const (in, flag) = cases[i];
		const result = wordexp(in, flag);
		assert(result is sh_error);
	};
};
