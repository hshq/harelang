// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use hare::ast;
use hare::lex;
use io;
use io::{mode};
use memio;
use strings;

fn expr_testloc(srcs: str...) void = for (let i = 0z; i < len(srcs); i += 1) {
	let buf = memio::fixed(strings::toutf8(srcs[i]));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");
	let exp = match (expr(&lexer)) {
	case let exp: ast::expr =>
		yield exp;
	case let err: error =>
		fmt::errorfln("{}: {}", srcs[i], strerror(err))!;
		abort();
	};
	defer ast::expr_finish(&exp);
	let runes = 0z;
	let it = strings::iter(srcs[i]);
	for (strings::next(&it) is rune) {
		runes += 1;
	};
	assert(exp.start.line == 1 && exp.start.col == 1);
	assert(exp.end.line == 1 && exp.end.col == runes);
};

@test fn expr_loc() void = {
	expr_testloc("foo", "foo[bar]", "foo.bar", "foo.1");
	expr_testloc("alloc(foo)");
	expr_testloc("append(foo, bar)", "append(foo, bar, baz)");
	expr_testloc("assert(foo)", `assert(foo, "bar")`, "abort()",
		`abort("foo")`);
	expr_testloc("foo is bar", "foo as bar");
	expr_testloc("foo = bar");
	expr_testloc("foo * bar", "foo && bar");
	expr_testloc("break", "break :foo");
	expr_testloc("foo(bar)");
	expr_testloc("foo: bar");
	expr_testloc("[foo, bar]", "[foo, bar...]");
	expr_testloc("foo { bar = baz, ... }", "struct { foo: bar = baz, }");
	expr_testloc("(foo, bar)");
	expr_testloc("null", "void", "true", `"שלום"`, "'a'");
	expr_testloc("[foo, bar]");
	expr_testloc("123", "-123.456", "123z", "123e+3");
	expr_testloc("continue", "continue :foo");
	expr_testloc("delete(foo[bar])", "delete(foo[bar..baz])");
	expr_testloc("for (let foo = 0; bar; baz) quux",
		"for (let bar = 0; baz; quux) quuux");
	expr_testloc("free(foo)");
	expr_testloc("if (foo) bar", "if (foo) bar else baz");
	expr_testloc("insert(foo[0], bar)", "insert(foo[0], bar, baz)");
	expr_testloc("len(foo)");
	expr_testloc("{ foo; bar; }", "{ defer foo; }",
		"{ let foo: bar = baz; }", "{ let foo: bar = baz, quux = quuux; }",
		"{ const foo: bar = baz; }", "{ const foo: bar = baz, quux = quuux; }");
	expr_testloc("match (foo) { case => bar; }");
	expr_testloc("offset(foo)");
	expr_testloc("foo?", "foo!");
	expr_testloc("return", "return foo");
	expr_testloc("size(int)");
	expr_testloc("switch (foo) { case => bar; }");
	expr_testloc("foo[bar..baz]");
	expr_testloc("&foo");
	expr_testloc("vastart()", "vaarg(ap)", "vaend(ap)");
	expr_testloc("yield", "yield foo", "yield :foo, bar");

	// We want to check the location of nested expressions, so this can't
	// use expr_testloc
	let buf = memio::fixed(strings::toutf8("foo: bar: baz"));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");
	let exp = match (expr(&lexer)) {
	case let exp: ast::expr =>
		yield exp;
	case let err: error =>
		fmt::errorln(strerror(err))!;
		abort();
	};
	defer ast::expr_finish(&exp);
	assert(exp.start.line == 1 && exp.start.col == 1);
	assert(exp.end.line == 1 && exp.end.col == 13);
	let c = exp.expr as ast::cast_expr;
	exp = *c.value;
	assert(exp.start.line == 1 && exp.start.col == 1);
	assert(exp.end.line == 1 && exp.end.col == 8);
	c = exp.expr as ast::cast_expr;
	exp = *c.value;
	assert(exp.start.line == 1 && exp.start.col == 1);
	assert(exp.end.line == 1 && exp.end.col == 3);
};

fn type_testloc(srcs: str...) void = for (let i = 0z; i < len(srcs); i += 1) {
	let buf = memio::fixed(strings::toutf8(srcs[i]));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");
	let typ = match (_type(&lexer)) {
	case let typ: ast::_type =>
		yield typ;
	case let err: error =>
		fmt::errorln(strerror(err))!;
		abort();
	};
	defer ast::type_finish(&typ);
	let runes = 0z;
	let it = strings::iter(srcs[i]);
	for (strings::next(&it) is rune) {
		runes += 1;
	};
	assert(typ.start.line == 1 && typ.start.col == 1);
	assert(typ.end.line == 1 && typ.end.col == runes);
};

@test fn type_loc() void = {
	type_testloc("foo", "...foo");
	type_testloc("int");
	type_testloc("enum { FOO = bar }");
	type_testloc("fn(foo: bar) baz");
	type_testloc("[foo]bar", "[*]foo", "[]foo", "[_]int");
	type_testloc("*foo", "nullable *int");
	type_testloc("struct { foo: bar }");
	type_testloc("union { foo: bar }");
	type_testloc("(foo | bar)");
	type_testloc("(foo, bar)");
};
