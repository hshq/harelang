// Identifies a single object, e.g. foo::bar::baz, ordered from least to most
// significant part (foo::bar::baz becomes ["baz", "bar", "foo"].
export type ident = []str;

// Frees resources associated with an identifier
export fn ident_free(ident: ident) void = {
	for (let i = 0z; i < len(ident); i += 1) {
		free(ident[i]);
	};
	free(ident);
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
