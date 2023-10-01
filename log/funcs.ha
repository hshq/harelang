// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use os;

// Prints data to the log, with a newline.
export fn lprintln(log: *logger, fields: fmt::formattable...) void = {
	log.println(log, fields...);
};

// Formats and prints data to the log, with a newline.
export fn lprintfln(log: *logger, fmt: str, fields: fmt::field...) void = {
	log.printfln(log, fmt, fields...);
};

// Prints data to the global log, with a newline.
export fn println(fields: fmt::formattable...) void = {
	lprintln(global, fields...);
};

// Formats and prints data to the global log, with a newline.
export fn printfln(fmt: str, fields: fmt::field...) void = {
	lprintfln(global, fmt, fields...);
};

// Prints data to the log with a newline, then terminates the process.
export fn lfatal(log: *logger, fields: fmt::formattable...) never = {
	lprintln(log, fields...);
	os::exit(255);
};

// Formats and prints data to the log with new line, then terminates the
// process.
export fn lfatalf(
	log: *logger,
	fmt: str,
	fields: fmt::field...
) never = {
	lprintfln(log, fmt, fields...);
	os::exit(255);
};

// Prints data to the global log with new line, then terminates the process.
export fn fatal(fields: fmt::formattable...) never = {
	lprintln(global, fields...);
	os::exit(255);
};

// Formats and prints data to the global log with new line, then terminates the
// process.
export fn fatalf(fmt: str, fields: fmt::field...) never = {
	lprintfln(global, fmt, fields...);
	os::exit(255);
};
