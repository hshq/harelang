// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

fn isaddrmapped(addr: *opaque) bool = {
	// This is a hack, but it's a common pattern on POSIX for testing the
	// validity of an address.
	static let pipefd: [2]int = [0, 0];
	if (pipefd[0] == 0) {
		match (rt::pipe2(&pipefd, 0)) {
		case rt::errno =>
			return false;
		case void => yield;
		};
	};

	match (rt::write(pipefd[1], addr, 1)) {
	case let err: rt::errno =>
		assert(err == rt::EFAULT);
		return false;
	case size =>
		return true;
	};
};
