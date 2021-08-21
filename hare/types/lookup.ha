use hare::ast;

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
