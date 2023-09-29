// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;

// Any error that may occur during TTY-related tasks.
export type error = !(errors::invalid | errors::unsupported | errors::noentry);

// Converts an [[error]] to a human-friendly string.
export fn strerror(err: error) str = {
	return errors::strerror(err);
};

// Structure representing dimensions of a terminal.
export type ttysize = struct {
	rows:    u16,
	columns: u16,
};
