// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use hare::ast;
use hare::types;

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
		scope = alloc(scope { class = scope_class::UNIT, ... }),
		...
	};
	scan(&ctx, subunits)?;
	return process(&ctx, subunits);
};
