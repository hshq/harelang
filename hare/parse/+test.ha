use bufio;
use hare::ast;
use hare::lex;
use strings;

@test fn identifier() void = {
	{
		const in = "foo";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = identifier(&lexer) as ast::identifier;
		defer ast::identifier_finish(&ident);
		assert(ident.name == "foo");
		assert(ident.ns == null);
		assert(lex::lex(&lexer) is io::EOF);
	};

	{
		const in = "foo::bar";
		let buf = bufio::fixed(strings::to_utf8(in));
		let lexer = lex::lexer_init(buf, "<test>");
		let ident = identifier(&lexer) as ast::identifier;
		defer ast::identifier_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::identifier => {
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
		let ident = identifier(&lexer) as ast::identifier;
		defer ast::identifier_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::identifier => {
				assert(ns.name == "bar");
				match (ns.ns) {
					null => abort(),
					ns: *ast::identifier => {
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
		let ident = identifier(&lexer) as ast::identifier;
		defer ast::identifier_finish(&ident);
		assert(ident.name == "foo");
		match (ident.ns) {
			null => abort(),
			ns: *ast::identifier => {
				assert(ns.name == "bar");
				assert(ns.ns == null);
			},
		};
		let tok = lex::lex(&lexer) as (lex::token, lex::location);
		assert(tok.0 as lex::btoken == hare::lex::btoken::SEMICOLON);
	};
};
