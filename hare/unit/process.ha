// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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
			case let d: decl =>
				yield d;
			case error =>
				abort(); // TODO
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
	case let co: []ast::decl_const =>
		abort(); // TODO
	case let gl: []ast::decl_global =>
		abort(); // TODO
	case let ty: []ast::decl_type =>
		abort(); // TODO
	case let fu: ast::decl_func =>
		return process_func(ctx, decl, &fu);
	case let ex: ast::assert_expr =>
		abort(); // TODO
	};
};

fn process_func(
	ctx: *context,
	adecl: *ast::decl,
	func: *ast::decl_func,
) (decl | error) = {
	assert(func.attrs & ast::fndecl_attr::TEST == 0); // TODO
	const afndecl = adecl.decl as ast::decl_func;
	const prototype = types::lookup(ctx.store, func.prototype)!;
	const fntype = prototype.repr as types::func;
	assert(fntype.variadism == types::variadism::NONE); // TODO
	assert(len(fntype.params) == 0); // TODO

	ctx.fntype = &fntype;
	const body: nullable *expr = match (afndecl.body) {
	case let abody: *ast::expr =>
		yield process_expr(ctx, abody)?;
	case null =>
		yield null;
	};

	return decl {
		exported = adecl.exported,
		start = adecl.start,
		end = adecl.end,
		decl = decl_func {
			symbol = afndecl.symbol,
			// TODO: Add namespace to ident
			ident = ast::ident_dup(afndecl.ident),
			prototype = prototype,
			body = body,
			// TODO: We should make these enums inherited
			attrs = afndecl.attrs: ast::fndecl_attr,
		},
	};
};

fn process_expr(
	ctx: *context,
	expr: *ast::expr,
) (*expr | error) = {
	match (expr.expr) {
	case ast::access_expr =>
		return process_access(ctx, expr);
	case ast::alloc_expr =>
		abort(); // TODO
	case ast::append_expr =>
		abort(); // TODO
	case ast::assert_expr =>
		abort(); // TODO
	case ast::assign_expr =>
		abort(); // TODO
	case ast::binarithm_expr =>
		abort(); // TODO
	case ast::binding_expr =>
		return process_binding(ctx, expr);
	case ast::break_expr =>
		abort(); // TODO
	case ast::call_expr =>
		abort(); // TODO
	case ast::cast_expr =>
		abort(); // TODO
	case ast::compound_expr =>
		return process_compound(ctx, expr);
	case ast::literal_expr =>
		return process_constant(ctx, expr);
	case ast::continue_expr =>
		abort(); // TODO
	case ast::defer_expr =>
		abort(); // TODO
	case ast::delete_expr =>
		abort(); // TODO
	case ast::error_assert_expr =>
		abort(); // TODO
	case ast::for_expr =>
		abort(); // TODO
	case ast::free_expr =>
		abort(); // TODO
	case ast::if_expr =>
		abort(); // TODO
	case ast::match_expr =>
		abort(); // TODO
	case ast::len_expr =>
		abort(); // TODO
	case ast::size_expr =>
		abort(); // TODO
	case ast::offset_expr =>
		abort(); // TODO
	case ast::propagate_expr =>
		abort(); // TODO
	case ast::return_expr =>
		return process_return(ctx, expr);
	case ast::slice_expr =>
		abort(); // TODO
	case ast::switch_expr =>
		abort(); // TODO
	case ast::unarithm_expr =>
		abort(); // TODO
	};
};

fn process_access(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const access_expr = aexpr.expr as ast::access_expr;
	const (result, ex) = match (access_expr) {
	case let ai: ast::access_identifier =>
		const object = match (ctx_lookup(ctx, ai)) {
		case null =>
			abort(); // TODO: Error
		case let obj: *object =>
			yield obj;
		};
		yield (object._type, object);
	case let ai: ast::access_index =>
		abort(); // TODO
	case let af: ast::access_field =>
		abort(); // TODO
	case let at: ast::access_tuple =>
		abort(); // TODO
	};
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = result,
		expr = ex,
		terminates = false,
	});
};

fn process_binding(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const bind = aexpr.expr as ast::binding_expr;
	assert(!bind.is_static && bind.kind == ast::binding_kind::LET);

	let bindings: bindings = [];
	for (let i = 0z; i < len(bind.bindings); i += 1) {
		const item = bind.bindings[i];
		const init = process_expr(ctx, item.init)?;
		const _type = match (item._type) {
		case null =>
			abort(); // TODO
		case let ty: *ast::_type =>
			yield types::lookup(ctx.store, ty)!;
		};
		const object = scope_insert(ctx, object {
			kind = object_kind::BIND,
			// TODO: tuple unpacking
			ident = ast::ident_dup([item.name as str]),
			name = ast::ident_dup([item.name as str]),
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
	const compound_expr = aexpr.expr as ast::compound_expr;
	const scope = scope_push(ctx, scope_class::COMPOUND);

	let exprs: compound = alloc([], len(compound_expr.exprs));
	let i = 0z;
	for (i < len(compound_expr.exprs); i += 1) {
		append(exprs, process_expr(ctx, compound_expr.exprs[i])?);
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

fn process_constant(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const constexpr = aexpr.expr as ast::literal_expr;
	const (result, ex) = match (constexpr) {
	case let v: ast::value =>
		yield (
			// TODO: iconst/fconst lowering
			types::lookup_builtin(ctx.store, match (v) {
			case ast::_null =>
				yield ast::builtin_type::NULL;
			case let b: bool =>
				yield ast::builtin_type::BOOL;
			case let s: str =>
				yield ast::builtin_type::STR;
			case let r: rune =>
				yield ast::builtin_type::RUNE;
			case void =>
				yield ast::builtin_type::VOID;
			}),
			v: constant,
		);
	case ast::array_literal =>
		abort(); // TODO
	case let v: ast::number_literal =>
		yield (
			types::lookup_builtin(ctx.store, switch (v.suff) {
			case lex::ltok::LIT_U8 =>
				yield ast::builtin_type::U8;
			case lex::ltok::LIT_U16 =>
				yield ast::builtin_type::U16;
			case lex::ltok::LIT_U32 =>
				yield ast::builtin_type::U32;
			case lex::ltok::LIT_U64 =>
				yield ast::builtin_type::U64;
			case lex::ltok::LIT_UINT =>
				yield ast::builtin_type::UINT;
			case lex::ltok::LIT_SIZE =>
				yield ast::builtin_type::SIZE;
			case lex::ltok::LIT_I8 =>
				yield ast::builtin_type::I8;
			case lex::ltok::LIT_I16 =>
				yield ast::builtin_type::I16;
			case lex::ltok::LIT_I32 =>
				yield ast::builtin_type::I32;
			case lex::ltok::LIT_I64 =>
				yield ast::builtin_type::I64;
			case lex::ltok::LIT_INT, lex::ltok::LIT_ICONST =>
				yield ast::builtin_type::INT;
			case lex::ltok::LIT_F32 =>
				yield ast::builtin_type::F32;
			case lex::ltok::LIT_F64, lex::ltok::LIT_FCONST =>
				yield ast::builtin_type::F64;
			case => abort(); // unreachable
			}),
			v.value: constant,
		);
	case ast::struct_literal =>
		abort(); // TODO
	case ast::tuple_literal =>
		abort(); // TODO
	};
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		result = result,
		expr = ex,
		...
	});
};

fn process_return(ctx: *context, aexpr: *ast::expr) (*expr | error) = {
	const ret = aexpr.expr as ast::return_expr;
	const rval = match (ret) {
	case null =>
		yield null;
	case let aexpr: *ast::expr =>
		yield process_expr(ctx, aexpr)?;
	};
	// TODO: assert(types::assignable(ctx.fntype.result as *types::func, rval.type));
	return alloc(expr {
		start = aexpr.start,
		end = aexpr.end,
		terminates = true,
		result = &types::builtin_void,
		expr = rval: _return,
	});
};
