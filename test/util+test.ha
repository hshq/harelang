// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

let want_abort = false;

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = {
	if (rt::jmp == null) {
		abort("Attempted to call test::expectabort outside of @test function");
	};
	want_abort = true;
};
