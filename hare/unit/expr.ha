use hare::lex;
use hare::types;

// A type-checked and validated Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	result: const *types::_type,
	terminates: bool,
	expr: (constant_expr | void),
};

// The value "null".
export type _null = void;

// The value of a constant expression.
export type constant_expr = (void | bool | _null | lex::value); // TODO: composite types
