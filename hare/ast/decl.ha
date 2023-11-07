// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::lex;

// A constant declaration.
//
// 	def foo: int = 0;
export type decl_const = struct {
	ident: ident,
	_type: nullable *_type,
	init: *expr,
};

// A global declaration.
//
// 	let foo: int = 0;
// 	const foo: int = 0;
export type decl_global = struct {
	is_const: bool,
	is_threadlocal: bool,
	symbol: str,
	ident: ident,
	_type: nullable *_type,
	init: nullable *expr,
};

// A type declaration.
//
// 	type foo = int;
export type decl_type = struct {
	ident: ident,
	_type: *_type,
};

// Attributes applicable to a function declaration.
export type fndecl_attr = enum {
	NONE,
	FINI,
	INIT,
	TEST,
};

// A function declaration.
//
// fn main() void = void;
export type decl_func = struct {
	symbol: str,
	ident: ident,
	prototype: *_type,
	body: nullable *expr,
	attrs: fndecl_attr,
};

// A Hare declaration.
export type decl = struct {
	exported: bool,
	start: lex::location,
	end: lex::location,
	decl: ([]decl_const | []decl_global | []decl_type | decl_func |
		assert_expr),

	// Only valid if the lexer has comments enabled
	docs: str,
};

// Frees resources associated with a declaration.
export fn decl_finish(d: decl) void = {
	free(d.docs);
	match (d.decl) {
	case let g: []decl_global =>
		for (let i = 0z; i < len(g); i += 1) {
			free(g[i].symbol);
			ident_free(g[i].ident);
			type_finish(g[i]._type);
			free(g[i]._type);
			expr_finish(g[i].init);
			free(g[i].init);
		};
		free(g);
	case let t: []decl_type =>
		for (let i = 0z; i < len(t); i += 1) {
			ident_free(t[i].ident);
			type_finish(t[i]._type);
			free(t[i]._type);
		};
		free(t);
	case let f: decl_func =>
		free(f.symbol);
		ident_free(f.ident);
		type_finish(f.prototype);
		free(f.prototype);
		expr_finish(f.body);
		free(f.body);
	case let c: []decl_const =>
		for (let i = 0z; i < len(c); i += 1) {
			ident_free(c[i].ident);
			type_finish(c[i]._type);
			free(c[i]._type);
			expr_finish(c[i].init);
			free(c[i].init);
		};
		free(c);
	case let e: assert_expr =>
		expr_finish(e.cond);
		free(e.cond);
		expr_finish(e.message);
		free(e.message);
	};
};
