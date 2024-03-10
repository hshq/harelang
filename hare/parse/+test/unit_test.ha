// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use hare::ast;
use hare::lex;
use io::{mode};
use memio;
use strings;
use types;

fn import_eq(i1: ast::import, i2: ast::import) bool = {
	if (!ast::ident_eq(i1.ident, i2.ident)) {
		return false;
	};

	let (o1, o2) = match (i1.bindings) {
	case void =>
		return i2.bindings is void;
	case let s1: ast::import_alias =>
		match (i2.bindings) {
		case let s2: ast::import_alias =>
			return s1 == s2;
		case =>
			return false;
		};
	case let o1: ast::import_members =>
		yield match (i2.bindings) {
		case let o2: ast::import_members =>
			if (len(o1) != len(o2)) {
				return false;
			};
			yield (o1, o2);
		case =>
			return false;
		};
	case ast::import_wildcard =>
		return i2.bindings is ast::import_wildcard;
	};
	for (let i = 0z; i < len(o1); i += 1) {
		if (o1[i] != o2[i]) {
			return false;
		};
	};
	return true;
};

type import_tuple = (ast::ident, (void | ast::import_alias |
	ast::import_members | ast::import_wildcard));

fn tup_to_import(tup: import_tuple) ast::import = ast::import {
	ident = tup.0,
	bindings = tup.1,
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

		"export fn main() void = void;";
	let buf = memio::fixed(strings::toutf8(in));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");
	let mods = imports(&lexer)!;
	defer ast::imports_finish(mods);

	let expected: [_]import_tuple = [
		(["foo"], void),
		(["bar"], void),
		(["baz", "bat"], void),
		(["bar"], "foo"),
		(["bat"], "baz"),
		(["quux", "corge"], "qux"),
		(["foo"], ast::import_wildcard),
		(["foo", "bar", "quux"], ast::import_wildcard),
		(["foo"], ["bar"]),
		(["foo"], ["bar"]),
		(["baz"], ["bat", "qux"]),
		(["quux", "corge"], ["grault", "garply"]),
	];

	assert(len(mods) == len(expected));
	for (let i = 0z; i < len(mods); i += 1) {
		assert(import_eq(mods[i], tup_to_import(expected[i])));
	};

	let tok = lex::lex(&lexer) as lex::token;
	assert(tok.0 == lex::ltok::EXPORT);
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
		") nullable *const void;\n\n"
		"static abort();\n\n"
		"static assert(true);\n");
};

@test fn docs() void = {
	roundtrip("// According to all known laws of aviation, there is no\n"
		"// way that a bee should be able to fly. Its wings are too\n"
		"// small to get its fat little body off the ground. The bee,\n"
		"// of course, flies anyway, because bees don't care what\n"
		"// humans think is impossible.\n"
		"export fn main() void = void;\n");
};
