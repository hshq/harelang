// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use io::{mode};
use io;
use strings;
use strio;

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
	let buf = bufio::fixed(strings::toutf8(src), mode::READ);
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
	let out = strio::dynamic();
	let z = unparse::subunit(&out, u) as size;
	let unsrc = strio::string(&out);
	assert(z == len(unsrc));
	return unsrc;
};
