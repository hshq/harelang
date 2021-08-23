use bufio;
use encoding::utf8;
use fmt;
use hare::ast;
use hare::lex;
use io;
use io::{mode};
use strings;

fn expr_testloc(srcs: str...) void = for (let i = 0z; i < len(srcs); i += 1) {
	let buf = bufio::fixed(strings::toutf8(srcs[i]), mode::READ);
	defer io::close(buf);
	let lexer = lex::init(buf, "<test>");
	let exp = match (expression(&lexer)) {
		exp: ast::expr => exp,
		err: error => {
			fmt::errorln(strerror(err))!;
			abort();
		},
	};
	defer ast::expr_free(exp);
	let runes = 0z;
	let d = utf8::decode(srcs[i]);
	for (true) match (utf8::next(&d)!) {
		void => break,
		rune => runes += 1,
	};
	assert(exp.start.line == 1 && exp.start.col == 1);
	assert(exp.end.line == 1 && exp.end.col == runes);
};

@test fn expr_loc() void = {
	expr_testloc("foo", "foo[bar]", "foo.bar", "foo.1");
	expr_testloc("alloc(foo)");
	expr_testloc("append(foo, bar)", "append(foo, bar, baz)");
	expr_testloc("assert(foo)", "assert(foo, \"bar\")", "abort()",
		"abort(\"foo\")");
	expr_testloc("foo = bar");
	expr_testloc("foo * bar");
	expr_testloc("let foo: bar = baz", "let foo: bar = baz, quux = quuux",
		"const foo: bar = baz", "const foo: bar = baz, quux = quuux");
	expr_testloc("break", "break :foo");
	expr_testloc("foo(bar)");
	expr_testloc("foo: bar");
	expr_testloc("[foo, bar]", "[foo, bar...]");
	expr_testloc("foo { bar = baz, ... }", "struct { foo: bar = baz, }");
	expr_testloc("(foo, bar)");
	expr_testloc("null", "void", "true", "\"שלום\"");
	expr_testloc("continue :foo");
	expr_testloc("defer foo");
	expr_testloc("delete(foo[bar])", "delete(foo[bar..baz])");
	expr_testloc("for (let foo = 0; bar; baz) quux",
		"for (let bar = 0; baz; quux) quuux");
	expr_testloc("free(foo)");
	expr_testloc("if (foo) bar", "if (foo) bar else baz");
	expr_testloc("len(foo)");
	expr_testloc("{ foo; bar; }");
	expr_testloc("match (foo) { * => bar }");
	expr_testloc("foo?");
	expr_testloc("return foo");
	expr_testloc("size(int)");
	expr_testloc("switch (foo) { * => bar }");
	expr_testloc("foo[bar..baz]");
	expr_testloc("&foo");

	// We want to check the location of nested expressions, so this can't
	// use expr_testloc
	let buf = bufio::fixed(strings::toutf8("foo: bar: baz"), mode::READ);
	defer io::close(buf);
	let lexer = lex::init(buf, "<test>");
	let exp = match (expression(&lexer)) {
		exp: ast::expr => exp,
		err: error => {
			fmt::errorln(strerror(err))!;
			abort();
		},
	};
	defer ast::expr_free(exp);
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
	let buf = bufio::fixed(strings::toutf8(srcs[i]), mode::READ);
	defer io::close(buf);
	let lexer = lex::init(buf, "<test>");
	let typ = match (_type(&lexer)) {
		typ: ast::_type => typ,
		err: error => {
			fmt::errorln(strerror(err))!;
			abort();
		},
	};
	defer ast::type_free(typ);
	let runes = 0z;
	let d = utf8::decode(srcs[i]);
	for (true) match (utf8::next(&d)!) {
		void => break,
		rune => runes += 1,
	};
	assert(typ.start.line == 1 && typ.start.col == 1);
	assert(typ.end.line == 1 && typ.end.col == runes);
};

@test fn type_loc() void = {
	type_testloc("foo", "...foo");
	type_testloc("int");
	type_testloc("enum { FOO = bar }");
	type_testloc("fn(foo: bar) baz", "@noreturn fn(foo: bar) baz");
	type_testloc("[foo]bar", "[*]foo", "[]foo", "[_]int");
	type_testloc("*foo", "nullable *int");
	type_testloc("struct { foo: bar }");
	type_testloc("union { foo: bar }");
	type_testloc("(foo | bar)");
	type_testloc("(foo, bar)");
};
