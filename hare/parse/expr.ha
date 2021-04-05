use hare::ast;
use hare::lex;
use hare::lex::{btoken};

fn binarithm(
	lexer: *lex::lexer,
	lvalue: (ast::expr | void),
	i: int,
) (ast::expr | error) = {
	// Precedence climbing parser
	// https://en.wikipedia.org/wiki/Operator-precedence_parser
	let lvalue = match (lvalue) {
		void => cast(lexer, void)?,
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

		let rvalue = cast(lexer, void)?;
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

fn cast(lexer: *lex::lexer, lvalue: (ast::expr | void)) (ast::expr | error) = {
	let lvalue = match (lvalue) {
		void => unarithm(lexer)?,
		e: ast::expr => e,
	};
	const tok = match (try_btoken(lexer, btoken::COLON,
			btoken::AS, btoken::IS)?) {
		void => return lvalue,
		tok: btoken => tok,
	};
	const kind = switch (tok) {
		btoken::COLON	=> ast::cast_kind::CAST,
		btoken::AS	=> ast::cast_kind::ASSERTION,
		btoken::IS	=> ast::cast_kind::TEST,
		* => abort(),
	};
	return cast(lexer, ast::cast_expr {
		kind = kind,
		value = alloc(lvalue),
		_type = alloc(_type(lexer)?),
	});
};

fn objsel(lexer: *lex::lexer) (ast::expr | error) = {
	abort(); // TODO
};

fn postfix(lexer: *lex::lexer) (ast::expr | error) = {
	want_btoken(lexer, btoken::VOID)?; // TODO
	return void;
};

fn unarithm(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (try_btoken(lexer,
			btoken::PLUS, btoken::MINUS, btoken::BNOT,
			btoken::LNOT, btoken::TIMES, btoken::BAND)) {
		void => return postfix(lexer),
		tok: btoken => tok,
	};
	const op = switch (tok) {
		btoken::PLUS	=> ast::unarithm_op::PLUS,
		btoken::MINUS	=> ast::unarithm_op::MINUS,
		btoken::BNOT	=> ast::unarithm_op::BNOT,
		btoken::LNOT	=> ast::unarithm_op::LNOT,
		btoken::TIMES	=> ast::unarithm_op::DEREF,
		btoken::BAND	=> ast::unarithm_op::ADDR,
		* => abort(),
	};
	let operand =
		if (tok == btoken::BAND) objsel(lexer)?
		else unarithm(lexer)?;
	return ast::unarithm_expr {
		op = op,
		operand = alloc(operand),
	};
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

fn scope_expression(lexer: *lex::lexer) (ast::expr | error) = {
	return simple_expression(lexer); // TODO
};

fn control_statement(lexer: *lex::lexer) (ast::expr | error) = {
	abort(); // TODO
};
