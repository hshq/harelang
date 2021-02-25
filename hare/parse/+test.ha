use bufio;
use fmt;
use hare::ast;
use hare::lex;
use io::{mode};
use strings;

@test fn ident() void = {
	{
		const in = "foo";
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 1);
		assert(ident[0] == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar";
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "bar" && ident[1] == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar::baz";
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 3);
		assert(ident[0] == "baz" && ident[1] == "bar"
			&& ident[2] == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar;";
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "bar" && ident[1] == "foo");
		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == lex::btoken::SEMICOLON);
	};
};

@test fn imports() void = {
	{
		const in = "use foo;";
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
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
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_][]str = [["foo"], ["bar"], ["bat", "baz"]];

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
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_](str, []str) = [
			("foo", ["bar"]),
			("baz", ["bat"]),
			("qux", ["corge", "quux"])
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
		let buf = bufio::fixed(strings::to_utf8(in), mode::READ);
		let lexer = lex::lexer_init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		defer for (let i = 0z; i < len(mods); i += 1) {
			ast::import_free(mods[i]);
		};

		assert(len(mods) == 3);
		let expected: [_]([]str, []str) = [
			(["foo"], ["bar"]),
			(["baz"], ["bat", "qux"]),
			(["corge", "quux"], ["grault", "garply"])
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
