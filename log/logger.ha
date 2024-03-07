// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use io;
use os;
use time::date;

// Interface for implementing a logger.
export type logger = struct {
	println: *fn(logger: *logger, fields: fmt::formattable...) void,
	printfln: *fn(logger: *logger, fmt: str, fields: fmt::field...) void,
};

export type stdlogger = struct {
	logger,
	sink: io::handle,
};

// Creates a new standard logger.
export fn new(sink: io::handle) stdlogger = {
	return stdlogger {
		println = &log_println,
		printfln = &log_printfln,
		sink = sink,
	};
};

fn log_println(sink: *logger, fields: fmt::formattable...) void = {
	const sink = sink: *stdlogger;
	assert(sink.println == &log_println);
	const now = date::localnow();
	fmt::fprint(sink.sink, "["): void;
	date::format(sink.sink, date::STAMP, &now): void;
	fmt::fprint(sink.sink, "] "): void;
	fmt::fprintln(sink.sink, fields...): void;
};

fn log_printfln(sink: *logger, fmt: str, fields: fmt::field...) void = {
	const sink = sink: *stdlogger;
	assert(sink.printfln == &log_printfln);
	const now = date::localnow();
	fmt::fprint(sink.sink, "["): void;
	date::format(sink.sink, date::STAMP, &now): void;
	fmt::fprint(sink.sink, "] "): void;
	fmt::fprintfln(sink.sink, fmt, fields...): void;
};
