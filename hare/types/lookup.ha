// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use hare::ast;

// Unwraps a type which may be aliased and returns the underlying type.
export fn dealias(t: *_type) const *_type = {
	for (true) match (t.repr) {
	case let a: alias =>
		t = a.secondary as const *_type;
	case =>
		break;
	};
	return t;
};

// Looks up a built-in type.
export fn lookup_builtin(
	store: *typestore,
	_type: ast::builtin_type,
) const *_type = lookup(store, &ast::_type {
	repr = _type,
	...
})!;
