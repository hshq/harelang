use hare::ast;
use hare::lex;
use hare::lex::{btoken};

// Parses a compound-expression
export fn compound_expression(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Expected EOF, expected compound expression"),
		t: (lex::token, lex::location) => t,
	};

	lex::unlex(lexer, tok);
	let tok = match (tok.0) {
		tok: btoken => tok,
		* => return complex_expression(lexer),
	};

	return switch (tok) {
		btoken::LBRACE => expression_list(lexer),
		btoken::BREAK, btoken::CONTINUE, btoken::RETURN =>
			control_statement(lexer),
		* => complex_expression(lexer),
	};
};

// Parses a simple-expression
export fn simple_expression(lexer: *lex::lexer) (ast::expr | error) = {
	want_btoken(lexer, btoken::VOID)?; // TODO
	return void;
};

// Parses a complex-expression
export fn complex_expression(lexer: *lex::lexer) (ast::expr | error) = {
	return simple_expression(lexer); // TODO
};

fn expression_list(lexer: *lex::lexer) (ast::expr | error) = {
	let items: ast::list_expr = [];

	for (let more = true; more) {
		let tok = match (lex::lex(lexer)?) {
			io::EOF => return syntaxerr(mkloc(lexer),
				"Unexpected EOF, expected scope or control expression"),
			t: (lex::token, lex::location) => t,
		};
		lex::unlex(lexer, tok);
		let item = match (tok.0) {
			tok: btoken => switch (tok) {
				btoken::RBRACE => break,
				btoken::BREAK,
				btoken::CONTINUE,
				btoken::RETURN => {
					more = false;
					control_statement(lexer)?;
				},
				* => scope_expression(lexer)?,
			},
			* => scope_expression(lexer)?,
		};
		append(items, alloc(item));
		want_btoken(lexer, btoken::SEMICOLON)?;
	};

	want_btoken(lexer, btoken::RBRACE)?;
	return items;
};

fn scope_expression(lexer: *lex::lexer) (ast::expr | error) = {
	return simple_expression(lexer); // TODO
};

fn control_statement(lexer: *lex::lexer) (ast::expr | error) = {
	abort(); // TODO
};
