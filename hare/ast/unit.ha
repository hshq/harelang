// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// A sub-unit, typically representing a single source file.
export type subunit = struct {
	imports: []import,
	decls: []decl,
};

// Frees resources associated with a [[subunit]].
export fn subunit_finish(u: subunit) void = {
	imports_finish(u.imports);
	for (let i = 0z; i < len(u.decls); i += 1) {
		decl_finish(u.decls[i]);
	};
	free(u.decls);
};
