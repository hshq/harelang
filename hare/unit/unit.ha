use hare::ast;
use hare::lex;
use hare::types;

// Attributes applicable to a function declaration.
export type fndecl_attrs = enum {
	NONE,
	FINI,
	INIT,
	TEST,
};

// A function declaration.
export type decl_func = struct {
	symbol: str,
	ident: ast::ident,
	prototype: const *types::_type,
	body: nullable *expr,
	attrs: fndecl_attrs,
};

// A declaration within a unit.
export type decl = struct {
	exported: bool,
	loc: lex::location,
	decl: (decl_func | void), // TODO: Other decl types
};

// A single compilation unit, representing all of the members of a namespace.
export type unit = struct {
	ident: ast::ident,
	decls: []decl,
};

export fn unit_free(unit: unit) void = {
	// TODO
	return;
};
