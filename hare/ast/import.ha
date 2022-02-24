// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

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
	mode: import_mode,
	ident: ident,
	alias: str,
	objects: []((str | void), str),
};

// Frees resources associated with an [[import]].
export fn import_free(import: import) void = {
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
