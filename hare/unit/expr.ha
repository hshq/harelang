use hare::ast;
use hare::lex;
use hare::types;

// A type-checked and validated Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	result: const *types::_type,
	terminates: bool,
	expr: (access | bindings | compound | constant | _return),
};

export type access = (access_object | access_field | access_index | access_tuple);

export type access_object = *object;

export type access_field = struct {
	object: *expr,
	field: const *types::struct_field,
};

export type access_index = struct {
	object: *expr,
	index: *expr,
};

export type access_tuple = struct {
	object: *expr,
	value: const *types::tuple_value,
};

// A single variable biding.
//
// 	foo: int = bar
export type binding = struct {
	object: *object,
	init: *expr,
};

// A list of variable bindings.
export type bindings = []binding;

// A compound expression, i.e. { ... }
export type compound = []*expr;

// The value of a constant expression.
export type constant = ast::value; // TODO: composite types

// A return expression, i.e. return <value>
export type _return = nullable *expr;
