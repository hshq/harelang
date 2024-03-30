// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use math;
use strings;
use types;

// Parses an expression.
export fn expr(lexer: *lex::lexer) (ast::expr | error) = {
	const loc = lex::mkloc(lexer);

	// All assignment-op tokens
	const atoks: []ltok = [
		ltok::EQUAL, ltok::BANDEQ, ltok::BOREQ, ltok::BXOREQ,
		ltok::DIVEQ, ltok::LANDEQ, ltok::LOREQ, ltok::LXOREQ,
		ltok::LSHIFTEQ, ltok::MINUSEQ, ltok::MODEQ, ltok::PLUSEQ,
		ltok::RSHIFTEQ, ltok::TIMESEQ,
	];

	const ex = match (peek(lexer, ltok::IF, ltok::FOR, ltok::BREAK,
		ltok::CONTINUE, ltok::RETURN, ltok::YIELD)?) {
	case void =>
		yield binarithm(lexer, void, 0)?;
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::IF =>
			yield if_expr(lexer)?;
		case ltok::FOR =>
			yield for_expr(lexer)?;
		case ltok::BREAK, ltok::CONTINUE, ltok::RETURN =>
			yield control(lexer)?;
		case ltok::YIELD =>
			yield yield_expr(lexer)?;
		case => abort(); // Invariant
		};
	};

	const tok = match (try(lexer, atoks...)?) {
	case let tok: lex::token =>
		yield tok;
	case =>
		return ex;
	};

	const is_obj_selector = match (ex.expr) {
	case (ast::access_expr | ast::slice_expr) =>
		yield true;
	case let ex: ast::unarithm_expr =>
		yield ex.op == ast::unarithm_op::DEREF;
	case =>
		yield false;
	};
	synassert(lex::mkloc(lexer), is_obj_selector,
		"Expected an object-selector, pointer dereference, or slice for assignment target")?;
	const ex = ast::assign_expr {
		op = switch (tok.0) {
		case ltok::EQUAL =>
			yield void;
		case ltok::BANDEQ =>
			yield ast::binarithm_op::BAND;
		case ltok::BOREQ =>
			yield ast::binarithm_op::BOR;
		case ltok::BXOREQ =>
			yield ast::binarithm_op::BXOR;
		case ltok::DIVEQ =>
			yield ast::binarithm_op::DIV;
		case ltok::LANDEQ =>
			yield ast::binarithm_op::LAND;
		case ltok::LOREQ =>
			yield ast::binarithm_op::LOR;
		case ltok::LSHIFTEQ =>
			yield ast::binarithm_op::LSHIFT;
		case ltok::LXOREQ =>
			yield ast::binarithm_op::LXOR;
		case ltok::MINUSEQ =>
			yield ast::binarithm_op::MINUS;
		case ltok::MODEQ =>
			yield ast::binarithm_op::MODULO;
		case ltok::PLUSEQ =>
			yield ast::binarithm_op::PLUS;
		case ltok::RSHIFTEQ =>
			yield ast::binarithm_op::RSHIFT;
		case ltok::TIMESEQ =>
			yield ast::binarithm_op::TIMES;
		case => abort(); // unreachable
		},
		object = alloc(ex),
		value = alloc(expr(lexer)?),
	};

	return ast::expr {
		start = loc,
		end = lex::prevloc(lexer),
		expr = ex,
	};
};

fn assert_expr(lexer: *lex::lexer, is_static: bool) (ast::expr | error) = {
	const tok = want(lexer, ltok::ABORT, ltok::ASSERT)?;

	let expr = switch (tok.0) {
	case ltok::ABORT =>
		want(lexer, ltok::LPAREN)?;
		const msg: nullable *ast::expr =
			match (peek(lexer, ltok::RPAREN)?) {
			case lex::token =>
				yield null;
			case =>
				yield alloc(expr(lexer)?);
			};
		want(lexer, ltok::RPAREN)?;

		yield ast::assert_expr {
			cond      = null,
			message   = msg,
			is_static = is_static,
		};
	case ltok::ASSERT =>
		want(lexer, ltok::LPAREN)?;
		const cond: nullable *ast::expr =
			alloc(expr(lexer)?);
		const msg: nullable *ast::expr =
			match (try(lexer, ltok::COMMA)?) {
			case lex::token =>
				yield alloc(expr(lexer)?);
			case =>
				yield null;
			};
		want(lexer, ltok::RPAREN)?;

		yield ast::assert_expr {
			cond      = cond,
			message   = msg,
			is_static = is_static,
		};
	case => abort(); // unreachable
	};

	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn alloc_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::ALLOC)?;
	want(lexer, ltok::LPAREN)?;

	const init = alloc(expr(lexer)?);
	const expr =
		switch (want(lexer, ltok::COMMA, ltok::ELLIPSIS, ltok::RPAREN)?.0) {
		case ltok::COMMA =>
			const capacity = alloc(expr(lexer)?);
			want(lexer, ltok::RPAREN)?;
			yield ast::alloc_expr {
				init = init,
				form = ast::alloc_form::COPY,
				capacity = capacity,
			};
		case ltok::ELLIPSIS =>
			want(lexer, ltok::RPAREN)?;
			yield ast::alloc_expr {
				init = init,
				form = ast::alloc_form::COPY,
				capacity = null,
			};
		case ltok::RPAREN =>
			yield ast::alloc_expr {
				init = init,
				form = ast::alloc_form::OBJECT,
				capacity = null,
			};
		case => abort(); // unreachable
		};

	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn append_insert_expr(
	lexer: *lex::lexer,
	is_static: bool,
) (ast::expr | error) = {
	const tok = want(lexer, ltok::APPEND, ltok::INSERT)?;
	want(lexer, ltok::LPAREN)?;

	const object = if (tok.0 == ltok::APPEND) objsel(lexer)?
		else idxexpr(lexer)?;
	want(lexer, ltok::COMMA)?;
	const value = expr(lexer)?;

	let length: nullable *ast::expr = null;
	let variadic = false;
	match (try(lexer, ltok::COMMA, ltok::ELLIPSIS)?) {
	case let tok: lex::token =>
		switch (tok.0) {
		case ltok::COMMA =>
			length = alloc(expr(lexer)?);
		case ltok::ELLIPSIS =>
			variadic = true;
		case => abort();
		};
	case void => void;
	};
	want(lexer, ltok::RPAREN)?;

	let expr = ast::append_expr {
		object = alloc(object),
		value = alloc(value),
		length = length,
		variadic = variadic,
		is_static = is_static,
	};
	const expr = if (tok.0 == ltok::INSERT) {
		yield expr: ast::insert_expr;
	} else expr;

	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn measurement(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = want(lexer, ltok::LEN, ltok::ALIGN, ltok::SIZE, ltok::OFFSET)?;
	want(lexer, ltok::LPAREN)?;
	const expr = switch (tok.0) {
	case ltok::LEN =>
		yield alloc(expr(lexer)?): ast::len_expr;
	case ltok::ALIGN =>
		yield alloc(_type(lexer)?): ast::align_expr;
	case ltok::SIZE =>
		yield alloc(_type(lexer)?): ast::size_expr;
	case ltok::OFFSET =>
		yield alloc(expr(lexer)?): ast::offset_expr;
	case => abort(); // unreachable
	};
	want(lexer, ltok::RPAREN)?;

	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
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
	case void =>
		yield cast(lexer, void)?;
	case let expr: ast::expr =>
		yield expr;
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

		const expr = ast::expr {
			start = lvalue.start,
			end = lex::prevloc(lexer),
			expr = ast::binarithm_expr {
				op = op,
				lvalue = alloc(lvalue),
				rvalue = alloc(rvalue),
			},
		};
		lvalue = expr;
	};

	lex::unlex(lexer, tok);
	return lvalue;
};

fn binding_unpack(lexer: *lex::lexer) (ast::binding_unpack | error) = {
	let fields: ast::binding_unpack = [];
	for (true) {
		const (tok, value, _) = want(lexer, ltok::NAME,
			ltok::UNDERSCORE)?;
		if (tok == ltok::UNDERSCORE) {
			append(fields, void);
		} else {
			append(fields, value as str);
		};
		if (len(fields) == 1) {
			want(lexer, ltok::COMMA)?;
		} else {
			match (try(lexer, ltok::COMMA)?) {
			case void => break;
			case lex::token => void;
			};
		};
	};
	want(lexer, ltok::RPAREN)?;
	return fields;
};

fn binding(lexer: *lex::lexer, is_static: bool) (ast::expr | error) = {
	const loc = lex::mkloc(lexer);
	const tok = want(lexer, ltok::DEF, ltok::CONST, ltok::LET)?.0;
	const kind = switch (tok) {
	case ltok::DEF =>
		assert(!is_static);
		yield ast::binding_kind::DEF;
	case ltok::CONST =>
		yield ast::binding_kind::CONST;
	case ltok::LET =>
		yield ast::binding_kind::LET;
	case => abort(); // unreachable
	};

	let bindings: []ast::binding = [];
	for (true) {
		const (tok, value, _) = want(lexer, ltok::NAME, ltok::LPAREN)?;
		const name = switch (tok) {
		case ltok::NAME =>
			yield value as str;
		case ltok::LPAREN =>
			if (kind == ast::binding_kind::DEF) {
				return syntaxerr(lex::mkloc(lexer),
					"Can't use tuple unpacking with def");
			};
			yield binding_unpack(lexer)?;
		case => abort();
		};
		const btype: nullable *ast::_type =
			if (try(lexer, ltok::COLON)? is lex::token) {
				yield alloc(_type(lexer)?);
			} else null;
		want(lexer, ltok::EQUAL)?;
		const init = alloc(expr(lexer)?);
		append(bindings, ast::binding {
			name = name,
			_type = btype,
			init = init,
		});
		match (try(lexer, ltok::COMMA)?) {
		case void => break;
		case lex::token => void;
		};
	};

	return ast::expr {
		start = loc,
		end = lex::prevloc(lexer),
		expr = ast::binding_expr {
			is_static = is_static,
			kind = kind,
			bindings = bindings,
		},
	};
};

fn builtin(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (peek(lexer, ltok::ALIGN, ltok::ALLOC, ltok::APPEND,
		ltok::FREE, ltok::DELETE, ltok::ABORT, ltok::ASSERT,
		ltok::INSERT, ltok::STATIC, ltok::SIZE, ltok::LEN, ltok::OFFSET,
		ltok::VASTART, ltok::VAARG, ltok::VAEND)?) {
	case let tok: lex::token =>
		yield tok;
	case void =>
		return postfix(lexer, void);
	};
	switch (tok.0) {
	case ltok::ALLOC =>
		return alloc_expr(lexer);
	case ltok::APPEND, ltok::INSERT =>
		return append_insert_expr(lexer, false);
	case ltok::DELETE =>
		return delete_expr(lexer, false);
	case ltok::FREE =>
		return free_expr(lexer);
	case ltok::ABORT, ltok::ASSERT =>
		return assert_expr(lexer, false);
	case ltok::STATIC =>
		want(lexer, ltok::STATIC)!;
		return static_expr(lexer);
	case ltok::ALIGN, ltok::SIZE, ltok::LEN, ltok::OFFSET =>
		return measurement(lexer);
	case ltok::VASTART =>
		want(lexer, ltok::VASTART)?;
		want(lexer, ltok::LPAREN)?;
		want(lexer, ltok::RPAREN)?;
		return ast::expr {
			start = tok.2,
			end = lex::prevloc(lexer),
			expr = void: ast::vastart_expr: ast::variadic_expr,
		};
	case ltok::VAARG =>
		want(lexer, ltok::VAARG)?;
		want(lexer, ltok::LPAREN)?;
		const expr = alloc(objsel(lexer)?);
		want(lexer, ltok::RPAREN)?;
		return ast::expr {
			start = tok.2,
			end = lex::prevloc(lexer),
			expr = expr: ast::vaarg_expr: ast::variadic_expr,
		};
	case ltok::VAEND =>
		want(lexer, ltok::VAEND)?;
		want(lexer, ltok::LPAREN)?;
		const expr = alloc(objsel(lexer)?);
		want(lexer, ltok::RPAREN)?;
		return ast::expr {
			start = tok.2,
			end = lex::prevloc(lexer),
			expr = expr: ast::vaend_expr: ast::variadic_expr,
		};
	case => abort(); // Invariant
	};
};

fn call(lexer: *lex::lexer, lvalue: ast::expr) (ast::expr | error) = {
	let args: []*ast::expr = [];
	let variadic = false;

	for (true) {
		match (try(lexer, ltok::RPAREN)?) {
		case lex::token => break;
		case void => void;
		};

		append(args, alloc(expr(lexer)?));

		match (try(lexer, ltok::ELLIPSIS)?) {
		case lex::token =>
			variadic = true;
			want(lexer, ltok::RPAREN)?;
			break;
		case void => void;
		};

		switch (want(lexer, ltok::COMMA, ltok::RPAREN)?.0) {
		case ltok::RPAREN => break;
		case => void;
		};
	};

	return ast::expr {
		start = lvalue.start,
		end = lex::prevloc(lexer),
		expr = ast::call_expr {
			lvalue = alloc(lvalue),
			variadic = variadic,
			args = args,
		},
	};
};

fn cast(lexer: *lex::lexer, lvalue: (ast::expr | void)) (ast::expr | error) = {
	const lvalue = match (lvalue) {
	case void =>
		yield unarithm(lexer)?;
	case let e: ast::expr =>
		yield e;
	};
	const tok = match (try(lexer, ltok::COLON, ltok::AS, ltok::IS)?) {
	case void =>
		return lvalue;
	case let tok: lex::token =>
		yield tok.0;
	};
	const kind = switch (tok) {
	case ltok::COLON =>
		yield ast::cast_kind::CAST;
	case ltok::AS =>
		yield ast::cast_kind::ASSERTION;
	case ltok::IS =>
		yield ast::cast_kind::TEST;
	case => abort();
	};
	let typ = match (try(lexer, ltok::NULL)?) {
	case let t: lex::token =>
		yield alloc(ast::_type {
			start = t.2,
			end = lex::prevloc(lexer),
			flags = 0,
			repr = ast::builtin_type::NULL,
		});
	case void =>
		yield alloc(_type(lexer)?);
	};
	return cast(lexer, ast::expr {
		start = lvalue.start,
		end = lex::prevloc(lexer),
		expr = ast::cast_expr {
			kind = kind,
			value = alloc(lvalue),
			_type = typ,
		},
	})?;
};

fn literal(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = want(lexer)?;
	const expr: ast::literal_expr = switch (tok.0) {
	case ltok::LIT_RCONST, ltok::LIT_STR =>
		yield tok.1 as (rune | str);
	case ltok::LIT_U8, ltok::LIT_U16, ltok::LIT_U32, ltok::LIT_U64,
		ltok::LIT_UINT, ltok::LIT_SIZE =>
		yield ast::number_literal {
			suff = tok.0,
			value = tok.1 as u64,
			sign = false,
		};
	case ltok::LIT_I8, ltok::LIT_I16, ltok::LIT_I32, ltok::LIT_I64,
		ltok::LIT_INT =>
		const n = tok.1 as u64;
		yield ast::number_literal {
			suff = tok.0,
			value = n: i64,
			sign = false,
		};
	case ltok::LIT_ICONST =>
		const n = tok.1 as u64;
		yield ast::number_literal {
			suff = tok.0,
			value = if (n <= types::I64_MAX: u64) n: i64 else n,
			sign = false,
		};
	case ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST =>
		yield ast::number_literal {
			suff = tok.0,
			value = tok.1 as f64,
			sign = false,
		};
	case ltok::VOID =>
		yield void;
	case ltok::DONE =>
		yield done;
	case ltok::TRUE =>
		yield true;
	case ltok::FALSE =>
		yield false;
	case ltok::NULL =>
		yield ast::_null;
	case =>
		return syntaxerr(lex::mkloc(lexer), "Expected literal expression");
	};
	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn control(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = want(lexer, ltok::BREAK, ltok::CONTINUE, ltok::RETURN)?;
	let label = if (tok.0 == ltok::BREAK || tok.0 == ltok::CONTINUE) {
		yield match (try(lexer, ltok::COLON)?) {
		case lex::token =>
			yield want(lexer, ltok::NAME)?.1 as str;
		case void =>
			yield "";
		};
	} else "";
	const expr = switch (tok.0) {
	case ltok::BREAK =>
		yield label: ast::break_expr;
	case ltok::CONTINUE =>
		yield label: ast::continue_expr;
	case ltok::RETURN =>
		yield match (peek(lexer, ltok::COMMA, ltok::ELSE, ltok::RBRACE,
			ltok::RBRACKET, ltok::RPAREN, ltok::SEMICOLON,
			ltok::EOF)?) {
		case void =>
			yield alloc(expr(lexer)?): ast::return_expr;
		case lex::token =>
			yield null: ast::return_expr;
		};
	case => abort(); // unreachable
	};
	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn delete_expr(lexer: *lex::lexer, is_static: bool) (ast::expr | error) = {
	const start = want(lexer, ltok::DELETE)?;
	want(lexer, ltok::LPAREN)?;
	const expr = alloc(postfix(lexer, void)?);
	// TODO: Assert that this was an indexing expression
	want(lexer, ltok::RPAREN)?;
	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::delete_expr {
			object = expr,
			is_static = is_static,
		},
	};
};

fn compound_expr(lexer: *lex::lexer) (ast::expr | error) = {
	let items: []*ast::expr = [];

	const start = want(lexer, ltok::LBRACE, ltok::COLON)?;
	const label = switch (start.0) {
	case ltok::COLON =>
		const tok = want(lexer, ltok::NAME)?;
		want(lexer, ltok::LBRACE)?;
		yield tok.1 as str;
	case =>
		yield "";
	};

	for (true) {
		append(items, alloc(stmt(lexer)?));
		if (try(lexer, ltok::RBRACE)? is lex::token) {
			break;
		};
	};

	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::compound_expr {
			exprs = items,
			label = label,
		},
	};
};

fn stmt(lexer: *lex::lexer) (ast::expr | error) = {
	const expr = match (try(lexer, ltok::DEFER, ltok::DEF,
		ltok::LET, ltok::CONST, ltok::STATIC)?) {
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::DEFER =>
			let expr = alloc(expr(lexer)?);
			yield ast::expr {
				start = tok.2,
				end = lex::prevloc(lexer),
				expr = expr: ast::defer_expr,
			};
		case ltok::DEF, ltok::CONST, ltok::LET =>
			lex::unlex(lexer, tok);
			yield binding(lexer, false)?;
		case ltok::STATIC =>
			yield match (peek(lexer, ltok::LET, ltok::CONST)?) {
			case lex::token =>
				yield binding(lexer, true)?;
			case void =>
				yield static_expr(lexer)?;
			};
		case => abort(); // unreachable
		};
	case void =>
		yield expr(lexer)?;
	};

	want(lexer, ltok::SEMICOLON)?;
	return expr;
};

fn for_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = want(lexer, ltok::FOR)?;
	const label = if (try(lexer, ltok::COLON)? is lex::token) {
		const tok = want(lexer, ltok::NAME)?;
		yield tok.1 as str;
	} else "";
	want(lexer, ltok::LPAREN)?;

	let kind = void: (ast::for_kind | void);
	let predicate_loc = lex::mkloc(lexer);

	const bindings = match (try(lexer, ltok::LET, ltok::CONST)?) {
	case let tok: lex::token =>
		const binding_kind = switch (tok.0) {
		case ltok::LET =>
			yield ast::binding_kind::LET;
		case ltok::CONST =>
			yield ast::binding_kind::CONST;
		case => abort(); // unreachable
		};

		let bindings: []ast::binding = [];

		for (true) {
			const (tok, value, _) = want(lexer,
				ltok::NAME, ltok::LPAREN)?;
			const binding_name = switch (tok) {
			case ltok::NAME =>
				yield value as str;
			case ltok::LPAREN =>
				yield binding_unpack(lexer)?;
			case => abort(); // unreachable
			};
			const btype: nullable *ast::_type =
				if (try(lexer, ltok::COLON)? is lex::token) {
					yield alloc(_type(lexer)?);
				} else null;

			const (tok, _, _) = want(lexer, ltok::EQUAL,
				ltok::DOUBLE_DOT, ltok::BAND, ltok::ARROW)?;

			if (kind is void) {
				switch (tok) {
				case ltok::EQUAL =>
					kind = ast::for_kind::ACCUMULATOR;
				case ltok::DOUBLE_DOT =>
					kind = ast::for_kind::EACH_VALUE;
				case ltok::BAND =>
					want(lexer, ltok::DOUBLE_DOT)?;
					kind = ast::for_kind::EACH_POINTER;
				case ltok::ARROW =>
					kind = ast::for_kind::ITERATOR;
				case => abort(); // unreachable
				};
			} else if (kind as ast::for_kind !=
					ast::for_kind::ACCUMULATOR
					|| tok != ltok::EQUAL) {
				return syntaxerr(lex::mkloc(lexer),
					"Cannot create multiple bindings in non-c-style loop");
			};

			const init_expr = alloc(expr(lexer)?);

			append(bindings, ast::binding {
				name = binding_name,
				_type = btype,
				init = init_expr,
			});

			match (try(lexer, ltok::COMMA)?) {
			case lex::token =>
				void;
			case void =>
				break;
			};
		};

		if (kind as ast::for_kind == ast::for_kind::ACCUMULATOR) {
			want(lexer, ltok::SEMICOLON)?;
		};

		yield alloc(ast::expr {
			start = predicate_loc,
			end = lex::prevloc(lexer),
			expr = ast::binding_expr {
				is_static = false,
				kind = binding_kind,
				bindings = bindings,
			},
		});
	case void =>
		kind = ast::for_kind::ACCUMULATOR;
		yield null;
	};

	const cond: nullable *ast::expr = null;
	const afterthought: nullable *ast::expr = null;

	if (kind as ast::for_kind == ast::for_kind::ACCUMULATOR) {
		cond = alloc(expr(lexer)?);
		match (try(lexer, ltok::SEMICOLON)) {
		case lex::token =>
			afterthought = alloc(expr(lexer)?);
		case void => void;
		};
	};

	want(lexer, ltok::RPAREN)?;

	const body = alloc(expr(lexer)?);
	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = ast::for_expr {
			kind = kind as ast::for_kind,
			bindings = bindings,
			cond = cond,
			afterthought = afterthought,
			body = body,
			label = label,
		},
	};
};

fn free_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::FREE)?;
	want(lexer, ltok::LPAREN)?;
	const expr = alloc(expr(lexer)?);
	want(lexer, ltok::RPAREN)?;
	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = expr: ast::free_expr,
	};
};

fn if_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::IF)?;
	want(lexer, ltok::LPAREN)?;
	const cond = alloc(expr(lexer)?);
	want(lexer, ltok::RPAREN)?;
	const tbranch = alloc(expr(lexer)?);
	const fbranch: nullable *ast::expr = match (try(lexer, ltok::ELSE)?) {
	case void =>
		yield null;
	case lex::token =>
		yield alloc(expr(lexer)?);
	};
	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::if_expr {
			cond = cond,
			tbranch = tbranch,
			fbranch = fbranch,
		},
	};
};

fn indexing(lexer: *lex::lexer, lvalue: ast::expr) (ast::expr | error) = {
	let is_slice = false;
	let start: nullable *ast::expr = null, end: nullable *ast::expr = null;

	if (try(lexer, ltok::DOUBLE_DOT)? is lex::token) {
		is_slice = true;
	} else {
		start = alloc(expr(lexer)?);
	};
	if (!is_slice && try(lexer, ltok::DOUBLE_DOT)? is lex::token) {
		is_slice = true;
	};
	if (is_slice && peek(lexer, ltok::RBRACKET)? is void) {
		end = alloc(expr(lexer)?);
	};

	want(lexer, ltok::RBRACKET)?;
	return ast::expr {
		start = lvalue.start,
		end = lex::prevloc(lexer),
		expr = if (is_slice) ast::slice_expr {
			object = alloc(lvalue),
			start = start,
			end = end,
		} else ast::access_index {
			object = alloc(lvalue),
			index = {
				assert(end == null);
				yield start as *ast::expr;
			},
		},
	};
};

fn objsel(lexer: *lex::lexer) (ast::expr | error) = {
	let expr = postfix(lexer, void)?;
	synassert(lex::mkloc(lexer), expr.expr is ast::access_expr,
		"Expected object selector")?;
	return expr;
};

fn idxexpr(lexer: *lex::lexer) (ast::expr | error) = {
	const expr = postfix(lexer, void)?;
	synassert(lex::mkloc(lexer), expr.expr is ast::access_expr
		&& expr.expr as ast::access_expr is ast::access_index,
		"Expected indexing expression")?;
	return expr;
};

fn plain_expression(lexer: *lex::lexer) (ast::expr | error) = {
	let tok = peek(lexer)? as lex::token;
	if (tok.0 >= ltok::LIT_U8 && tok.0 <= ltok::LAST_LITERAL) {
		return literal(lexer);
	};
	switch (tok.0) {
	case ltok::TRUE, ltok::FALSE, ltok::NULL, ltok::VOID, ltok::DONE =>
		return literal(lexer);
	case ltok::LBRACKET =>
		return plain_array(lexer)?;
	case ltok::STRUCT =>
		let s = plain_struct(lexer, [])?;
		return ast::expr {
			start = tok.2,
			end = lex::prevloc(lexer),
			expr = s,
		};
	case ltok::LPAREN =>
		want(lexer, ltok::LPAREN)?;
		let ex = expr(lexer)?;
		switch (want(lexer, ltok::RPAREN, ltok::COMMA)?.0) {
		case ltok::RPAREN =>
			return ex;
		case ltok::COMMA =>
			return plain_tuple(lexer, ex, tok.2)?;
		case => abort();
		};
	case ltok::NAME =>
		let id = ident(lexer)?;
		match (peek(lexer, ltok::LBRACE)?) {
		case void =>
			return ast::expr {
				start = tok.2,
				end = lex::prevloc(lexer),
				expr = id: ast::access_identifier,
			};
		case lex::token =>
			let s = plain_struct(lexer, id)?;
			return ast::expr {
				start = tok.2,
				end = lex::prevloc(lexer),
				expr = s,
			};
		};
	case =>
		return syntaxerr(lex::mkloc(lexer),
			"Unexpected {}, was expecting an expression",
			lex::tokstr(tok));
	};
};

fn plain_array(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::LBRACKET)?;

	let values: []*ast::expr = [];
	let expand = false;
	for (true) {
		match (try(lexer, ltok::RBRACKET)?) {
		case lex::token => break;
		case void => void;
		};

		append(values, alloc(expr(lexer)?));

		match (try(lexer, ltok::COMMA, ltok::ELLIPSIS)?) {
		case void =>
			want(lexer, ltok::RBRACKET)?;
			break;
		case let tok: lex::token =>
			switch (tok.0) {
			case ltok::ELLIPSIS =>
				expand = true;
				want(lexer, ltok::RBRACKET)?;
				break;
			case ltok::COMMA => void;
			case => abort();
			};
		};
	};
	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::array_literal {
			expand = expand,
			values = values,
		},
	};
};

fn plain_struct(
	lexer: *lex::lexer,
	alias: ast::ident,
) (ast::struct_literal | error) = {
	if (len(alias) == 0) {
		want(lexer, ltok::STRUCT)?;
	};
	want(lexer, ltok::LBRACE)?;

	let autofill = false;
	let fields: [](ast::struct_value | *ast::struct_literal) = [];
	for (true) {
		const tok = want(lexer, ltok::ELLIPSIS,
			ltok::NAME, ltok::STRUCT)?;
		switch (tok.0) {
		case ltok::ELLIPSIS =>
			synassert(lex::mkloc(lexer), len(alias) != 0,
				"Cannot use auto-fill with anonymous struct")?;
			autofill = true;
			want(lexer, ltok::RBRACE)?;
			break;
		case ltok::NAME, ltok::STRUCT =>
			lex::unlex(lexer, tok);
			append(fields, struct_field(lexer)?);
		case => abort(); // unreachable
		};

		switch (want(lexer, ltok::COMMA, ltok::RBRACE)?.0) {
		case ltok::RBRACE => break;
		case ltok::COMMA =>
			if (try(lexer, ltok::RBRACE)? is lex::token) {
				break;
			};
		case => abort(); // unreachable
		};
	};

	return ast::struct_literal {
		autofill = autofill,
		alias = alias,
		fields = fields,
	};
};

fn struct_field(
	lexer: *lex::lexer,
) (ast::struct_value | *ast::struct_literal | error) = {
	const tok = want(lexer, ltok::NAME, ltok::STRUCT)?;
	switch (tok.0) {
	case ltok::NAME =>
		const name = strings::dup(tok.1 as str);
		const tok = match (try(lexer, ltok::COLON,
			ltok::DOUBLE_COLON, ltok::EQUAL)?) {
		case let tok: lex::token =>
			yield tok;
		case void =>
			let id: ast::ident = alloc([name]);
			return alloc(plain_struct(lexer, id)?);
		};

		switch (tok.0) {
		case ltok::COLON =>
			const _type = alloc(_type(lexer)?);
			want(lexer, ltok::EQUAL)?;
			const init = alloc(expr(lexer)?);
			return ast::struct_value {
				name = name,
				_type = _type,
				init = init,
			};
		case ltok::DOUBLE_COLON =>
			let id: ast::ident = alloc([name]);
			let rest = ident(lexer)?;
			append(id, rest...);
			return alloc(plain_struct(lexer, id)?);
		case ltok::EQUAL =>
			return ast::struct_value {
				name = name,
				_type = null,
				init = alloc(expr(lexer)?),
			};
		case => abort(); // Invariant
		};
	case ltok::STRUCT =>
		lex::unlex(lexer, tok);
		return alloc(plain_struct(lexer, [])?);
	case => abort(); // Invariant
	};
};

fn plain_tuple(
	lexer: *lex::lexer,
	ex: ast::expr,
	start: lex::location
) (ast::expr | error) = {
	let values: []*ast::expr = [];
	append(values, alloc(ex));

	for (true) {
		append(values, alloc(expr(lexer)?));

		match (try(lexer, ltok::COMMA)?) {
		case lex::token =>
			match (try(lexer, ltok::RPAREN)) {
			case lex::token => break;
			case => void;
			};
		case void =>
			want(lexer, ltok::RPAREN)?;
			break;
		};
	};

	return ast::expr {
		start = start,
		end = lex::prevloc(lexer),
		expr = values: ast::tuple_literal,
	};
};

fn postfix(lexer: *lex::lexer, lvalue: (ast::expr | void)) (ast::expr | error) = {
	let lvalue = match (lvalue) {
	case void =>
		yield plain_expression(lexer)?;
	case let ex: ast::expr =>
		yield ex;
	};

	let tok = match (try(lexer, ltok::LPAREN, ltok::DOT,
		ltok::LBRACKET, ltok::QUESTION, ltok::LNOT)?) {
	case void =>
		return lvalue;
	case let tok: lex::token =>
		yield tok;
	};

	let next = switch (tok.0) {
	case ltok::LPAREN =>
		yield call(lexer, lvalue)?;
	case ltok::DOT =>
		yield postfix_dot(lexer, lvalue)?;
	case ltok::LBRACKET =>
		yield indexing(lexer, lvalue)?;
	case ltok::QUESTION =>
		yield ast::expr {
			start = lvalue.start,
			end = lex::prevloc(lexer),
			expr = alloc(lvalue): ast::propagate_expr,
		};
	case ltok::LNOT =>
		yield ast::expr {
			start = lvalue.start,
			end = lex::prevloc(lexer),
			expr = alloc(lvalue): ast::error_assert_expr,
		};
	case => abort();
	};

	return postfix(lexer, next);
};

fn postfix_dot(
	lexer: *lex::lexer,
	lvalue: ast::expr,
) (ast::expr | error) = {
	match (try(lexer, ltok::NAME)?) {
	case let tok: lex::token =>
		return ast::expr {
			start = lvalue.start,
			end = lex::prevloc(lexer),
			expr = ast::access_field {
				object = alloc(lvalue),
				field = tok.1 as str,
			},
		};
	case void =>
		let lit = literal(lexer)?;
		let val = lit.expr as ast::literal_expr;
		synassert(lex::mkloc(lexer), val is ast::number_literal,
			"Expected integer literal")?;
		let val = val as ast::number_literal;
		return ast::expr {
			start = lvalue.start,
			end = lex::prevloc(lexer),
			expr = ast::access_tuple {
				object = alloc(lvalue),
				value = alloc(lit),
			},
		};
	};
};

fn static_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = want(lexer, ltok::ABORT, ltok::ASSERT, ltok::APPEND,
		ltok::INSERT, ltok::DELETE)?;
	lex::unlex(lexer, tok);

	switch (tok.0) {
	case ltok::ABORT, ltok::ASSERT =>
		return assert_expr(lexer, true);
	case ltok::APPEND, ltok::INSERT =>
		return append_insert_expr(lexer, true);
	case ltok::DELETE =>
		return delete_expr(lexer, true);
	case => abort(); // unreachable
	};
};

fn switch_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::SWITCH)?;

	const label = if (try(lexer, ltok::COLON)? is lex::token) {
		const tok = want(lexer, ltok::NAME)?;
		yield tok.1 as str;
	} else "";

	want(lexer, ltok::LPAREN)?;
	const value = expr(lexer)?;
	want(lexer, ltok::RPAREN)?;

	want(lexer, ltok::LBRACE)?;

	let cases: []ast::switch_case = [];
	for (true) {
		want(lexer, ltok::CASE)?;

		let opts: []*ast::expr = [];
		if (try(lexer, ltok::ARROW)? is void) for (true) {
			append(opts, alloc(expr(lexer)?));
			switch (want(lexer, ltok::ARROW, ltok::COMMA)?.0) {
			case ltok::ARROW =>
				break;
			case ltok::COMMA =>
				if (try(lexer, ltok::ARROW)? is lex::token) {
					break;
				};
			case => abort(); // unreachable
			};
		};

		let exprs: []*ast::expr = [];
		for (true) {
			append(exprs, alloc(stmt(lexer)?));
			match (peek(lexer, ltok::CASE, ltok::RBRACE)?) {
			case lex::token =>
				break;
			case void => void;
			};
		};

		append(cases, ast::switch_case {
			options = opts,
			exprs = exprs,
		});

		if (try(lexer, ltok::RBRACE)? is lex::token) {
			break;
		};
	};

	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::switch_expr {
			value = alloc(value),
			cases = cases,
			label = label,
		},
	};
};

fn match_case(lexer: *lex::lexer) (ast::match_case | error) = {
	want(lexer, ltok::CASE)?;
	let tok = lex::lex(lexer)?;
	let loc = tok.2;
	let name: str = "", typ: nullable *ast::_type = null;
	switch (tok.0) {
	case ltok::NULL =>
		typ = alloc(ast::_type {
			start = loc,
			end = lex::prevloc(lexer),
			flags = 0,
			repr = ast::builtin_type::NULL,
		});
	case ltok::LET =>
		name = want(lexer, ltok::NAME)?.1 as str;
		want(lexer, ltok::COLON)?;
		typ = alloc(_type(lexer)?);
	case ltok::ARROW =>
		lex::unlex(lexer, tok);
	case =>
		lex::unlex(lexer, tok);
		typ = alloc(_type(lexer)?);
	};
	want(lexer, ltok::ARROW)?;
	let exprs: []*ast::expr = [];
	for (true) {
		append(exprs, alloc(stmt(lexer)?));
		if (peek(lexer, ltok::CASE, ltok::RBRACE)? is lex::token) {
			break;
		};
	};

	return ast::match_case {
		name = name,
		_type = typ,
		exprs = exprs,
	};
};

fn match_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::MATCH)?;
	const label = if (try(lexer, ltok::COLON)? is lex::token) {
		const tok = want(lexer, ltok::NAME)?;
		yield tok.1 as str;
	} else "";
	want(lexer, ltok::LPAREN)?;
	const value = expr(lexer)?;
	want(lexer, ltok::RPAREN)?;
	want(lexer, ltok::LBRACE)?;

	let cases: []ast::match_case = [];
	for (true) {
		append(cases, match_case(lexer)?);
		if (try(lexer, ltok::RBRACE)? is lex::token) {
			break;
		};
	};

	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::match_expr {
			value = alloc(value),
			cases = cases,
			label = label,
		},
	};
};

fn unarithm(lexer: *lex::lexer) (ast::expr | error) = {
	const tok = match (try(lexer,
		ltok::MINUS, ltok::BNOT, ltok::LNOT, ltok::TIMES, ltok::BAND,
		ltok::SWITCH, ltok::MATCH, ltok::COLON, ltok::LBRACE)?) {
	case void =>
		return builtin(lexer);
	case let tok: lex::token =>
		yield switch (tok.0) {
		case ltok::SWITCH =>
			lex::unlex(lexer, tok);
			return switch_expr(lexer);
		case ltok::MATCH =>
			lex::unlex(lexer, tok);
			return match_expr(lexer);
		case ltok::COLON, ltok::LBRACE =>
			lex::unlex(lexer, tok);
			return compound_expr(lexer);
		case =>
			yield tok;
		};
	};

	const op = switch (tok.0) {
	case ltok::MINUS =>
		yield ast::unarithm_op::MINUS;
	case ltok::BNOT =>
		yield ast::unarithm_op::BNOT;
	case ltok::LNOT =>
		yield ast::unarithm_op::LNOT;
	case ltok::TIMES =>
		yield ast::unarithm_op::DEREF;
	case ltok::BAND =>
		yield ast::unarithm_op::ADDR;
	case => abort();
	};

	const operand = unarithm(lexer)?;
	const expr = :blk {
		if (op == ast::unarithm_op::MINUS) match (operand.expr) {
		case let c: ast::literal_expr =>
			match (c) {
			case let n: ast::number_literal =>
				let sign = false;
				const val = match (n.value) {
				case let i: i64 =>
					sign = i < 0;
					yield -i;
				case let u: u64 => void;
				case let f: f64 =>
					sign = math::signf64(f) < 0;
					yield -f;
				};

				if (val is void) yield;
				yield :blk, ast::number_literal {
					suff = n.suff,
					value = val as (i64 | f64),
					sign = sign,
				}: ast::literal_expr;
			case => void;
			};
		case => void;
		};

		yield ast::unarithm_expr {
			op = op,
			operand = alloc(operand),
		};
	};
	return ast::expr {
		start = tok.2,
		end = lex::prevloc(lexer),
		expr = expr,
	};
};

fn yield_expr(lexer: *lex::lexer) (ast::expr | error) = {
	const start = want(lexer, ltok::YIELD)?;
	let label = "";
	let value: nullable *ast::expr = null;
	match (try(lexer, ltok::COLON, ltok::COMMA, ltok::ELSE, ltok::RBRACE,
		ltok::RBRACKET, ltok::RPAREN, ltok::SEMICOLON, ltok::EOF)?) {
	case void =>
		value = alloc(expr(lexer)?);
	case let t: lex::token =>
		if (t.0 == ltok::COLON) {
			label = want(lexer, ltok::NAME)?.1 as str;
			match (try(lexer, ltok::COMMA)?) {
			case void => void;
			case lex::token =>
				value = alloc(expr(lexer)?);
			};
		} else {
			lex::unlex(lexer, t);
		};
	};
	return ast::expr {
		start = start.2,
		end = lex::prevloc(lexer),
		expr = ast::yield_expr {
			label = label,
			value = value,
		},
	};
};

fn binop_for_tok(tok: lex::token) ast::binarithm_op = {
	switch (tok.0) {
	case ltok::BAND =>
		return ast::binarithm_op::BAND;
	case ltok::BOR =>
		return ast::binarithm_op::BOR;
	case ltok::BXOR =>
		return ast::binarithm_op::BXOR;
	case ltok::DIV =>
		return ast::binarithm_op::DIV;
	case ltok::GT =>
		return ast::binarithm_op::GT;
	case ltok::GTEQ =>
		return ast::binarithm_op::GTEQ;
	case ltok::LAND =>
		return ast::binarithm_op::LAND;
	case ltok::LEQUAL =>
		return ast::binarithm_op::LEQUAL;
	case ltok::LESS =>
		return ast::binarithm_op::LESS;
	case ltok::LESSEQ =>
		return ast::binarithm_op::LESSEQ;
	case ltok::LOR =>
		return ast::binarithm_op::LOR;
	case ltok::LSHIFT =>
		return ast::binarithm_op::LSHIFT;
	case ltok::LXOR =>
		return ast::binarithm_op::LXOR;
	case ltok::MINUS =>
		return ast::binarithm_op::MINUS;
	case ltok::MODULO =>
		return ast::binarithm_op::MODULO;
	case ltok::NEQUAL =>
		return ast::binarithm_op::NEQUAL;
	case ltok::PLUS =>
		return ast::binarithm_op::PLUS;
	case ltok::RSHIFT =>
		return ast::binarithm_op::RSHIFT;
	case ltok::TIMES =>
		return ast::binarithm_op::TIMES;
	case => abort();
	};
};

fn precedence(tok: lex::token) int = {
	switch (tok.0) {
	case ltok::LOR =>
		return 0;
	case ltok::LXOR =>
		return 1;
	case ltok::LAND =>
		return 2;
	case ltok::LEQUAL, ltok::NEQUAL =>
		return 3;
	case ltok::LESS, ltok::LESSEQ, ltok::GT, ltok::GTEQ =>
		return 4;
	case ltok::BOR =>
		return 5;
	case ltok::BXOR =>
		return 6;
	case ltok::BAND =>
		return 7;
	case ltok::LSHIFT, ltok::RSHIFT =>
		return 8;
	case ltok::PLUS, ltok::MINUS =>
		return 9;
	case ltok::TIMES, ltok::DIV, ltok::MODULO =>
		return 10;
	case =>
		return -1;
	};
};
