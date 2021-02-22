use bufio;
use hare::ast;
use hare::lex;
use strings;
use fmt;

@test fn ident() void = {
	{
		const in = "foo";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_finish(&ident);
		assert(ident.name == "foo");
		assert(ident.ns == null);
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::ident => {
				assert(ns.name == "bar");
				assert(ns.ns == null);
			},
		};
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar::baz";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::ident => {
				assert(ns.name == "bar");
				match (ns.ns) {
					null => abort(),
					ns: *ast::ident => {
						assert(ns.name == "baz");
						assert(ns.ns == null);
					},
				};
			},
		};
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar;";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::ident => {
				assert(ns.name == "bar");
				assert(ns.ns == null);
			},
		};
		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == hare::lex::btoken::SEMICOLON);
	};
};

@test fn imports() void = {
	{
		const in = "use foo;";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;
		assert(len(mods) == 1);
		assert(mods[0] is ast::import_module);
		let mod = mods[0] as ast::import_module;
		assert(mod.name == "foo");
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in =
			"use foo;\n"
			"use bar;\n"
			"use baz::bat;\n\n"
			"export fn main() void = void;";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let mods = imports(&lexer) as []ast::import;

		assert(len(mods) == 3);
		let expected = ["foo", "bar", "baz"];

		for (let i = 0z; i < len(mods); i += 1) {
			assert(mods[i] is ast::import_module);
			let mod = mods[i] as ast::import_module;
			assert(mod.name == expected[i]);
		};

		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == hare::lex::btoken::EXPORT);
	};
};
