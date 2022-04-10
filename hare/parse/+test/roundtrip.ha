// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
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
	let buf = bufio::fixed(strings::toutf8(src), mode::READ);
	let lexer = lex::init(&buf, "<test>", lex::flags::COMMENTS);
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
	defer ast::subunit_free(u);
	let out = strio::dynamic();
	defer io::close(&out);
	let z = unparse::subunit(&out, u) as size;
	let unsrc = strio::string(&out);
	assert(z == len(unsrc));
	if (unsrc != src) {
		fmt::errorfln("=== wanted\n{}", src)!;
		fmt::errorfln("=== got\n{}", unsrc)!;
		abort();
	};
};
