// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use io;
use memio;
use strings;

fn parse_expr(src: str) *ast::expr = {
	let stream = memio::fixed(strings::toutf8(src));
	let sc = bufio::newscanner(&stream);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");
	return alloc(parse::expr(&lexer)!);
};

fn mktestctx() context = context {
	store = types::store(types::x86_64, null, null),
	scope = alloc(scope { ... }),
	...
};

fn freetestctx(ctx: *context) void = {
	// TODO: Some of this should be in -test
	types::store_free(ctx.store);
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
		...
	});
	const aexpr = parse_expr("hello");
	defer ast::expr_finish(aexpr);
	const expr = process_access(&ctx, aexpr)!;
	const access = expr.expr as access;
	const ao = access as access_object;
	assert(ao == object);
	assert(expr.result == &types::builtin_u32);
};

@test fn compound() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("{ void; void; void; }");
	defer ast::expr_finish(aexpr);
	const expr = process_compound(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const compound = expr.expr as compound;
	assert(len(compound) == 3);

	const aexpr = parse_expr("{ return; }");
	defer ast::expr_finish(aexpr);
	const expr = process_compound(&ctx, aexpr)!;
	assert(expr.terminates);

	// TODO: test yields
};

@test fn constant() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("void");
	defer ast::expr_finish(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::VOID);
	const constexpr = expr.expr as constant;
	assert(constexpr is void);

	const aexpr = parse_expr("true");
	defer ast::expr_finish(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant;
	assert(constexpr as bool == true);

	const aexpr = parse_expr("false");
	defer ast::expr_finish(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::BOOL);
	const constexpr = expr.expr as constant;
	assert(constexpr as bool == false);

	const aexpr = parse_expr("null");
	defer ast::expr_finish(aexpr);
	const expr = process_constant(&ctx, aexpr)!;
	assert(expr.result.repr as types::builtin == types::builtin::NULL);
	assert(expr.expr is constant);

	const cases: [_](str, types::builtin, constant) = [
		("1234", types::builtin::INT, 1234),
		("1234u", types::builtin::UINT, 1234u),
		("\"hello world\"", types::builtin::STR, "hello world"),
		("'!'", types::builtin::RUNE, '!'),
		("13.37", types::builtin::F64, 13.37f64),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const _case = cases[i];
		const aexpr = parse_expr(_case.0);
		defer ast::expr_finish(aexpr);
		const expr = process_constant(&ctx, aexpr)!;
		assert(expr.result.repr as types::builtin == _case.1);
		const constexpr = expr.expr as constant;
		match (_case.2) {
		case let s: str =>
			assert(constexpr as str == s);
		case let r: rune =>
			assert(constexpr as rune == r);
		case let i: i64 =>
			assert(constexpr as i64 == i);
		case let u: u64 =>
			assert(constexpr as u64 == u);
		case let f: f64 =>
			assert(constexpr as f64 == f);
		case void =>
			abort();
		};
	};
};

@test fn _return() void = {
	const ctx = mktestctx();
	defer freetestctx(&ctx);
	const aexpr = parse_expr("return;");
	defer ast::expr_finish(aexpr);
	const ret_expr = process_return(&ctx, aexpr)!;
	assert(ret_expr.terminates);
	assert(ret_expr.result.repr as types::builtin == types::builtin::VOID);
	const rval = ret_expr.expr as _return;
	assert(rval == null);

	const aexpr = parse_expr("return 10;");
	defer ast::expr_finish(aexpr);
	const ret_expr = process_return(&ctx, aexpr)!;
	assert(ret_expr.terminates);
	assert(ret_expr.result.repr as types::builtin == types::builtin::VOID);
	const rval = ret_expr.expr as _return;
	assert((rval as *expr).expr is constant);
};
