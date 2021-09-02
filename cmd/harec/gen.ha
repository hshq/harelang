use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::types;
use hare::types::{builtin};
use hare::unit;
use io;
use os;
use strings;

fn gen(store: *types::typestore, unit: *unit::unit) void = {
	// TODO: context_init
	let ctx = context {
		out = bufio::dynamic(io::mode::WRITE),
		store = store,
		unit = unit,
		arch = struct {
			// TODO: Initialize these properly
			ptr: *qtype = &qlong,
			sz: *qtype = &qlong,
		},
		...
	};
	defer io::close(ctx.out);
	for (let i = 0z; i < len(unit.decls); i += 1) match (unit.decls[i].decl) {
		func: unit::decl_func => gen_func(&ctx, &unit.decls[i]),
		* => abort(), // TODO
	};
};

fn gen_func(ctx: *context, decl: *unit::decl) void = {
	// TODO: const fndecl = &decl.decl as *unit::decl_func;
	const fndecl = decl.decl as unit::decl_func;
	const body = match (fndecl.body) {
		null => return, // Prototype
		expr: *unit::expr => expr,
	};
	const fntype = fndecl.prototype.repr as types::func;
	assert(fntype.flags == 0);
	ctx.serial = 0;

	const ident = module::identuscore(fndecl.ident);
	defer free(ident);
	fmt::printf("{}function section \".text.{}\" \"ax\"",
		if (decl.exported) "export " else "", ident)!;
	const rtype = fntype.result;
	const has_rval = match (types::dealias(rtype).repr) {
		bi: types::builtin => bi != types::builtin::VOID,
		* => true,
	};
	if (has_rval) {
		const qrtype = qtype_lookup(ctx, rtype, false);
		fmt::printf(" {}", qtype_repr(qrtype))!;
	};
	fmt::printf(" ${}(", ident)!;
	assert(len(fntype.params) == 0); // TODO
	fmt::println(") {")!;
	fmt::println(mklabel(ctx, "start"))!;

	// We use a dynamic buffer here so that we can emit alloc instructions
	// on-demand at the start of the function, rather than spread out
	// through the body. This is more reliable on qbe's ARM backend, and
	// generates better IL besides.
	bufio::reset(ctx.out);

	fmt::fprintln(ctx.out, mklabel(ctx, "body"))!;

	const rval = gen_expr(ctx, body);
	if (!body.terminates) {
		if (has_rval) {
			emit(ctx.out, void, qinstr::RET, rval);
		} else {
			emit(ctx.out, void, qinstr::RET);
		};
	};

	io::write(os::stdout, bufio::buffer(ctx.out))!;
	fmt::println("}\n")!;
};

fn gen_store(ctx: *context, object: value, value: value) void = {
	match (types::dealias(object._type).repr) {
		bi: types::builtin => switch (bi) {
			builtin::STR => abort(), // TODO
			* => void,
		},
		types::_struct => abort(), // TODO
		(types::array | types::slice | types::tagged | types::tuple) =>
			abort(), // TODO
		* => void,
	};
	const instr = qinstr_store(ctx, object._type);
	emit(ctx.out, void, instr, value, object);
};

fn gen_expr(ctx: *context, expr: *unit::expr) value = {
	return match (expr.expr) {
		unit::binding_expr => gen_binding(ctx, expr),
		unit::compound_expr => gen_compound(ctx, expr),
		unit::constant_expr => gen_const(ctx, expr),
		unit::return_expr => gen_return(ctx, expr),
	};
};

fn gen_expr_at(ctx: *context, expr: *unit::expr, at: value) void = {
	match (expr.expr) {
		// TODO: Some functions will prefer _at
		* => void,
	};
	const value = gen_expr(ctx, expr);
	gen_store(ctx, at, value);
};

fn gen_binding(ctx: *context, expr: *unit::expr) value = {
	const bindings = expr.expr as unit::binding_expr;
	for (let i = 0z; i < len(bindings); i += 1) {
		const item = bindings[i];
		const temp = mktemp(ctx);
		append(ctx.bindings, binding {
			object = item.object,
			name = temp,
		});
		const value = value {
			value = temp,
			_type = item.object._type,
		};
		// TODO: tuple unpacking
		// const lval, instr = allocval(value);
		const instr = qinstr_alloc(value._type);
		const lval = mklval(ctx, value);
		emit(ctx.out, lval, instr, value._type.sz);
		gen_expr_at(ctx, item.init, value);
	};
	return vvoid;
};

fn gen_compound(ctx: *context, expr: *unit::expr) value = {
	const compound = expr.expr as unit::compound_expr;
	for (let i = 0z; i < len(compound); i += 1) {
		gen_expr(ctx, compound[i]);
	};
	return vvoid; // TODO
};

fn gen_const(ctx: *context, expr: *unit::expr) value = {
	const constexpr = expr.expr as unit::constant_expr;
	const val: qval = match (constexpr) {
		void => return vvoid,
		b: bool => (if (b) 1u32 else 0u32): constant,
		ast::_null => 0u64, // XXX: Arch
		r: rune => r: u32,
		v: (u64 | f64) => v,
		i: i64 => i: u64,
		s: str => abort(), // TODO
		// TODO: Aggregate types
	};
	return value {
		value = val,
		_type = expr.result,
	};
};

fn gen_return(ctx: *context, expr: *unit::expr) value = {
	const rexpr = expr.expr as unit::return_expr;
	match (rexpr) {
		null => emit(ctx.out, void, qinstr::RET),
		expr: *unit::expr => {
			emit(ctx.out, void, qinstr::RET, gen_expr(ctx, expr));
		},
	};
	return vvoid;
};
