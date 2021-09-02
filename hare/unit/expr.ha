use hare::ast;
use hare::lex;
use hare::types;

// A type-checked and validated Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	result: const *types::_type,
	terminates: bool,
	expr: (binding_expr | compound_expr | constant_expr | return_expr),
};

// A single variable biding.
//
// 	foo: int = bar
export type binding = struct {
	object: *object,
	init: *expr,
};

// A list of variable bindings.
export type binding_expr = []binding;

// A compound expression, i.e. { ... }
export type compound_expr = []*expr;

// The value of a constant expression.
export type constant_expr = ast::value; // TODO: composite types

// A return expression, i.e. return <value>
export type return_expr = nullable *expr;
