// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::types;
use hare::types::{builtin};
use hare::unit;
use hare::unit::{object_kind};
use io;
use memio;
use os;
use strings;

fn gen(out: io::handle, store: *types::typestore, unit: *unit::unit) void = {
	// TODO: context_init
	let ctx = context {
		out = out,
		buf = memio::dynamic(),
		store = store,
		unit = unit,
		arch = struct {
			// TODO: Initialize these properly
			ptr: *qtype = &qlong,
			sz: *qtype = &qlong,
		},
		...
	};
	defer io::close(&ctx.buf)!;
	for (let i = 0z; i < len(unit.decls); i += 1) {
		match (unit.decls[i].decl) {
		case let func: unit::decl_func =>
			gen_func(&ctx, &unit.decls[i]);
		case => abort(); // TODO
		};
	};
};

fn gen_func(ctx: *context, decl: *unit::decl) void = {
	// TODO: const fndecl = &decl.decl as *unit::decl_func;
	const fndecl = decl.decl as unit::decl_func;
	const body = match (fndecl.body) {
	case let expr: *unit::expr =>
		yield expr;
	case null =>
		return; // Prototype
	};
	const fntype = fndecl.prototype.repr as types::func;
	ctx.serial = 0;

	const ident = strings::join("_", fndecl.ident...);
	defer free(ident);
	fmt::fprintf(ctx.out, "{}section \".text.{}\" \"ax\" function",
		if (decl.exported) "export " else "", ident)!;
	const rtype = fntype.result;
	const has_rval =
		match (types::dealias(rtype).repr) {
		case let bi: types::builtin =>
			yield bi != types::builtin::VOID;
		case =>
			yield true;
		};
	if (has_rval) {
		const qrtype = qtype_lookup(ctx, rtype, false);
		fmt::fprintf(ctx.out, " {}", qtype_repr(qrtype))!;
	};
	fmt::fprintf(ctx.out, " ${}(", ident)!;
	assert(len(fntype.params) == 0); // TODO
	fmt::fprintln(ctx.out, ") {")!;
	fmt::fprintln(ctx.out, mklabel(ctx, "start"))!;

	// We use a dynamic buffer here so that we can emit alloc instructions
	// on-demand at the start of the function, rather than spread out
	// through the body. This is more reliable on qbe's ARM backend, and
	// generates better IL besides.
	memio::reset(&ctx.buf);

	fmt::fprintln(&ctx.buf, mklabel(ctx, "body"))!;

	const rval = gen_expr(ctx, body);
	if (!body.terminates) {
		if (has_rval) {
			emit(&ctx.buf, void, qinstr::RET, rval);
		} else {
			emit(&ctx.buf, void, qinstr::RET);
		};
	};

	io::writeall(ctx.out, memio::buffer(&ctx.buf))!;
	fmt::fprintln(ctx.out, "}\n")!;
};

fn gen_store(ctx: *context, object: value, value: value) void = {
	match (types::dealias(object._type).repr) {
	case let bi: types::builtin =>
		switch (bi) {
		case builtin::STR => abort(); // TODO
		case => void;
		};
	case types::_struct => abort(); // TODO
	case (types::array | types::slice | types::tagged | types::tuple) =>
		abort(); // TODO
	case => void; // Handled below
	};
	const instr = qinstr_store(ctx, object._type);
	emit(&ctx.buf, void, instr, value, object);
};

fn gen_load(ctx: *context, object: value) value = {
	match (types::dealias(object._type).repr) {
	case let bi: types::builtin =>
		switch (bi) {
		case builtin::STR => abort(); // TODO
		case => void;
		};
	case types::_struct => abort(); // TODO
	case (types::array | types::slice | types::tagged | types::tuple) =>
		abort(); // TODO
	case => void; // Handled below
	};
	const instr = qinstr_load(ctx, object._type);
	const temp = mktemp(ctx);
	const ty = qtype_lookup(ctx, object._type, false);
	emit(&ctx.buf, (ty, temp), instr, object);
	return value {
		value = temp,
		_type = object._type,
	};
};

fn gen_expr(ctx: *context, expr: *unit::expr) value = {
	match (expr.expr) {
	case unit::access =>
		return gen_access(ctx, expr);
	case unit::bindings =>
		return gen_binding(ctx, expr);
	case unit::compound =>
		return gen_compound(ctx, expr);
	case unit::constant =>
		return gen_const(ctx, expr);
	case unit::_return =>
		return gen_return(ctx, expr);
	};
};

fn gen_expr_at(ctx: *context, expr: *unit::expr, at: value) void = {
	match (expr.expr) {
	case => void; // TODO: Some functions will prefer _at
	};
	const value = gen_expr(ctx, expr);
	gen_store(ctx, at, value);
};

fn gen_access_object(ctx: *context, object: *unit::object) value = {
	switch (object.kind) {
	case object_kind::CONST, object_kind::TYPE => abort();
	case object_kind::BIND =>
		const binding = binding_lookup(ctx, object);
		return value {
			value = binding.name,
			_type = object._type,
		};
	case object_kind::DECL => abort(); // TODO
	};
};

fn gen_access_addr(ctx: *context, expr: *unit::expr) value = {
	match (expr.expr as unit::access) {
	case let ao: unit::access_object =>
		return gen_access_object(ctx, ao);
	case let ai: unit::access_index => abort(); // TODO
	case let af: unit::access_field => abort(); // TODO
	case let at: unit::access_tuple => abort(); // TODO
	};
};

fn gen_access(ctx: *context, expr: *unit::expr) value = {
	const addr = gen_access_addr(ctx, expr);
	return gen_load(ctx, addr);
};

fn gen_binding(ctx: *context, expr: *unit::expr) value = {
	const bindings = expr.expr as unit::bindings;
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
		const instr = qinstr_alloc(value._type);
		const lval = mklval(ctx, value);
		emit(&ctx.buf, lval, instr, value._type.sz);
		gen_expr_at(ctx, item.init, value);
	};
	return vvoid;
};

fn gen_compound(ctx: *context, expr: *unit::expr) value = {
	const compound = expr.expr as unit::compound;
	for (let i = 0z; i < len(compound); i += 1) {
		gen_expr(ctx, compound[i]);
	};
	return vvoid; // TODO
};

fn gen_const(ctx: *context, expr: *unit::expr) value = {
	const constexpr = expr.expr as unit::constant;
	const val: qval = match (constexpr) {
	case void =>
		return vvoid;
	case let b: bool =>
		yield (if (b) 1u32 else 0u32): constant;
	case ast::_null =>
		yield 0u64; // XXX: Arch
	case let r: rune =>
		yield r: u32;
	case let v: (u64 | f64) =>
		yield v;
	case let i: i64 =>
		yield i: u64;
	case let s: str => abort(); // TODO
	// TODO: Aggregate types
	};
	return value {
		value = val,
		_type = expr.result,
	};
};

fn gen_return(ctx: *context, expr: *unit::expr) value = {
	const rexpr = expr.expr as unit::_return;
	match (rexpr) {
	case null =>
		emit(&ctx.buf, void, qinstr::RET);
	case let expr: *unit::expr =>
		emit(&ctx.buf, void, qinstr::RET, gen_expr(ctx, expr));
	};
	return vvoid;
};
