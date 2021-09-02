use hare::ast;
use hare::lex;
use hare::types;

// A type-checked and validated Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	result: const *types::_type,
	terminates: bool,
	expr: (compound_expr | constant_expr | void),
};

// A compound expression, i.e. { ... }
export type compound_expr = []*expr;

// The value of a constant expression.
export type constant_expr = ast::value; // TODO: composite types
