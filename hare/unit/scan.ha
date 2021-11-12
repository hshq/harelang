use hare::ast;
use hare::types;

// The scan phase determines the types of all declarations in the unit, and
// handles forward references, so that the next phase (validate) is simplified.
fn scan(ctx: *context, subunits: const []ast::subunit) (void | error) = {
	for (let i = 0z; i < len(subunits); i += 1) {
		let subunit = &subunits[i];
		assert(len(subunit.imports) == 0); // TODO

		scope_push(ctx, scope_class::SUBUNIT);
		for (let j = 0z; j < len(subunit.decls); j += 1) {
			let decl = &subunit.decls[j];
			match (scan_decl(ctx, decl)) {
			case void => void;
			case types::deferred =>
				abort(); // TODO
			case error =>
				abort(); // TODO
			};
		};
		scope_pop(ctx);
	};
};

fn scan_decl(
	ctx: *context,
	decl: *ast::decl,
) (void | types::deferred | error) = {
	// TODO: match on &decl.decl
	match (decl.decl) {
	case co: []ast::decl_const =>
		abort(); // TODO
	case gl: []ast::decl_global =>
		abort(); // TODO
	case ty: []ast::decl_type =>
		abort(); // TODO
	case fu: ast::decl_func =>
		return scan_func(ctx, decl, fu);
	};
};

fn scan_func(
	ctx: *context,
	decl: *ast::decl,
	func: ast::decl_func,
) (void | types::deferred | error) = {
	assert(func.attrs & ast::fndecl_attrs::TEST == 0); // TODO
	const fntype = match (types::lookup(ctx.store, &func.prototype)) {
	case err: types::error =>
		return err;
	case types::deferred =>
		return types::deferred;
	case fntype: const *types::_type =>
		yield fntype;
	};
	scope_insert(ctx, object {
		kind = object_kind::DECL,
		// TODO: Add namespace to ident
		ident = ast::ident_dup(func.ident),
		name = ast::ident_dup(func.ident),
		_type = fntype,
		...
	});
	return;
};
