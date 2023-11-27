// SPDX-License-Identifier: MIT
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use io;
use os::exec;

// Tagged union of possible wordexp error conditions.
export type error = !(io::error | exec::error | utf8::invalid | sh_error);

// An error occured during shell expansion.
export type sh_error = !void;

// Converts an [[error]] to a human-friendly string.
export fn strerror(err: error) const str = {
	match (err) {
	case let err: io::error =>
		return io::strerror(err);
	case let err: exec::error =>
		return exec::strerror(err);
	case utf8::invalid =>
		return "Word expansion returned invalid UTF-8 data";
	case sh_error =>
		return "An error occured during shell expansion";
	};
};
