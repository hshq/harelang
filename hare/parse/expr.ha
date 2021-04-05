use hare::ast;
use hare::lex;
use hare::lex::{btoken};

fn cast(lexer: *lex::lexer) (ast::expr | error) = {
	want_btoken(lexer, btoken::VOID)?; // TODO
	return void;
};

fn binarithm(
	lexer: *lex::lexer,
	lvalue: (ast::expr | void),
	i: int,
) (ast::expr | error) = {
	// Precedence climbing parser
	// https://en.wikipedia.org/wiki/Operator-precedence_parser
	let lvalue = match (lvalue) {
		void => cast(lexer)?,
		expr: ast::expr => expr,
	};

	let tok = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Unexpected EOF, was expecting simple expression"),
		t: (lex::token, lex::location) => t,
	};

	let j = precedence(tok);
	for (j >= i; j = precedence(tok)) {
		const op = binop_for_tok(tok);

		let rvalue = cast(lexer)?;
		tok = match (lex::lex(lexer)?) {
			io::EOF => return syntaxerr(mkloc(lexer),
				"Unexpected EOF, expecting simple expression"),
			t: (lex::token, lex::location) => t,
		};

		let k = precedence(tok);
		for (k > j; k = precedence(tok)) {
			lex::unlex(lexer, tok);
			rvalue = binarithm(lexer, rvalue, k)?;
			tok = match (lex::lex(lexer)?) {
				io::EOF => return syntaxerr(mkloc(lexer),
					"Unexpected EOF, expecting simple expression"),
				t: (lex::token, lex::location) => t,
			};
		};

		let expr = ast::binarithm_expr {
			op = op,
			lvalue = alloc(lvalue),
			rvalue = alloc(rvalue),
		};
		lvalue = expr;
	};

	lex::unlex(lexer, tok);
	return lvalue;
};

fn binop_for_tok(tok: (lex::token, lex::location)) ast::binarithm_op = {
	let tok = match (tok.0) {
		b: btoken => b,
		* => abort(),
	};
	return switch (tok) {
		btoken::BAND		=> ast::binarithm_op::BAND,
		btoken::BOR		=> ast::binarithm_op::BOR,
		btoken::BXOR		=> ast::binarithm_op::BXOR,
		btoken::DIV		=> ast::binarithm_op::DIV,
		btoken::GREATER		=> ast::binarithm_op::GT,
		btoken::GREATEREQ	=> ast::binarithm_op::GTEQ,
		btoken::LAND		=> ast::binarithm_op::LAND,
		btoken::LEQUAL		=> ast::binarithm_op::LEQUAL,
		btoken::LESS		=> ast::binarithm_op::LESS,
		btoken::LESSEQ		=> ast::binarithm_op::LESSEQ,
		btoken::LOR		=> ast::binarithm_op::LOR,
		btoken::LSHIFT		=> ast::binarithm_op::LSHIFT,
		btoken::LXOR		=> ast::binarithm_op::LXOR,
		btoken::MINUS		=> ast::binarithm_op::MINUS,
		btoken::MODULO		=> ast::binarithm_op::MODULO,
		btoken::NEQUAL		=> ast::binarithm_op::NEQUAL,
		btoken::PLUS		=> ast::binarithm_op::PLUS,
		btoken::RSHIFT		=> ast::binarithm_op::RSHIFT,
		btoken::TIMES		=> ast::binarithm_op::TIMES,
		* => abort(),
	};
};

fn precedence(tok: (lex::token, lex::location)) int = {
	let tok = match (tok.0) {
		b: btoken => b,
		* => return -1,
	};
	return switch (tok) {
		btoken::LOR => 0,
		btoken::LXOR => 1,
		btoken::LAND => 2,
		btoken::LEQUAL,
		btoken::NEQUAL => 3,
		btoken::LESS,
		btoken::LESSEQ,
		btoken::GREATER,
		btoken::GREATEREQ => 4,
		btoken::BOR => 5,
		btoken::BXOR => 6,
		btoken::BAND => 7,
		btoken::LSHIFT,
		btoken::RSHIFT => 8,
		btoken::PLUS,
		btoken::MINUS => 9,
		btoken::TIMES,
		btoken::DIV,
		btoken::MODULO => 10,
		* => -1,
	};
};

// Parses a compound-expression
export fn compound_expression(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = match (lex::lex(lexer)?) {
		io::EOF => return syntaxerr(mkloc(lexer),
			"Unexpected EOF, expected compound expression"),
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
export fn simple_expression(lexer: *lex::lexer) (ast::expr | error) =
	binarithm(lexer, void, 0);

// Parses a complex-expression
export fn complex_expression(lexer: *lex::lexer) (ast::expr | error) = {
	// TODO: if, for, switch, match
	return simple_expression(lexer);
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
