use hare::ast;
use hare::lex;
use hare::types;

fn process(ctx: *context, subunits: const []ast::subunit) (unit | error) = {
	let unit = unit {
		ident = [], // TODO
		decls = [],
	};

	for (let i = 0z; i < len(subunits); i += 1) {
		let subunit = subunits[i];
		for (let j = 0z; j < len(subunit.decls); j += 1) {
			let adecl = &subunit.decls[j];
			let decl = match (process_decl(ctx, adecl)) {
				d: decl => d,
				error => abort(), // TODO
			};
			append(unit.decls, decl);
		};
	};

	return unit;
};

fn process_decl(
	ctx: *context,
	decl: *ast::decl,
) (decl | error) = {
	// TODO: match on &decl.decl
	match (decl.decl) {
		co: []ast::decl_const => abort(), // TODO
		gl: []ast::decl_global => abort(), // TODO
		ty: []ast::decl_type => abort(), // TODO
		fu: ast::decl_func => process_func(ctx, decl, fu),
	};
};

fn process_func(
	ctx: *context,
	adecl: *ast::decl,
	func: ast::decl_func,
) (decl | error) = {
	assert(func.attrs & ast::fndecl_attrs::TEST == 0); // TODO
	const afndecl = adecl.decl as ast::decl_func;
	const prototype = types::lookup(ctx.store, &func.prototype)!;
	const fntype = prototype._type as types::func;
	assert(fntype.variadism == types::variadism::NONE); // TODO
	assert(len(fntype.params) == 0); // TODO

	let body: nullable *expr = null;
	// TODO: Change the afndecl body field to nullable *ast::expr
	if (afndecl.body is ast::expr) {
		const abody = afndecl.body as ast::expr;
		body = process_expr(ctx, &abody)?;
	};

	return decl {
		exported = adecl.exported,
		loc = adecl.loc,
		decl = decl_func {
			symbol = afndecl.symbol,
			// TODO: Add namespace to ident
			ident = ast::ident_dup(afndecl.ident),
			prototype = prototype,
			body = body,
			// TODO: We should make these enums inherited
			attrs = afndecl.attrs: fndecl_attrs,
		},
	};
};

fn process_expr(
	ctx: *context,
	expr: *ast::expr,
) (*expr | error) = match (expr.expr) {
	ast::access_expr => abort(), // TODO
	ast::alloc_expr => abort(), // TODO
	ast::append_expr => abort(), // TODO
	ast::assert_expr => abort(), // TODO
	ast::assign_expr => abort(), // TODO
	ast::binarithm_expr => abort(), // TODO
	ast::binding_expr => abort(), // TODO
	ast::break_expr => abort(), // TODO
	ast::call_expr => abort(), // TODO
	ast::cast_expr => abort(), // TODO
	ast::constant_expr => process_constant(ctx, expr),
	ast::continue_expr => abort(), // TODO
	ast::defer_expr => abort(), // TODO
	ast::delete_expr => abort(), // TODO
	ast::for_expr => abort(), // TODO
	ast::free_expr => abort(), // TODO
	ast::if_expr => abort(), // TODO
	ast::list_expr => abort(), // TODO
	ast::match_expr => abort(), // TODO
	ast::len_expr => abort(), // TODO
	ast::size_expr => abort(), // TODO
	ast::offset_expr => abort(), // TODO
	ast::propagate_expr => abort(), // TODO
	ast::return_expr => abort(), // TODO
	ast::slice_expr => abort(), // TODO
	ast::switch_expr => abort(), // TODO
	ast::unarithm_expr => abort(), // TODO
};

fn process_constant(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const constexpr = aexpr.expr as ast::constant_expr;
	const er: (const *types::_type, constant_expr) = match (constexpr) {
		void => (
			types::lookup_builtin(ctx.store, ast::builtin_type::VOID),
			void: constant_expr,
		),
		b: bool => (
			types::lookup_builtin(ctx.store, ast::builtin_type::BOOL),
			b,
		),
		ast::_null => (
			types::lookup_builtin(ctx.store, ast::builtin_type::NULL),
			_null,
		),
		lex::value => abort(), // TODO
		ast::array_constant => abort(), // TODO
		ast::struct_constant => abort(), // TODO
		ast::tuple_constant => abort(), // TODO
	};
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = er.0,
		expr = er.1,
		...
	});
};

@test fn constant() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("void");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result._type as types::builtin == types::builtin::VOID);
	const constexpr = expr.expr as constant_expr;
	assert(constexpr is void);

	const aexpr = parse_expr("true");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result._type as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant_expr;
	assert(constexpr as bool == true);

	const aexpr = parse_expr("false");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result._type as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant_expr;
	assert(constexpr as bool == false);

	const aexpr = parse_expr("null");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result._type as types::builtin == types::builtin::NULL);
	assert(expr.expr is constant_expr);
};
