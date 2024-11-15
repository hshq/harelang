// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use os;
use rt;

// The global logger instance.
export let global: *logger = &_default;

// Default logger that writes to [[os::stderr]].
export const default: *logger = &_default;

let _default: stdlogger = stdlogger {
	println = &log_println,
	printfln = &log_printfln,
	sink = rt::STDERR_FILENO: io::file,
};

// Sets the global logger instance to the provided logger.
export fn setlogger(log: *logger) void = {
	global = log;
};
