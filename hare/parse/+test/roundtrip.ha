// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use io::{mode};
use io;
use memio;
use strings;

fn roundtrip(src: str) void = {
	let unsrc = _roundtrip(src);
	defer free(unsrc);
	if (unsrc != src) {
		fmt::errorfln("=== wanted\n{}", src)!;
		fmt::errorfln("=== got\n{}", unsrc)!;
		abort();
	};
};

fn roundtrip_reparse(src: str) void = {
	let unsrc = _roundtrip(src);
	defer free(unsrc);
	roundtrip(unsrc);
};

fn _roundtrip(src: str) str = {
	let buf = memio::fixed(strings::toutf8(src));
	let lexer = lex::init(&buf, "<test>", lex::flag::COMMENTS);
	defer lex::finish(&lexer);
	let u = ast::subunit {
		imports = [],
		decls: []ast::decl = match (decls(&lexer)) {
		case let decls: []ast::decl =>
			yield decls;
		case let err: error =>
			fmt::errorln(strerror(err))!;
			abort();
		},
	};
	defer ast::subunit_finish(u);
	let out = memio::dynamic();
	let z = unparse::subunit(&out, &unparse::syn_wrap, u)!;
	let unsrc = memio::string(&out)!;
	assert(z == len(unsrc));
	return unsrc;
};
