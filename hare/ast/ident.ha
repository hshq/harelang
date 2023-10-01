// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;

// Identifies a single object, e.g. foo::bar::baz.
export type ident = []str;

// Maximum length of an identifier, as the sum of the lengths of its parts plus
// one for each namespace deliniation.
//
// In other words, the length of "a::b::c" is 5.
export def IDENT_MAX: size = 255;

// Frees resources associated with an [[ident]]ifier.
export fn ident_free(ident: ident) void = strings::freeall(ident);

// Returns true if two [[ident]]s are identical.
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

// Duplicates an [[ident]].
export fn ident_dup(id: ident) ident = strings::dupall(id);
