// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;

// A logger that does not print any messages.
export const silent: *logger = &_silent;

let _silent: logger = logger {
	println = &silent_println,
	printfln = &silent_printfln,
};

fn silent_println(l: *logger, fields: fmt::formattable...) void = return;
fn silent_printfln(l: *logger, fmt: str, fields: fmt::field...) void = return;
