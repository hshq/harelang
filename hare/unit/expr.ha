// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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

// An access expression.
export type access = (access_object | access_field | access_index | access_tuple);

// An access expression for an object.
export type access_object = *object;

// An access expression for a struct field.
export type access_field = struct {
	object: *expr,
	field: const *types::struct_field,
};

// An access expression for a slice or array index.
export type access_index = struct {
	object: *expr,
	index: *expr,
};

// An access expression for a tuple value.
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
export type constant = (...ast::value | i64 | u64 | f64); // TODO: composite types

// A return expression, i.e. return <value>
export type _return = nullable *expr;
