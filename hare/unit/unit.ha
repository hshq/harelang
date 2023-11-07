// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::ast;
use hare::lex;
use hare::types;


// A function declaration.
export type decl_func = struct {
	symbol: str,
	ident: ast::ident,
	prototype: const *types::_type,
	body: nullable *expr,
	attrs: ast::fndecl_attr,
};

// A declaration within a unit.
export type decl = struct {
	exported: bool,
	start: lex::location,
	end: lex::location,
	decl: (decl_func | void), // TODO: Other decl types
};

// A single compilation unit, representing all of the members of a namespace.
export type unit = struct {
	ident: ast::ident,
	decls: []decl,
};

export fn unit_finish(unit: unit) void = {
	// TODO
	return;
};
