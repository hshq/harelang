// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use os;
use path;

export fn main() void = {
	let buf = path::init()!;
	let status: int = os::status::SUCCESS;
	iter(&buf, &status);
	os::exit(status);
};

fn iter(buf: *path::buffer, status: *int) void = {
	let it = os::iter(path::string(buf))!;
	defer fs::finish(it);
	for (let ent => fs::next(it)!) {
		path::push(buf, ent.name)!;
		defer path::pop(buf);
		const st = os::stat(path::string(buf))!;
		if (fs::isfile(st.mode)) {
			match (path::peek_ext(buf)) {
			case let s: str =>
				if (s == "ha") {
					parse(path::string(buf), status);
				};
			case void => void;
			};
		} else if (fs::isdir(st.mode)) {
			iter(buf, status);
		};
	};
};

fn parse(path: str, status: *int) void = {
	const f = os::open(path)!;
	defer io::close(f)!;
	let sc = bufio::newscanner(f);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, path);
	match (parse::subunit(&lexer)) {
	case let su: ast::subunit =>
		ast::subunit_finish(su);
	case let err: parse::error =>
		fmt::errorln(parse::strerror(err))!;
		*status = os::status::FAILURE;
	};
};
