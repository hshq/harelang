use bufio;
use fmt;
use hare::ast;
use hare::lex;
use io::{mode};
use io;
use strings;

@test fn imports() void = {
	{
		const in = "use foo;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 1);
		assert(mods[0] is ast::import_module);

		let mod = mods[0] as ast::import_module;
		assert(len(mod) == 1 && mod[0] == "foo");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in =
			"use foo;\n"
			"use bar;\n"
			"use baz::bat;\n\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_][]str = [["foo"], ["bar"], ["baz", "bat"]];

		for (let i = 0z; i < len(mods); i += 1) {
			assert(mods[i] is ast::import_module);
			let mod = mods[i] as ast::import_module;
			assert(len(mod) == len(expected[i]));
			for (let j = 0z; j < len(expected[i]); j += 1z) {
				assert(mod[j] == expected[i][j]);
			};
		};

		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EXPORT);
	};

	{
		const in =
			"use foo = bar;\n"
			"use baz = bat;\n"
			"use qux = quux::corge;\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_](str, []str) = [
			("foo", ["bar"]),
			("baz", ["bat"]),
			("qux", ["quux", "corge"])
		];

		for (let i = 0z; i < len(mods); i += 1) {
			assert(mods[i] is ast::import_alias);
			let mod = mods[i] as ast::import_alias;
			assert(mod.alias == expected[i].0);
			assert(len(mod.ident) == len(expected[i].1));
			for (let j = 0z; j < len(expected[i].1); j += 1z) {
				assert(mod.ident[j] == expected[i].1[j]);
			};
		};
	};

	{
		const in =
			"use foo::{bar};\n"
			"use baz::{bat, qux};\n"
			"use quux::corge::{grault, garply,};\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_]([]str, []str) = [
			(["foo"], ["bar"]),
			(["baz"], ["bat", "qux"]),
			(["quux", "corge"], ["grault", "garply"])
		];

		for (let i = 0z; i < len(mods); i += 1) {
			assert(mods[i] is ast::import_objects);
			let mod = mods[i] as ast::import_objects;
			assert(len(mod.objects) == len(expected[i].1));
			for (let j = 0z; j < len(expected[i].0); j += 1z) {
				assert(mod.objects[j] == expected[i].1[j]);
			};
			assert(len(mod.ident) == len(expected[i].0));
			for (let j = 0z; j < len(expected[i].0); j += 1z) {
				assert(mod.ident[j] == expected[i].0[j]);
			};
		};
	};
};

@test fn decls() void = {
	roundtrip("export type foo::bar = *int, baz = const void;\n"
		"type foo = ...bar;\n"
		"type foo = nullable *fn(x: rune, _: int) void;\n"
		"export let @symbol(\"_\") foo::bar: int = void, baz: int = void;\n"
		"def foo::bar: int = void;\n"
		"@symbol(\".f9$oo\") fn foo(bar: int, baz: int...) void;\n"
		"@test fn foo(_: int, ...) void;\n"
		"export fn main() void = void;\n");
};

@test fn docs() void = {
	roundtrip("// According to all known laws of aviation, there is no\n"
		"// way that a bee should be able to fly. Its wings are too\n"
		"// small to get its fat little body off the ground. The bee,\n"
		"// of course, flies anyway, because bees don't care what\n"
		"// humans think is impossible.\n"
		"export fn main() void = void;\n");
};
