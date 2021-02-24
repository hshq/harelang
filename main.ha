use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
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
	let imports = match (parse::imports(&lexer)) {
		err: parse::error => fmt::fatal("{}", parse::errstr(err)),
		i: []ast::import => i,
	};
	defer for (let i = 0z; i < len(imports); i += 1) {
		ast::import_free(imports[i]);
	};

	fmt::errorln("{} has {} imports:", in.1, len(imports));
	for (let i = 0z; i < len(imports); i += 1) {
		let name = match (imports[i]) {
			m: ast::import_module => m: ast::ident,
			a: ast::import_alias => a.ident,
			o: ast::import_objects => o.ident,
		};
		fmt::printf("use ");
		for (let i = len(name): int - 1; i >= 0; i -= 1) {
			fmt::printf("{}{}", name[i],
				if (i != 0) "::" else ";\n");
		};
	};
};
