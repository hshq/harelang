// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use os;
use rt;
use strings;

let want_abort = false;

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = {
	if (rt::jmp == null) {
		abort("Attempted to call test::expectabort outside of @test function");
	};
	want_abort = true;
};

// Skip the currently running test.
export fn skip(reason: str) never = {
	if (rt::jmp == null) {
		abort("Attempted to call test::skip outside of @test function");
	};
	rt::reason = rt::abort_reason {
		msg = reason,
		...
	};
	rt::longjmp(&jmpbuf, status::SKIP);
};

// Check the $HARETEST_INCLUDE space-delimited environment variable for
// keywords. If all the keywords are present, return void. Otherwise, skip the
// currently running test.
export fn require(keywords: str...) void = {
	for :keywords (let keyword .. keywords) {
		let tokr = strings::tokenize(os::tryenv("HARETEST_INCLUDE", ""), " ");
		for (true) {
			match (strings::next_token(&tokr)) {
			case let tok: str =>
				if (tok == keyword) {
					continue :keywords;
				};
			case done =>
				skip(fmt::asprintf(
					"Requires HARETEST_INCLUDE='{}'",
					strings::join(" ", keywords...),
				));
			};
		};
	};
};
