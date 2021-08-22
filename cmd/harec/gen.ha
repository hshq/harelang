use bufio;
use fmt;
use hare::ast;
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
	const fntype = fndecl.prototype._type as types::func;
	assert(fntype.flags == 0);
	ctx.serial = 0;

	const ident = module::identuscore(fndecl.ident);
	defer free(ident);
	fmt::printf("{}function section \".text.{}\" \"ax\"",
		if (decl.exported) "export " else "", ident)!;
	const rtype = fntype.result;
	if (!(rtype._type is types::builtin) ||
			rtype._type as types::builtin != types::builtin::VOID) {
		abort(); // TODO: Return type
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

	io::write(os::stdout, bufio::buffer(ctx.out))!;
	fmt::println("}\n")!;
};

fn gen_expr(ctx: *context, expr: *unit::expr) value = {
	// TODO
	emit(ctx, void, qinstr::RET);

	// TODO:
	// - Make this a constant called valvoid
	// - Implement tagged unions (and their casts) in eval
	// - Add builtin type globals in hare::types like &types::builtin_void
	return value {
		value = qvoid,
		_type = types::lookup_builtin(ctx.store, ast::builtin_type::VOID),
	};
};
