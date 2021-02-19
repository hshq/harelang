use fmt;
use hare::lex;
use io;
use os;

export fn main() void = {
	let lexer = lex::lexer_init(os::stdin, "<stdin>");
	for (true) match (lex::lex(&lexer)) {
		t: (lex::token, lex::location) => {
			let tok = t.0, loc = t.1;
			fmt::println("{}@{},{}: {4}{}{4}",
				loc.path, loc.line, loc.col,
				lex::tokstr(tok),
				if (tok is lex::name) "'" else "");
		},
		err: lex::error => fmt::fatal("Error: {}", lex::errstr(err)),
		io::EOF => break,
		* => abort(),
	};
};
