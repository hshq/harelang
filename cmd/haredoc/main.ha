use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use os;
use strings;

export fn main() void = {
	const lexer = lex::init(os::stdin, "<stdin>", lex::flags::COMMENTS);
	const unit = match (parse::subunit(&lexer)) {
		u: ast::subunit => u,
		err: parse::error => fmt::fatal(parse::strerror(err)),
	};
	for (let i = 0z; i < len(unit.decls); i += 1) {
		const decl = unit.decls[i];
		if (!decl.exported || decl.docs == "") {
			continue;
		};

		let iter = strings::tokenize(decl.docs, "\n");
		for (true) match (strings::next_token(&iter)) {
			s: str => if (len(s) != 0) {
				fmt::printfln("//{}", s);
			},
			void => break,
		};

		match (unparse_decl(os::stdout, decl)) {
			err: io::error => fmt::fatal(io::strerror(err)),
			size => void,
		};

		fmt::println();
		fmt::println();
	};
};
