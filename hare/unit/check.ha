use hare::ast;
use hare::types;

type context = struct {
	store: *types::typestore,
	unit: *unit,
	scope: *scope,
};

// Type checks a set of [[hare::ast::subunit]]s and determines if it is
// logically consistent, then returns the corresponding [[unit]], which from
// then on is guaranteed to be compilable.
export fn check(
	store: *types::typestore,
	ident: ast::ident,
	subunits: const []ast::subunit,
) (unit | error) = {
	let unit = unit {
		ident = ident,
		decls = [],
	};
	let ctx = context {
		store = store,
		unit = &unit,
		scope = alloc(scope { ... }),
	};

	scan(&ctx, subunits)?;
	// TODO: validate

	return unit;
};
