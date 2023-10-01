// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use hare::lex;
use hare::parse;
use io;
use os;
use strings;

// TODO: Expand to more kinds of errors
fn printerr(err: parse::error) void = {
	match (err) {
	case let err: lex::syntax =>
		printerr_syntax(err);
	case let err: io::error =>
		fmt::errorln(io::strerror(err))!;
	};
};

fn printerr_syntax(err: lex::syntax) void = {
	let location = err.0, details = err.1;
	let file = os::open(location.path)!;
	defer io::close(file)!;

	let line = 1u;
	for (line < location.line) {
		let r = bufio::read_rune(file) as rune;
		if (r == '\n') {
			line += 1u;
		};
	};

	let line = bufio::read_line(file) as []u8;
	defer free(line);
	let line = strings::fromutf8_unsafe(line);
	fmt::errorfln("{}:{}:{}: syntax error: {}",
		location.path, location.line, location.col, details)!;
	fmt::errorln(line)!;
	for (let i = 0u; i < location.col - 2; i += 1) {
		fmt::error(" ")!;
	};
	fmt::errorln("^--- here")!;
};
