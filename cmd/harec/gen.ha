use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::types;
use hare::unit;
use io;
use os;

type context = struct {
	out: *io::stream,
	store: *types::typestore,
	unit: *unit::unit,
	serial: uint,
};

fn gen(store: *types::typestore, unit: *unit::unit) void = {
	let ctx = context {
		out = bufio::dynamic(io::mode::WRITE),
		store = store,
		unit = unit,
		serial = 0,
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
	if (fndecl.body == null) {
		return; // Prototype
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
	gen_expr(ctx, fndecl.body: *unit::expr);
	emit(ctx, void, qinstr::RET); // TODO

	io::write(os::stdout, bufio::buffer(ctx.out))!;
	fmt::println("}\n")!;
};

fn gen_expr(ctx: *context, expr: *unit::expr) value = {
	match (expr.expr) {
		unit::constant_expr => return gen_expr_const(ctx, expr),
		* => abort(), // TODO
	};
};

fn gen_expr_const(ctx: *context, expr: *unit::expr) value = {
	const constexpr = expr.expr as unit::constant_expr;
	const val: qval = match (constexpr) {
		void => return vvoid,
		b: bool => (if (b) 1u32 else 0u32): constant,
		ast::_null => 0u64, // XXX: Arch
		v: ast::value => abort(), // TODO
	};
	return value {
		value = val,
		_type = expr.result,
	};
};
