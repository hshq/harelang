use hare::ast;
use hare::lex;
use hare::types;

export type fndecl_attrs = enum {
	NONE,
	FINI,
	INIT,
	TEST,
};

export type decl_func = struct {
	symbol: str,
	ident: ast::ident,
	prototype: const *types::_type,
	//body: (expr | void), TODO
	attrs: fndecl_attrs,
};

export type decl = struct {
	exported: bool,
	loc: lex::location,
	decl: (decl_func | void), // TODO: Other decl types
};

export type unit = struct {
	ident: ast::ident,
	decls: []decl,
};

export fn unit_free(unit: unit) void = {
	// TODO
	return;
};
