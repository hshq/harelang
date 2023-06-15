// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use hare::ast;
use hare::lex;
use io::{mode};
use memio;
use strings;

fn import_eq(i1: ast::import, i2: ast::import) bool = {
	if (i1.mode != i2.mode) {
		return false;
	};
	if (!ast::ident_eq(i1.ident, i2.ident)) {
		return false;
	};
	let mode = i1.mode;
	if (mode & ast::import_mode::ALIAS != 0 && i1.alias != i2.alias) {
		return false;
	};
	if (mode & ast::import_mode::MEMBERS != 0) {
		for (let i = 0z; i < len(i1.objects); i += 1) {
			let o1 = i1.objects[i], o2 = i2.objects[i];
			if (o1.0 is void ^^ o2.0 is void) {
				return false;
			};
			if (o1.0 is str && o1.0: str != o2.0: str) {
				return false;
			};
			if (o1.1 != o2.1) {
				return false;
			};
		};
	};
	return true;
};

type import_tuple = (ast::import_mode, ast::ident, str, []((str | void), str));

fn tup_to_import(tup: import_tuple) ast::import = ast::import {
	mode = tup.0,
	ident = tup.1,
	alias = tup.2,
	objects = tup.3,
	...
};

@test fn imports() void = {
	const in =
		"use foo;\n"
		"use bar;\n"
		"use baz::bat;\n\n"

		"use foo = bar;\n"
		"use baz = bat;\n"
		"use qux = quux::corge;\n"

		"use foo::*;"
		"use foo::bar::quux::*;"

		"use foo::{bar};\n"
		"use foo::{bar,};\n"
		"use baz::{bat, qux};\n"
		"use quux::corge::{grault, garply,};\n"

		"use quux::{alias = grault};\n"
		"use quux::{alias = grault,};\n"
		"use quux::{alias = grault, garply};\n"
		"use quux::{alias = grault, alias2 = garply};\n"

		"use alias = quux::corge::{grault, garply,};\n"
		"use modalias = quux::{alias = grault, alias2 = garply};\n"

		"export fn main() void = void;";
	let buf = memio::fixed(strings::toutf8(in));
	let lexer = lex::init(&buf, "<test>");
	defer lex::finish(&lexer);
	let mods = imports(&lexer)!;
	defer ast::imports_finish(mods);

	let expected: [_]import_tuple = [
		(ast::import_mode::IDENT, ["foo"], "", []),
		(ast::import_mode::IDENT, ["bar"], "", []),
		(ast::import_mode::IDENT, ["baz", "bat"], "", []),
		(ast::import_mode::ALIAS, ["bar"], "foo", []),
		(ast::import_mode::ALIAS, ["bat"], "baz", []),
		(ast::import_mode::ALIAS, ["quux", "corge"], "qux", []),
		(ast::import_mode::WILDCARD, ["foo"], "", []),
		(ast::import_mode::WILDCARD, ["foo", "bar", "quux"], "", []),
		(ast::import_mode::MEMBERS, ["foo"], "", [(void, "bar")]),
		(ast::import_mode::MEMBERS, ["foo"], "", [(void, "bar")]),
		(ast::import_mode::MEMBERS, ["baz"], "", [(void, "bat"), (void, "qux")]),
		(ast::import_mode::MEMBERS,
			["quux", "corge"], "", [(void, "grault"), (void, "garply")]),
		(ast::import_mode::MEMBERS, ["quux"], "", [("alias", "grault")]),
		(ast::import_mode::MEMBERS, ["quux"], "", [("alias", "grault")]),
		(ast::import_mode::MEMBERS,
			["quux"], "", [("alias", "grault"), (void, "garply")]),
		(ast::import_mode::MEMBERS,
			["quux"], "", [("alias", "grault"), ("alias2", "garply")]),
		(ast::import_mode::MEMBERS | ast::import_mode::ALIAS,
			["quux", "corge"], "alias", [(void, "grault"), (void, "garply")]),
		(ast::import_mode::MEMBERS | ast::import_mode::ALIAS,
			["quux"], "modalias", [("alias", "grault"), ("alias2", "garply")]),
	];

	assert(len(mods) == len(expected));
	for (let i = 0z; i < len(mods); i += 1) {
		assert(import_eq(mods[i], tup_to_import(expected[i])));
	};

	let tok = lex::lex(&lexer) as lex::token;
	assert(tok.0 == lex::ltok::EXPORT);

	const in = "use a::{b = c = d};\n";
	let buf = memio::fixed(strings::toutf8(in));
	let lexer = lex::init(&buf, "<test>");
	defer lex::finish(&lexer);
	assert(imports(&lexer) is error);
};

@test fn decls() void = {
	roundtrip("export type foo::bar = *int, baz = const void;\n\n"
		"type foo = ...bar;\n\n"
		"type foo = nullable *fn(x: rune, int) void;\n\n"
		"export let @symbol(\"_\") foo::bar: int = void, baz: int = void, bat = void;\n\n"
		"def foo::bar: int = void;\n\n"
		"def foo::bar = void;\n\n"
		"@symbol(\".f9$oo\") fn foo(bar: int, baz: int...) void;\n\n"
		"@test fn foo(int, ...) void;\n\n"
		"@test fn foo(...) void;\n\n"
		"fn foo(bar) void;\n\n"
		"fn foo(bar::baz) void;\n\n"
		"export fn main() void = void;\n\n"
		"fn long(\n"
			"\tfirst: *const void,\n"
			"\tsecond: (void | rune | str),\n"
			"\tthird: size...\n"
		") nullable *const void;\n");
};

@test fn docs() void = {
	roundtrip("// According to all known laws of aviation, there is no\n"
		"// way that a bee should be able to fly. Its wings are too\n"
		"// small to get its fat little body off the ground. The bee,\n"
		"// of course, flies anyway, because bees don't care what\n"
		"// humans think is impossible.\n"
		"export fn main() void = void;\n");
};
