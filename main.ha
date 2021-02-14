use fmt;
use hare::lex;
use io;
use os;

export fn main() void = {
	let lexer = lex::lexer_init(os::stdin, "<stdin>");
	for (true) {
		match (lex::lex(&lexer)) {
			t: (lex::token, lex::location) => {
				let tok = t.0, loc = t.1;
				fmt::println("{}@{},{}: '{}'",
					loc.path, loc.line, loc.col,
					lex::tokstr(tok));
			},
			err: lex::error => fmt::fatal("Error: {}", lex::errstr(err)),
			io::EOF => break,
			* => abort(),
		};
	};
};
