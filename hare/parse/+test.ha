use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use io::{mode};
use strings;
use strio;

@test fn ident() void = {
	{
		const in = "foo";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 1);
		assert(ident[0] == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar::baz";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 3);
		assert(ident[0] == "foo" && ident[1] == "bar"
			&& ident[2] == "baz");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == lex::btoken::SEMICOLON);
	};
};

@test fn imports() void = {
	{
		const in = "use foo;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 1);
		assert(mods[0] is ast::import_module);

		let mod = mods[0] as ast::import_module;
		assert(len(mod) == 1 && mod[0] == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in =
			"use foo;\n"
			"use bar;\n"
			"use baz::bat;\n\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
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

		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == lex::btoken::EXPORT);
	};

	{
		const in =
			"use foo = bar;\n"
			"use baz = bat;\n"
			"use qux = quux::corge;\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(buf, "<test>");
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
		let lexer = lex::init(buf, "<test>");
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

fn roundtrip(src: str) void = {
	let buf = bufio::fixed(strings::toutf8(src), mode::READ);
	let lexer = lex::init(buf, "<test>");
	let u = ast::subunit {
		imports = [],
		decls = decls(&lexer) as []ast::decl,
	};
	defer ast::subunit_free(u);
	let out = strio::dynamic();
	unparse::subunit(out, u) as size;
	let unsrc = strio::finish(out);
	defer free(unsrc);
	assert(unsrc == src);
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

@test fn binarithm() void = {
	roundtrip("export fn main() void = void + void * void / void;\n");
};

@test fn cast() void = {
	roundtrip("export fn main() void = void: int;\n"
		"export fn main() void = void as int;\n"
		"export fn main() void = void is int;\n"
		"export fn main() void = void: int: uint: u16: u8;\n"
		"export fn main() void = void: int as uint: u16 is u8;\n");
};
