// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use hare::lex;

// A constant declaration.
//
// 	def foo: int = 0;
export type decl_const = struct {
	ident: ident,
	_type: _type,
	init: *expr,
};

// A global declaration.
//
// 	let foo: int = 0;
// 	const foo: int = 0;
export type decl_global = struct {
	is_const: bool,
	symbol: str,
	ident: ident,
	_type: _type,
	init: nullable *expr,
};

// A type declaration.
//
// 	type foo = int;
export type decl_type = struct {
	ident: ident,
	_type: _type,
};

// Attributes applicable to a function declaration.
export type fndecl_attrs = enum {
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
	prototype: _type,
	body: (expr | void),
	attrs: fndecl_attrs,
};

// A Hare declaration.
export type decl = struct {
	exported: bool,
	start: lex::location,
	end: lex::location,
	decl: ([]decl_const | []decl_global | []decl_type | decl_func),

	// Only valid if the lexer has comments enabled
	docs: str,
};

// Frees resources associated with a declaration.
export fn decl_free(d: decl) void = {
	free(d.docs);
	match (d.decl) {
	case let g: []decl_global =>
		for (let i = 0z; i < len(g); i += 1) {
			free(g[i].symbol);
			ident_free(g[i].ident);
			type_free(g[i]._type);
			expr_free(g[i].init);
		};
		free(g);
	case let t: []decl_type =>
		for (let i = 0z; i < len(t); i += 1) {
			ident_free(t[i].ident);
			type_free(t[i]._type);
		};
		free(t);
	case let f: decl_func =>
		free(f.symbol);
		ident_free(f.ident);
		type_free(f.prototype);
		if (f.body is expr) expr_free(f.body as expr);
	case let c: []decl_const =>
		for (let i = 0z; i < len(c); i += 1) {
			ident_free(c[i].ident);
			type_free(c[i]._type);
			expr_free(c[i].init);
		};
		free(c);
	};
};
