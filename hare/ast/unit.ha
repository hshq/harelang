// A sub-unit, typically representing a single source file.
export type subunit = struct {
	imports: []import,
	decls: []decl,
};

// Frees resources associated with a [[subunit]].
export fn subunit_free(u: subunit) void = {
	for (let i = 0z; i < len(u.imports); i += 1) {
		import_free(u.imports[i]);
	};
	free(u.imports);
	for (let i = 0z; i < len(u.decls); i += 1) {
		decl_free(u.decls[i]);
	};
	free(u.decls);
};
