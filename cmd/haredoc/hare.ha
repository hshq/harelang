use fmt;
use hare::ast;
use os;
use strings;

// Formats output as Hare source code (prototypes)
fn emit_hare(decls: []ast::decl) (void | error) = {
	// TODO: Should we emit the dependencies, too?
	for (let i = 0z; i < len(decls); i += 1) {
		const decl = decls[i];
		if (!decl.exported || decl.docs == "") {
			continue;
		};

		const iter = strings::tokenize(decl.docs, "\n");
		for (true) match (strings::next_token(&iter)) {
			s: str => if (len(s) != 0) {
				fmt::printfln("//{}", s)?;
			},
			void => break,
		};

		unparse_decl(os::stdout, decl)?;
		fmt::print("\n\n")?;
	};
};
