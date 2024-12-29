// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;
use time;
use unix;

// Forward declaration to resolve signal => test => signal loop
fn test::require(keywords: str...) void;

let ok = false;

fn handle_signal(
	_sig: sig,
	info: *siginfo,
	ucontext: *opaque
) void = {
	ok = true;
};

@test fn test_handle() void = {
	test::require("integration");
	handle(sig::USR1, &handle_signal);
	match (rt::kill(unix::getpid(), sig::USR1)) {
	case let errno: rt::errno =>
		abort(errors::strerror(errors::errno(errno)));
	case void => void;
	};

	assert(ok);
};
