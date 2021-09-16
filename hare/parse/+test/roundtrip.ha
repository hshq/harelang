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
	defer io::close(buf);
	let lexer = lex::init(buf, "<test>");
	let u = ast::subunit {
		imports = [],
		decls: []ast::decl = match (decls(&lexer)) {
		case decls: []ast::decl =>
			yield decls;
		case err: error =>
			fmt::errorln(strerror(err))!;
			abort();
		},
	};
	defer ast::subunit_free(u);
	let out = strio::dynamic();
	unparse::subunit(out, u) as size;
	let unsrc = strio::finish(out);
	defer free(unsrc);
	if (unsrc != src) {
		fmt::errorfln("=== wanted\n{}", src)!;
		fmt::errorfln("=== got\n{}", unsrc)!;
		abort();
	};
};
