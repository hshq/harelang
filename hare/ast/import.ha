// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::lex;
use strings;

// An imported module.
//
// 	use foo;
// 	use foo = bar;
// 	use foo::{bar, baz};
// 	use foo::*;
export type import = struct {
	start: lex::location,
	end: lex::location,
	ident: ident,
	bindings: (void | import_alias | import_members | import_wildcard),
};

// An import alias.
//
// 	use foo = bar;
export type import_alias = str;

// An import members list.
//
// 	use foo::{bar, baz};
export type import_members = []str;

// An import wildcard.
//
// 	use foo::*;
export type import_wildcard = void;

// Frees resources associated with an [[import]].
export fn import_finish(import: import) void = {
	ident_free(import.ident);
	match (import.bindings) {
	case let alias: import_alias =>
		free(alias);
	case let objects: import_members =>
		strings::freeall(objects);
	case => void;
	};
};

// Frees resources associated with each [[import]] in a slice, and then
// frees the slice itself.
export fn imports_finish(imports: []import) void = {
	for (let i = 0z; i < len(imports); i += 1) {
		import_finish(imports[i]);
	};
	free(imports);
};
