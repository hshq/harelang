// Identifies a single object, e.g. foo::bar::baz.
export type ident = []str;

// Maximum length of an identifier, as the sum of the lengths of its parts plus
// one for each namespace deliniation.
//
// In other words, the length of "a::b::c" is 5.
export def IDENT_MAX: size = 255;

// Frees resources associated with an identifier.
export fn ident_free(ident: ident) void = {
	for (let i = 0z; i < len(ident); i += 1) {
		free(ident[i]);
	};
	free(ident);
};

// Returns true if two idents are identical.
export fn ident_eq(a: ident, b: ident) bool = {
	if (len(a) != len(b)) {
		return false;
	};
	for (let i = 0z; i < len(a); i += 1) {
		if (a[i] != b[i]) {
			return false;
		};
	};
	return true;
};

// A sub-unit, typically representing a single source file.
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

// Frees resources associated with an import.
export fn import_free(import: import) void = {
	match (import) {
		m: import_module => ident_free(m: ident),
		a: import_alias => {
			ident_free(a.ident);
			free(a.alias);
		},
		o: import_objects => {
			ident_free(o.ident);
			for (let i = 0z; i < len(o.objects); i += 1) {
				free(o.objects[i]);
			};
			free(o.objects);
		},
	};
};

// TODO
export type declaration = void;
