use fmt;
use hare::lex;
use io;
use os;

export fn main() void = {
	let in = switch (len(os::args)) {
		1 => (os::stdin, "<stdin>"),
		2 => {
			let fd = match (os::open(os::args[1])) {
				err: io::error => fmt::fatal("Error opening '{}': {}",
					os::args[1], io::errstr(err)),
				fd: *io::stream => fd,
			};
			(fd, os::args[1]);
		},
		* => fmt::fatal("Usage: {} [<input>]", os::args[0]),
	};
	defer io::close(in.0);
	let lexer = lex::lexer_init(in.0, in.1);

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
