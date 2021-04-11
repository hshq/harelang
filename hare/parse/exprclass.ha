use hare::ast;
use hare::lex::{ltok};
use hare::lex;
use io;

// Parses an expression.
export fn expression(lexer: *lex::lexer) (ast::expr | error) = {
	// TODO: if, for, switch, match, etc
	return binarithm(lexer, void, 0);
};
