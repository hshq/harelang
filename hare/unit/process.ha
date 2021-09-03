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
	return match (decl.decl) {
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
	const fntype = prototype.repr as types::func;
	assert(fntype.variadism == types::variadism::NONE); // TODO
	assert(len(fntype.params) == 0); // TODO

	ctx.fntype = &fntype;
	const body: nullable *expr = match (afndecl.body) {
		abody: ast::expr => process_expr(ctx, &abody)?,
		void => null,
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
	ast::access_expr => process_access(ctx, expr),
	ast::alloc_expr => abort(), // TODO
	ast::append_expr => abort(), // TODO
	ast::assert_expr => abort(), // TODO
	ast::assign_expr => abort(), // TODO
	ast::binarithm_expr => abort(), // TODO
	ast::binding_expr => process_binding(ctx, expr),
	ast::break_expr => abort(), // TODO
	ast::call_expr => abort(), // TODO
	ast::cast_expr => abort(), // TODO
	ast::compound_expr => process_compound(ctx, expr),
	ast::constant_expr => process_constant(ctx, expr),
	ast::continue_expr => abort(), // TODO
	ast::defer_expr => abort(), // TODO
	ast::delete_expr => abort(), // TODO
	ast::for_expr => abort(), // TODO
	ast::free_expr => abort(), // TODO
	ast::if_expr => abort(), // TODO
	ast::match_expr => abort(), // TODO
	ast::len_expr => abort(), // TODO
	ast::size_expr => abort(), // TODO
	ast::offset_expr => abort(), // TODO
	ast::propagate_expr => abort(), // TODO
	ast::return_expr => process_return(ctx, expr),
	ast::slice_expr => abort(), // TODO
	ast::switch_expr => abort(), // TODO
	ast::unarithm_expr => abort(), // TODO
};

fn process_access(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const access = aexpr.expr as ast::access_expr;
	const op: (const *types::_type, access) = match (access) {
		ai: ast::access_identifier => {
			const object = match (ctx_lookup(ctx, ai)) {
				null => abort(), // TODO: Error
				obj: *object => obj,
			};
			yield (object._type, object);
		},
		ai: ast::access_index => abort(), // TODO
		af: ast::access_field => abort(), // TODO
		at: ast::access_tuple => abort(), // TODO
	};
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = op.0,
		expr = op.1,
	});
};

@test fn access() void = {
	// TODO: Test error cases, more access types
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const object = scope_insert(&ctx, object {
		kind = object_kind::BIND,
		ident = ["hello"],
		name = ["hello"],
		_type = &types::builtin_u32,
	});
	const aexpr = parse_expr("hello");
	defer ast::expr_free(aexpr);
	const expr = process_access(&ctx, aexpr)!;
	const access = expr.expr as access;
	const ao = access as access_object;
	assert(ao == object);
	assert(expr.result == &types::builtin_u32);
};

fn process_binding(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const bind = aexpr.expr as ast::binding_expr;
	assert(!bind.is_static && !bind.is_const); // TODO

	let bindings: bindings = [];
	for (let i = 0z; i < len(bind.bindings); i += 1) {
		const item = bind.bindings[i];
		const init = process_expr(ctx, item.init)?;
		const _type = match (item._type) {
			null => abort(), // TODO
			ty: *ast::_type => types::lookup(ctx.store, ty)!,
		};
		const object = scope_insert(ctx, object {
			kind = object_kind::BIND,
			ident = ast::ident_dup([item.name]),
			name = ast::ident_dup([item.name]),
			_type = _type,
			...
		});
		append(bindings, binding {
			object = object,
			init = init,
		});
	};
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = &types::builtin_void,
		expr = bindings,
		...
	});
};

fn process_compound(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const compound = aexpr.expr as ast::compound_expr;
	const scope = scope_push(ctx, scope_class::COMPOUND);

	let exprs: compound = alloc([], len(compound.exprs));
	let i = 0z;
	for (i < len(compound.exprs); i += 1) {
		append(exprs, process_expr(ctx, compound.exprs[i])?);
	};

	scope_pop(ctx);
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = &types::builtin_void, // TODO: Pick result type
		expr = exprs,
		terminates = exprs[i - 1].terminates,
		...
	});
};

@test fn compound() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("{ void; void; void; }");
	defer ast::expr_free(aexpr);
	const expr = process_compound(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const compound = expr.expr as compound;
	assert(len(compound) == 3);

	const aexpr = parse_expr("{ return; }");
	defer ast::expr_free(aexpr);
	const expr = process_compound(&ctx, aexpr)!;
	assert(expr.terminates);

	// TODO: test yields
};

fn process_constant(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const constexpr = aexpr.expr as ast::constant_expr;
	// TODO: Tuple unpacking
	const er: (const *types::_type, constant) = match (constexpr) {
		v: ast::value => (
			// TODO: iconst/fconst lowering
			types::lookup_builtin(ctx.store, match (v) {
				ast::_null => ast::builtin_type::NULL,
				b: bool => ast::builtin_type::BOOL,
				s: str => ast::builtin_type::STR,
				r: rune => ast::builtin_type::RUNE,
				i: i64 => ast::builtin_type::INT,
				u: u64 => ast::builtin_type::UINT,
				f: f64 => ast::builtin_type::F64,
				void => ast::builtin_type::VOID,
			}),
			v,
		),
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
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const constexpr = expr.expr as constant;
	assert(constexpr is void);

	const aexpr = parse_expr("true");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant;
	assert(constexpr as bool == true);

	const aexpr = parse_expr("false");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant;
	assert(constexpr as bool == false);

	const aexpr = parse_expr("null");
	defer ast::expr_free(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::NULL);
	assert(expr.expr is constant);

	const cases: [_](str, types::builtin, ast::value) = [
		("1234", types::builtin::INT, 1234),
		("1234u", types::builtin::UINT, 1234u),
		("\"hello world\"", types::builtin::STR, "hello world"),
		("'!'", types::builtin::RUNE, '!'),
		("13.37", types::builtin::F64, 13.37f64),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const case = cases[i];
		const aexpr = parse_expr(case.0);
		defer ast::expr_free(aexpr);
		const expr = process_constant(&ctx, aexpr)!;
		assert(expr.result.repr as types::builtin == case.1);
		const constexpr = expr.expr as constant;
		match (case.2) {
			s: str => assert(constexpr as str == s),
			r: rune => assert(constexpr as rune == r),
			i: i64 => assert(constexpr as i64 == i),
			u: u64 => assert(constexpr as u64 == u),
			f: f64 => assert(constexpr as f64 == f),
			void => abort(),
		};
	};
};

fn process_return(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const ret = aexpr.expr as ast::return_expr;
	const rval = match (ret) {
		null => null,
		aexpr: *ast::expr => process_expr(ctx, aexpr)?,
	};
	// TODO: assert(types::assignable(ctx.fntype.result, rval.type));
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		terminates = true,
		result = &types::builtin_void,
		expr = rval: _return,
	});
};

@test fn _return() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("return;");
	defer ast::expr_free(aexpr);
	const expr = process_return(&ctx, aexpr)!;
	assert(expr.terminates);
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const rval = expr.expr as _return;
	assert(rval == null);

	const aexpr = parse_expr("return 10;");
	defer ast::expr_free(aexpr);
	const expr = process_return(&ctx, aexpr)!;
	assert(expr.terminates);
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const rval = expr.expr as _return;
	assert(rval != null);
	assert((rval: *expr).expr is constant);
};
