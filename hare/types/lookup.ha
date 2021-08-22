use hare::ast;

// Unwraps a type which may be aliased and returns the underlying type.
export fn dealias(t: *_type) const *_type = {
	for (true) match (t._type) {
		a: alias => {
			assert(a._type != null);
			t = a._type: const *_type;
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
		_type = _type,
		...
	};
	return lookup(store, &atype)!;
};
