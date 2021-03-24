use hare::ast;
use hare::lex;
use hare::lex::{btoken};

// Parses an expression
// TODO: Actually implement this
export fn expr(lexer: *lex::lexer) (ast::expr | error) = {
	want_btoken(lexer, btoken::VOID)?;
	return void;
};
