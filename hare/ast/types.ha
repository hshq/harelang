// Identifies a single object, e.g. foo::bar::baz
export type identifier = struct {
	name: str,
	ns: nullable *identifier,
};

export fn identifier_finish(ident: *identifier) void = {
	match (ident.ns) {
		null => void,
		ns: *identifier => identifier_finish(ns),
	};
	free(ident.name);
};

// A sub-unit, typically representing a single source file
export type subunit = struct {
	imports: []import,
	declarations: []declaration,
};

// use module;
export type import_module = identifier;

// use alias = module;
export type import_alias = struct {
	ident: identifier,
	alias: str,
};

// use module::{foo, bar, baz};
export type import_objects = struct {
	ident: identifier,
	objects: []str,
};

// An imported module
export type import = (import_module | import_alias | import_objects);

// TODO
export type declaration = void;
