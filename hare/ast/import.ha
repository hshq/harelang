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
