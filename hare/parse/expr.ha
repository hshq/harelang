use hare::ast;
use hare::lex::{ltok};
use hare::lex;
use fmt;

// Parses an expression.
export fn expression(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (peek(lexer, ltok::LBRACE, ltok::MATCH, ltok::SWITCH,
			ltok::IF, ltok::FOR, ltok::BREAK, ltok::CONTINUE,
			ltok::RETURN, ltok::LET, ltok::CONST)?) {
		void => return binarithm(lexer, void, 0),
		tok: lex::token => tok,
	};
	return switch (tok.0) {
		ltok::LBRACE => expression_list(lexer),
		ltok::MATCH => abort(), // TODO
		ltok::SWITCH => abort(), // TODO
		ltok::IF => if_expr(lexer),
		ltok::FOR => abort(), // TODO
		ltok::BREAK, ltok::CONTINUE, ltok::RETURN => control(lexer),
		ltok::LET, ltok::CONST => abort(), // TODO
		* => abort(), // Invariant
	};
};

fn binarithm(
	lexer: *lex::lexer,
	lvalue: (ast::expr | void),
	i: int,
) (ast::expr | error) = {
	// Precedence climbing parser
	// https://en.wikipedia.org/wiki/Operator-precedence_parser
	// TODO: Incorporate assignment into this?
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

fn builtin(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (peek(lexer, ltok::ALLOC, ltok::APPEND, ltok::FREE,
			ltok::DELETE, ltok::ABORT, ltok::ASSERT, ltok::STATIC,
			ltok::SIZE, ltok::LEN, ltok::OFFSET, ltok::DEFER)?) {
		tok: lex::token => tok,
		void => return postfix(lexer, void),
	};
	return switch (tok.0) {
		ltok::ALLOC => abort(),
		ltok::APPEND => abort(),
		ltok::DELETE => abort(),
		ltok::FREE => abort(),
		ltok::ASSERT => abort(),
		ltok::STATIC => abort(),
		ltok::SIZE, ltok::LEN, ltok::OFFSET => abort(),
		ltok::DEFER => abort(),
		* => abort(), // Invariant
	};
};

fn call(lexer: *lex::lexer, lvalue: ast::expr) (ast::expr | error) = {
	let args: []*ast::expr = [];
	let variadic = false;

	for (true) {
		match (try(lexer, ltok::RPAREN)?) {
			lex::token => break,
			void => void,
		};

		append(args, alloc(expression(lexer)?));

		match (try(lexer, ltok::ELLIPSIS)?) {
			lex::token => {
				variadic = true;
				try(lexer, ltok::COMMA)?;
				want(lexer, ltok::RPAREN)?;
				break;
			},
			void => void,
		};

		switch (want(lexer, ltok::COMMA, ltok::RPAREN)?.0) {
			ltok::RPAREN => break,
			* => void,
		};
	};

	return ast::call_expr {
		lvalue = alloc(lvalue),
		variadic = variadic,
		args = args,
	};
};

fn cast(lexer: *lex::lexer, lvalue: (ast::expr | void)) (ast::expr | error) = {
	const lvalue = match (lvalue) {
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
	const tok = want(lexer)?;
	return switch (tok.0) {
		ltok::LIT_U8, ltok::LIT_U16, ltok::LIT_U32, ltok::LIT_U64,
		ltok::LIT_UINT, ltok::LIT_SIZE, ltok::LIT_I8, ltok::LIT_I16,
		ltok::LIT_I32, ltok::LIT_I64, ltok::LIT_INT, ltok::LIT_ICONST,
		ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST, ltok::LIT_RUNE,
		ltok::LIT_STR => tok.1,
		ltok::VOID => void,
		ltok::TRUE => true,
		ltok::FALSE => false,
		ltok::NULL => ast::_null,
		* => syntaxerr(mkloc(lexer), "Expected constant expression"),
	};
};

fn control(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = want(lexer, ltok::BREAK, ltok::CONTINUE, ltok::RETURN)?;
	let label = if (tok.0 == ltok::BREAK || tok.0 == ltok::CONTINUE) {
		match (try(lexer, ltok::LABEL)?) {
			tok: lex::token => tok.1 as str,
			void => "",
		};
	} else "";
	return switch (tok.0) {
		ltok::BREAK => label: ast::break_expr,
		ltok::CONTINUE => label: ast::continue_expr,
		ltok::RETURN => match (peek(lexer, ltok::COMMA, ltok::SEMICOLON)?) {
			void => alloc(expression(lexer)?): ast::return_expr,
			lex::token => null: ast::return_expr,
		},
	};
};

fn expression_list(lexer: *lex::lexer) (ast::expr | error) = {
	let items: ast::list_expr = [];

	want(lexer, ltok::LBRACE)?;
	for (let more = true; more) {
		const item = match (peek(lexer, ltok::RBRACE)?) {
			lex::token => break,
			void => expression(lexer)?,
		};
		append(items, alloc(item));
		want(lexer, ltok::SEMICOLON)?;
	};

	want(lexer, ltok::RBRACE)?;
	return items;
};

fn if_expr(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::IF)?;
	want(lexer, ltok::LPAREN)?;
	const cond = alloc(expression(lexer)?);
	want(lexer, ltok::RPAREN)?;
	const tbranch = alloc(expression(lexer)?);
	const fbranch: nullable *ast::expr = match (try(lexer, ltok::ELSE)?) {
		void => null,
		lex::token => alloc(expression(lexer)?),
	};
	return ast::if_expr {
		cond = cond,
		tbranch = tbranch,
		fbranch = fbranch,
	};
};

fn indexing(lexer: *lex::lexer, lvalue: ast::expr) (ast::expr | error) = {
	let is_slice = false;
	let start: nullable *ast::expr = null, end: nullable *ast::expr = null;

	match (try(lexer, ltok::SLICE)?) {
		void => start = alloc(expression(lexer)?),
		lex::token => is_slice = true,
	};
	if (!is_slice) match (try(lexer, ltok::SLICE)?) {
		void => void,
		lex::token => is_slice = true,
	};
	if (is_slice) match (peek(lexer, ltok::RBRACKET)?) {
		lex::token => void,
		void => end = alloc(expression(lexer)?),
	};

	want(lexer, ltok::RBRACKET)?;
	return if (is_slice) ast::slice_expr {
		object = alloc(lvalue),
		start = start,
		end = end,
	} else ast::access_index {
		object = alloc(lvalue),
		index = {
			assert(start != null && end == null);
			start: *ast::expr;
		},
	};
};

fn objsel(lexer: *lex::lexer) (ast::expr | error) = {
	let expr = postfix(lexer, void)?;
	synassert(mkloc(lexer), expr is ast::access_expr,
		"Expected object selector")?;
	return expr;
};

fn plain_expression(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = peek(lexer)? as lex::token;
	if (tok.0 >= ltok::LIT_U8 && tok.0 <= ltok::LAST_LITERAL) {
		return constant(lexer);
	};
	return switch (tok.0) {
		ltok::TRUE, ltok::FALSE, ltok::NULL, ltok::VOID =>
			constant(lexer),
		ltok::LBRACKET => abort(), // TODO: Array literal
		ltok::STRUCT => abort(), // TODO: Struct literal
		ltok::LPAREN => {
			let ex = expression(lexer);
			return switch (want(lexer, ltok::RPAREN, ltok::COMMA)?.0) {
				ltok::RPAREN => ex,
				ltok::COMMA => abort(), // TODO: Tuple literal
				* => abort(),
			};
		},
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
	let lvalue = match (lvalue) {
		void => plain_expression(lexer)?,
		ex: ast::expr => ex,
	};

	lvalue = match (try(lexer, ltok::LPAREN,
			ltok::DOT, ltok::LBRACKET, ltok::QUESTION)) {
		tok: lex::token => switch (tok.0) {
			ltok::LPAREN => call(lexer, lvalue)?,
			ltok::DOT => postfix_dot(lexer, lvalue)?,
			ltok::LBRACKET => indexing(lexer, lvalue)?,
			ltok::QUESTION => alloc(lvalue): ast::propagate_expr,
			* => abort(),
		},
		void => return lvalue,
	};

	return postfix(lexer, lvalue);
};

fn postfix_dot(lexer: *lex::lexer, lvalue: ast::expr) (ast::expr | error) = {
	return match (try(lexer, ltok::NAME)?) {
		tok: lex::token => ast::access_field {
			object = alloc(lvalue),
			field = tok.1 as str,
		},
		void => {
			let con = constant(lexer)?;
			let val = con as ast::constant_expr;
			synassert(mkloc(lexer), val is lex::value,
				"Expected integer constant")?;
			let val = val as lex::value;
			synassert(mkloc(lexer), val is i64,
				"Expected integer constant")?;
			ast::access_tuple {
				object = alloc(lvalue),
				value = alloc(con),
			};
		},
	};
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
	ltok::LEQUAL, ltok::NEQUAL => 3,
	ltok::LESS, ltok::LESSEQ, ltok::GREATER, ltok::GREATEREQ => 4,
	ltok::BOR => 5,
	ltok::BXOR => 6,
	ltok::BAND => 7,
	ltok::LSHIFT, ltok::RSHIFT => 8,
	ltok::PLUS, ltok::MINUS => 9,
	ltok::TIMES, ltok::DIV, ltok::MODULO => 10,
	* => -1,
};
