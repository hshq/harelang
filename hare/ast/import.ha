// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use hare::lex;

// Variants of the import statement
export type import_mode = enum uint {
	// use module;
	IDENT = 0,
	// use alias = module;
	ALIAS = 1 << 0,
	// use module::{foo, bar, baz};
	MEMBERS = 1 << 1,
	// use module::*;
	WILDCARD = 1 << 2,
};

// An imported module.
export type import = struct {
	start: lex::location,
	end: lex::location,
	mode: import_mode,
	ident: ident,
	alias: str,
	objects: []((str | void), str),
};

// Frees resources associated with an [[import]].
export fn import_finish(import: import) void = {
	ident_free(import.ident);
	if (import.mode == import_mode::ALIAS) {
		free(import.alias);
	};
	for (let i = 0z; i < len(import.objects); i += 1) {
		free(import.objects[i].1);
		match (import.objects[i].0) {
		case void => void;
		case let s: str =>
			free(s);
		};
	};
	free(import.objects);
};

// Frees resources associated with each [[import]] in a slice, and then
// frees the slice itself.
export fn imports_finish(imports: []import) void = {
	for (let i = 0z; i < len(imports); i += 1) {
		import_finish(imports[i]);
	};
	free(imports);
};
