// Identifies a single object, e.g. foo::bar::baz
export type ident = struct {
	name: str,
	ns: nullable *ident,
};

// Frees resources associated with an identifier
export fn ident_finish(ident: *ident) void = {
	match (ident.ns) {
		null => void,
		ns: *ident => ident_finish(ns),
	};
	free(ident.name);
};

// A sub-unit, typically representing a single source file
export type subunit = struct {
	imports: []import,
	declarations: []declaration,
};

// use module;
export type import_module = ident;

// use alias = module;
export type import_alias = struct {
	ident: ident,
	alias: str,
};

// use module::{foo, bar, baz};
export type import_objects = struct {
	ident: ident,
	objects: []str,
};

// An imported module
export type import = (import_module | import_alias | import_objects);

// TODO
export type declaration = void;
