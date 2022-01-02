use bufio;
use hare::ast;
use hare::lex;
use io;
use io::{mode};
use strings;

@test fn ident() void = {
	{
		const in = "foo";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 1);
		assert(ident[0] == "foo");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in = "foo::bar";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::EOF);
	};

	{
		const in = "foo::bar::baz";
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
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
		let buf = bufio::fixed(strings::toutf8(in), mode::READ);
		let lexer = lex::init(&buf, "<test>");
		let ident = ident(&lexer) as ast::ident;
		defer ast::ident_free(ident);
		assert(len(ident) == 2);
		assert(ident[0] == "foo" && ident[1] == "bar");
		let tok = lex::lex(&lexer) as lex::token;
		assert(tok.0 == lex::ltok::SEMICOLON);
	};
};
