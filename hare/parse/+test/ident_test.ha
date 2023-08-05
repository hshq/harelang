// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use hare::ast;
use hare::lex;
use io;
use io::{mode};
use memio;
use strings;

@test fn ident() void = {
	{
		const in = ";";
		let buf = memio::fixed(strings::toutf8(in));
		let lexer = lex::init(&buf, "<test>");
		defer lex::finish(&lexer);
		ident(&lexer) as error: void;
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::SEMICOLON);
	};

	{
		const in = "foo";
		let buf = memio::fixed(strings::toutf8(in));
		let lexer = lex::init(&buf, "<test>");
		defer lex::finish(&lexer);
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 1);
		assert(ident[0] == "foo");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in = "foo::bar";
		let buf = memio::fixed(strings::toutf8(in));
		let lexer = lex::init(&buf, "<test>");
		defer lex::finish(&lexer);
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in = "foo::bar::baz";
		let buf = memio::fixed(strings::toutf8(in));
		let lexer = lex::init(&buf, "<test>");
		defer lex::finish(&lexer);
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 3);
		assert(ident[0] == "foo" && ident[1] == "bar"
			&& ident[2] == "baz");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in = "foo::bar;";
		let buf = memio::fixed(strings::toutf8(in));
		let lexer = lex::init(&buf, "<test>");
		defer lex::finish(&lexer);
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::SEMICOLON);
	};
};
