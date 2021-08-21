use hare::ast;
use hare::types;

type context = struct {
	store: *types::typestore,
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
	let ctx = context {
		store = store,
		scope = alloc(scope { ... }),
	};
	scan(&ctx, subunits)?;
	return process(&ctx, subunits);
};
