use hare::ast;
use hare::lex;

export fn subunit(lexer: *lex::lexer) (ast::subunit | error) = {
	let i = imports(lexer)?;
	let d = decls(lexer)?;
	return ast::subunit {
		imports = i,
		decls = d,
	};
};
