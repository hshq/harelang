use hare::lex;

// let foo: int = 0;
// const foo: int = 0;
export type decl_global = struct {
	is_const: bool,
	symbol: str,
	ident: ident,
	_type: _type,
	init: expr,
};

// type foo = int;
export type decl_type = struct {
	ident: ident,
	_type: _type,
};

// Represents the @fini/@init/@test attributes associated with a function
export type fndecl_attrs = enum {
	NONE,
	FINI,
	INIT,
	TEST,
};

// fn main() void = void;
export type decl_func = struct {
	symbol: str,
	ident: ident,
	prototype: _type,
	body: (expr | void),
	attrs: fndecl_attrs,
};

// A declaration
export type decl = struct {
	exported: bool,
	loc: lex::location,
	decl: ([]decl_global | []decl_type | decl_func),
};

// Frees resources associated with a declaration
export fn decl_free(d: decl) void = match (d.decl) {
	g: []decl_global => {
		for (let i = 0z; i < len(g); i += 1) {
			free(g[i].symbol);
			ident_free(g[i].ident);
			type_free(g[i]._type);
			expr_free(g[i].init);
		};
		free(g);
	},
	t: []decl_type => {
		for (let i = 0z; i < len(t); i += 1) {
			ident_free(t[i].ident);
			type_free(t[i]._type);
		};
		free(t);
	},
	f: decl_func => {
		free(f.symbol);
		ident_free(f.ident);
		type_free(f.prototype);
		if (f.body is expr) expr_free(f.body as expr);
	},
};
