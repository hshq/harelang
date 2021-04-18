use hare::ast;
use hare::lex::{ltok};
use hare::lex;
use fmt;

// Parses an expression.
export fn expression(lexer: *lex::lexer) (ast::expr | error) = {
	const indirect = match (try(lexer, ltok::TIMES)?) {
		void => false,
		lex::token => true,
	};

	// All assignment-op tokens
	const atoks: []ltok = [
		ltok::EQUAL, ltok::ANDEQ, ltok::BXOREQ, ltok::DIVEQ,
		ltok::LSHIFTEQ, ltok::MINUSEQ, ltok::MODEQ, ltok::OREQ,
		ltok::PLUSEQ, ltok::RSHIFTEQ, ltok::TIMESEQ,
	];

	const expr: ast::expr = if (indirect) {
		const expr = unarithm(lexer)?;
		// Disambiguate between
		// 	* unary-expression assignment-op expression
		// and
		// 	binary-expression
		if (peek(lexer, atoks...)? is lex::token) {
			expr;
		} else return binarithm(lexer, ast::unarithm_expr {
			op = ast::unarithm_op::DEREF,
			operand = alloc(expr),
		}, 0);
	} else match (peek(lexer, ltok::LBRACE, ltok::MATCH,
			ltok::SWITCH, ltok::IF, ltok::LABEL, ltok::FOR,
			ltok::BREAK, ltok::CONTINUE, ltok::RETURN, ltok::LET,
			ltok::CONST)?) {
		void => binarithm(lexer, void, 0)?,
		tok: lex::token => switch (tok.0) {
			ltok::LBRACE => expression_list(lexer)?,
			ltok::MATCH => abort(), // TODO
			ltok::SWITCH => switch_expr(lexer)?,
			ltok::IF => if_expr(lexer)?,
			ltok::LABEL, ltok::FOR => for_expr(lexer)?,
			ltok::BREAK,
			ltok::CONTINUE,
			ltok::RETURN => control(lexer)?,
			ltok::LET, ltok::CONST => binding(lexer, false)?,
			* => abort(), // Invariant
		},
	};

	const tok = match (try(lexer, atoks...)?) {
		tok: lex::token => tok,
		* => return expr,
	};

	synassert(mkloc(lexer),
		expr is ast::access_expr || expr is ast::slice_expr,
		"Expected an object-selector or slice for assignment target")?;

	return ast::assign_expr {
		op = switch (tok.0) {
			ltok::EQUAL	=> void,
			ltok::ANDEQ	=> ast::binarithm_op::BAND,
			ltok::BXOREQ	=> ast::binarithm_op::BXOR,
			ltok::DIVEQ	=> ast::binarithm_op::DIV,
			ltok::LSHIFTEQ	=> ast::binarithm_op::LSHIFT,
			ltok::MINUSEQ	=> ast::binarithm_op::MINUS,
			ltok::MODEQ	=> ast::binarithm_op::MODULO,
			ltok::OREQ	=> ast::binarithm_op::BOR,
			ltok::PLUSEQ	=> ast::binarithm_op::PLUS,
			ltok::RSHIFTEQ	=> ast::binarithm_op::RSHIFT,
			ltok::TIMESEQ	=> ast::binarithm_op::TIMES,
		},
		object = alloc(expr),
		value = alloc(expression(lexer)?),
		indirect = indirect,
	};
};

fn alloc_expr(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::ALLOC)?;
	want(lexer, ltok::LPAREN)?;

	const init = expression(lexer)?;
	const cap: nullable *ast::expr =
		if (try(lexer, ltok::COMMA)? is lex::token) {
			alloc(expression(lexer)?);
		} else null;

	want(lexer, ltok::RPAREN)?;

	return ast::alloc_expr {
		init = alloc(init),
		capacity = cap,
	};
};

fn append_expr(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::APPEND)?;
	want(lexer, ltok::LPAREN)?;

	const object =
		if (try(lexer, ltok::TIMES)? is lex::token) unarithm(lexer)?
		else objsel(lexer)?;
	want(lexer, ltok::COMMA)?;

	let variadic: nullable *ast::expr = null;
	let values: []*ast::expr = [];
	for (true) {
		if (try(lexer, ltok::RPAREN)? is lex::token) break;

		const expr = alloc(expression(lexer)?);
		switch (want(lexer, ltok::COMMA, ltok::ELLIPSIS, ltok::RPAREN)?.0) {
			ltok::COMMA => append(values, expr),
			ltok::ELLIPSIS => {
				variadic = expr;
				try(lexer, ltok::COMMA)?;
				want(lexer, ltok::RPAREN)?;
				break;
			},
			ltok::RPAREN => {
				append(values, expr);
				break;
			},
			* => abort(),
		};
	};

	synassert(mkloc(lexer), variadic != null || len(values) != 0,
		"Expected values to append")?;

	return ast::append_expr {
		object = alloc(object),
		variadic = variadic,
		values = values,
	};
};

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
	for (let j = precedence(tok); j >= i; j = precedence(tok)) {
		const op = binop_for_tok(tok);

		let rvalue = cast(lexer, void)?;
		tok = lex::lex(lexer)?;

		for (let k = precedence(tok); k > j; k = precedence(tok)) {
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

fn binding(lexer: *lex::lexer, is_static: bool) (ast::expr | error) = {
	const is_const = switch (want(lexer, ltok::LET, ltok::CONST)?.0) {
		ltok::LET => false,
		ltok::CONST => true,
	};

	let bindings: []ast::binding = [];
	for (true) {
		const name = want(lexer, ltok::NAME)?.1 as str;
		const btype: nullable *ast::_type =
			if (try(lexer, ltok::COLON)? is lex::token) {
				alloc(_type(lexer)?);
			} else null;
		want(lexer, ltok::EQUAL)?;
		const init = alloc(expression(lexer)?);
		append(bindings, ast::binding {
			name = name,
			_type = btype,
			init = init,
		});
		match (try(lexer, ltok::COMMA)?) {
			void => break,
			lex::token => void,
		};
	};

	return ast::binding_expr {
		is_static = is_static,
		is_const = is_const,
		bindings = bindings,
	};
};

fn builtin(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (peek(lexer, ltok::ALLOC, ltok::APPEND, ltok::FREE,
			ltok::DELETE, ltok::ABORT, ltok::ASSERT, ltok::STATIC,
			ltok::SIZE, ltok::LEN, ltok::OFFSET, ltok::DEFER)?) {
		tok: lex::token => tok,
		void => return postfix(lexer, void),
	};
	return switch (tok.0) {
		ltok::ALLOC => alloc_expr(lexer)?,
		ltok::APPEND => append_expr(lexer)?,
		ltok::DELETE => delete_expr(lexer)?,
		ltok::FREE => abort(), // TODO
		ltok::ASSERT => abort(), // TODO
		ltok::STATIC => {
			want(lexer, ltok::STATIC)?;
			let tok = match (peek(lexer, ltok::LET, ltok::CONST,
					ltok::ASSERT)?) {
				tok: lex::token => tok,
				// TODO: The following is lame
				void => return syntaxerr(tok.2,
					"Expected let, const, or assert"),
			};
			switch (tok.0) {
				ltok::LET, ltok::CONST => binding(lexer, true),
				ltok::ASSERT => abort(), // TODO
				* => abort(),
			};
		},
		ltok::SIZE, ltok::LEN, ltok::OFFSET => abort(), // TODO
		ltok::DEFER => {
			want(lexer, ltok::DEFER)?;
			alloc(expression(lexer)?): ast::defer_expr;
		},
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

fn delete_expr(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::DELETE)?;
	want(lexer, ltok::LPAREN)?;
	const expr = plain_expression(lexer)?;
	want(lexer, ltok::LBRACKET)?;
	const expr = alloc(indexing(lexer, expr)?);
	want(lexer, ltok::RPAREN)?;
	return expr: ast::delete_expr;
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

fn for_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = want(lexer, ltok::FOR, ltok::LABEL)?;
	const label: ast::label = switch (tok.0) {
		ltok::LABEL => {
			want(lexer, ltok::FOR)?;
			tok.1 as str;
		},
		* => "",
	};

	want(lexer, ltok::LPAREN)?;

	const bindings: nullable *ast::expr = match (peek(
			lexer, ltok::LET, ltok::CONST)?) {
		void => null,
		lex::token => {
			const bindings = alloc(binding(lexer, false)?);
			want(lexer, ltok::SEMICOLON)?;
			bindings;
		},
	};

	const cond = alloc(expression(lexer)?);

	const afterthought: nullable *ast::expr = match (peek(
			lexer, ltok::SEMICOLON)) {
		void => null,
		lex::token => {
			want(lexer, ltok::SEMICOLON)?;
			alloc(expression(lexer)?);
		},
	};

	want(lexer, ltok::RPAREN)?;

	return ast::for_expr {
		label = label,
		bindings = bindings,
		cond = cond,
		afterthought = afterthought,
		body = alloc(expression(lexer)?),
	};
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
		ltok::LBRACKET => plain_array(lexer)?,
		ltok::STRUCT => abort(), // TODO: Struct literal
		ltok::LPAREN => {
			want(lexer, ltok::LPAREN)?;
			let ex = expression(lexer)?;
			return switch (want(lexer, ltok::RPAREN, ltok::COMMA)?.0) {
				ltok::RPAREN => ex,
				ltok::COMMA => plain_tuple(lexer, ex)?,
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

fn plain_array(lexer: *lex::lexer) (ast::expr | error) = {
	want(lexer, ltok::LBRACKET)?;

	let values: []*ast::expr = [];
	let expand = false;
	for (true) {
		match (try(lexer, ltok::RBRACKET)?) {
			lex::token => break,
			void => void,
		};

		append(values, alloc(expression(lexer)?));

		match (try(lexer, ltok::COMMA, ltok::ELLIPSIS)?) {
			void => {
				want(lexer, ltok::RBRACKET)?;
				break;
			},
			tok: lex::token => switch (tok.0) {
				ltok::COMMA => void,
				ltok::ELLIPSIS => {
					expand = true;
					try(lexer, ltok::COMMA)?;
					want(lexer, ltok::RBRACKET)?;
					break;
				},
				* => abort(),
			},
		};
	};
	return ast::array_constant {
		expand = expand,
		values = values,
	};
};

fn plain_tuple(lexer: *lex::lexer, ex: ast::expr) (ast::expr | error) = {
	let values: []*ast::expr = [];
	append(values, alloc(ex));

	for (true) {
		match (try(lexer, ltok::RPAREN)?) {
			lex::token => break,
			void => void,
		};

		append(values, alloc(expression(lexer)?));

		match (try(lexer, ltok::COMMA)?) {
			void => {
				want(lexer, ltok::RPAREN)?;
				break;
			},
			lex::token => void,
		};
	};

	// XXX: Why do we have to cast this twice? harec bug?
	return values: ast::tuple_constant: ast::constant_expr;
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

fn switch_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::SWITCH)?;

	want(lexer, ltok::LPAREN)?;
	const value = expression(lexer)?;
	want(lexer, ltok::RPAREN)?;

	want(lexer, ltok::LBRACE)?;

	let cases: []ast::switch_case = [];
	for (true) {
		if (try(lexer, ltok::RBRACE)? is lex::token) break;

		let opts: []*ast::expr = [];
		if (try(lexer, ltok::TIMES)? is lex::token) {
			want(lexer, ltok::CASE)?;
		} else {
			for (true) {
				if (try(lexer, ltok::CASE) is lex::token) break;

				append(opts, alloc(expression(lexer)?));

				if (!(try(lexer, ltok::COMMA) is lex::token)) {
					want(lexer, ltok::CASE)?;
					break;
				};
			};
			synassert(mkloc(lexer), len(opts) != 0,
				"Expected a list of options")?;
		};

		append(cases, ast::switch_case {
			options = opts,
			value = alloc(expression(lexer)?),
		});

		if (!(try(lexer, ltok::COMMA) is lex::token)) {
			want(lexer, ltok::RBRACE)?;
			break;
		};
	};

	synassert(start.2, len(cases) != 0, "Expected a list of switch cases")?;

	return ast::switch_expr {
		value = alloc(value),
		cases = cases,
	};
};

fn unarithm(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (try(lexer,
			ltok::PLUS, ltok::MINUS, ltok::BNOT,
			ltok::LNOT, ltok::TIMES, ltok::BAND)) {
		void => return builtin(lexer),
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
