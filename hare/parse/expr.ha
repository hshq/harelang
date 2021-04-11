use hare::ast;
use hare::lex::{ltok};
use hare::lex;

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

	let tok = lex::lex(lexer)?;
	let j = precedence(tok);
	for (j >= i; j = precedence(tok)) {
		const op = binop_for_tok(tok);

		let rvalue = cast(lexer, void)?;
		tok = lex::lex(lexer)?;

		let k = precedence(tok);
		for (k > j; k = precedence(tok)) {
			lex::unlex(lexer, tok);
			rvalue = binarithm(lexer, rvalue, k)?;
			tok = lex::lex(lexer)?;
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
	const tok = match (try(lexer, ltok::COLON,
			ltok::AS, ltok::IS)?) {
		void => return lvalue,
		tok: lex::token => tok.0,
	};
	const kind = switch (tok) {
		ltok::COLON	=> ast::cast_kind::CAST,
		ltok::AS	=> ast::cast_kind::ASSERTION,
		ltok::IS	=> ast::cast_kind::TEST,
		* => abort(),
	};
	return cast(lexer, ast::cast_expr {
		kind = kind,
		value = alloc(lvalue),
		_type = alloc(_type(lexer)?),
	});
};

fn constant(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::VOID)?;
	return void;
};

fn control_statement(lexer: *lex::lexer) (ast::expr | error) = {
	abort(); // TODO
};

fn objsel(lexer: *lex::lexer) (ast::expr | error) = {
	abort(); // TODO
};

fn plain_expression(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = peek(lexer)? as lex::token;
	return switch (tok.0) {
		ltok::TRUE,
		ltok::FALSE,
		ltok::NULL,
		ltok::VOID => constant(lexer),
		ltok::LBRACKET => abort(), // TODO: Array literal
		ltok::STRUCT => abort(), // TODO: Struct literal
		ltok::LPAREN => {
			let ex = expression(lexer);
			return switch (want(lexer,
					ltok::RPAREN, ltok::COMMA)?.0) {
				ltok::RPAREN => ex,
				ltok::COMMA => abort(), // TODO: Tuple literal
				* => abort(),
			};
		},
		ltok::LITERAL => return constant(lexer),
		ltok::NAME => {
			let id = ident(lexer)?;
			return match (try(lexer, ltok::LBRACE)?) {
				void => id: ast::access_identifier,
				lex::token => abort(), // TODO: Struct literal
			};
		},
		* => syntaxerr(mkloc(lexer),
			"Unexpected {}, was expecting an expression",
			lex::tokstr(tok)),
	};
};

fn postfix(lexer: *lex::lexer, lvalue: (ast::expr | void)) (ast::expr | error) = {
	// Built-ins (XXX: these should probably be moved in the Hare grammar)
	match (peek(lexer,
			ltok::ALLOC, ltok::APPEND, ltok::FREE,
			ltok::DELETE, ltok::ABORT, ltok::ASSERT,
			ltok::STATIC, ltok::SIZE, ltok::LEN,
			ltok::OFFSET)?) {
		tok: lex::token => {
			if (lvalue is ast::expr) {
				return syntaxerr(mkloc(lexer),
					"Unexpected {}, was expecting '(', '.', or '['",
					lex::tokstr(tok));
			};
			abort(); // TODO: Delegate as appropriate
		},
		void => void,
	};

	let lvalue = match (lvalue) {
		void => plain_expression(lexer)?,
		ex: ast::expr => ex,
	};

	match (try(lexer, ltok::LPAREN, ltok::DOT, ltok::LBRACKET,
			ltok::QUESTION)) {
		tok: lex::token => switch (tok.0) {
			ltok::LPAREN => abort(), // TODO: Calls
			ltok::DOT => abort(), // TODO: Field access
			ltok::LBRACKET => abort(), // TODO: Indexing
			ltok::QUESTION => abort(), // TODO: Propagation
			* => abort(),
		},
		void => return lvalue,
	};

	return postfix(lexer, lvalue);
};

fn unarithm(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (try(lexer,
			ltok::PLUS, ltok::MINUS, ltok::BNOT,
			ltok::LNOT, ltok::TIMES, ltok::BAND)) {
		void => return postfix(lexer, void),
		tok: lex::token => tok.0,
	};
	const op = switch (tok) {
		ltok::PLUS	=> ast::unarithm_op::PLUS,
		ltok::MINUS	=> ast::unarithm_op::MINUS,
		ltok::BNOT	=> ast::unarithm_op::BNOT,
		ltok::LNOT	=> ast::unarithm_op::LNOT,
		ltok::TIMES	=> ast::unarithm_op::DEREF,
		ltok::BAND	=> ast::unarithm_op::ADDR,
		* => abort(),
	};
	let operand =
		if (tok == ltok::BAND) objsel(lexer)?
		else unarithm(lexer)?;
	return ast::unarithm_expr {
		op = op,
		operand = alloc(operand),
	};
};

fn binop_for_tok(tok: lex::token) ast::binarithm_op = switch (tok.0) {
	ltok::BAND	=> ast::binarithm_op::BAND,
	ltok::BOR	=> ast::binarithm_op::BOR,
	ltok::BXOR	=> ast::binarithm_op::BXOR,
	ltok::DIV	=> ast::binarithm_op::DIV,
	ltok::GREATER	=> ast::binarithm_op::GT,
	ltok::GREATEREQ	=> ast::binarithm_op::GTEQ,
	ltok::LAND	=> ast::binarithm_op::LAND,
	ltok::LEQUAL	=> ast::binarithm_op::LEQUAL,
	ltok::LESS	=> ast::binarithm_op::LESS,
	ltok::LESSEQ	=> ast::binarithm_op::LESSEQ,
	ltok::LOR	=> ast::binarithm_op::LOR,
	ltok::LSHIFT	=> ast::binarithm_op::LSHIFT,
	ltok::LXOR	=> ast::binarithm_op::LXOR,
	ltok::MINUS	=> ast::binarithm_op::MINUS,
	ltok::MODULO	=> ast::binarithm_op::MODULO,
	ltok::NEQUAL	=> ast::binarithm_op::NEQUAL,
	ltok::PLUS	=> ast::binarithm_op::PLUS,
	ltok::RSHIFT	=> ast::binarithm_op::RSHIFT,
	ltok::TIMES	=> ast::binarithm_op::TIMES,
	* => abort(),
};

fn precedence(tok: lex::token) int = switch (tok.0) {
	ltok::LOR => 0,
	ltok::LXOR => 1,
	ltok::LAND => 2,
	ltok::LEQUAL,
	ltok::NEQUAL => 3,
	ltok::LESS,
	ltok::LESSEQ,
	ltok::GREATER,
	ltok::GREATEREQ => 4,
	ltok::BOR => 5,
	ltok::BXOR => 6,
	ltok::BAND => 7,
	ltok::LSHIFT,
	ltok::RSHIFT => 8,
	ltok::PLUS,
	ltok::MINUS => 9,
	ltok::TIMES,
	ltok::DIV,
	ltok::MODULO => 10,
	* => -1,
};

fn expression_list(lexer: *lex::lexer) (ast::expr | error) = {
	let items: ast::list_expr = [];

	for (let more = true; more) {
		let tok = peek(lexer)? as lex::token;
		let item = switch (tok.0) {
			ltok::RBRACE => break,
			ltok::BREAK,
			ltok::CONTINUE,
			ltok::RETURN => {
				more = false;
				control_statement(lexer)?;
			},
			* => expression(lexer)?,
		};
		append(items, alloc(item));
		want(lexer, ltok::SEMICOLON)?;
	};

	want(lexer, ltok::RBRACE)?;
	return items;
};
