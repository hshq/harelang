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
