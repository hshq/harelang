use hare::ast;

// Unwraps a type which may be aliased and returns the underlying type.
export fn dealias(t: *_type) const *_type = {
	for (true) match (t.repr) {
		a: alias => {
			assert(a.secondary != null);
			t = a.secondary: const *_type;
		},
		* => break,
	};
	return t;
};

// Looks up a built-in type.
export fn lookup_builtin(
	store: *typestore,
	_type: ast::builtin_type,
) const *_type = {
	// TODO: &ast::type { ... }
	const atype = ast::_type {
		repr = _type,
		...
	};
	return lookup(store, &atype)!;
};
