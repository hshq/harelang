// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::ast::{binarithm_op};
use hare::lex;
use hare::lex::{ltok};
use io;
use strings;

// Unparses a [[hare::ast::expr]].
export fn expr(
	out: io::handle,
	syn: *synfunc,
	e: *ast::expr,
) (size | io::error) = {
	let ctx = context {
		out = out,
		...
	};
	return _expr(&ctx, syn, e);
};

fn _expr(ctx: *context, syn: *synfunc, e: *ast::expr) (size | io::error) = {
	ctx.stack = &stack {
		cur = e,
		up = ctx.stack,
		...
	};
	defer {
		let stack = &(ctx.stack as *stack);
		match (stack.extra) {
		case let p: *opaque =>
			free(p);
		case null => void;
		};
		ctx.stack = stack.up;
	};

	match (e.expr) {
	case let e: ast::access_expr =>
		match (e) {
		case let id: ast::access_identifier =>
			return _ident(ctx, syn, id, synkind::IDENT);
		case let ix: ast::access_index =>
			let z = 0z;
			const needs_parens = !is_postfix(ix.object);
			if (needs_parens) {
				z += syn(ctx, "(", synkind::PUNCTUATION)?;
			};
			z += _expr(ctx, syn, ix.object)?;
			if (needs_parens) {
				z += syn(ctx, ")", synkind::PUNCTUATION)?;
			};
			z += syn(ctx, "[", synkind::PUNCTUATION)?;
			z += _expr(ctx, syn, ix.index)?;
			z += syn(ctx, "]", synkind::PUNCTUATION)?;
			return z;
		case let fi: ast::access_field =>
			let z = 0z;
			const needs_parens = !is_postfix(fi.object);
			if (needs_parens) {
				z += syn(ctx, "(", synkind::PUNCTUATION)?;
			};
			z += _expr(ctx, syn, fi.object)?;
			if (needs_parens) {
				z += syn(ctx, ")", synkind::PUNCTUATION)?;
			};
			z += syn(ctx, ".", synkind::OPERATOR)?;
			z += syn(ctx, fi.field, synkind::SECONDARY)?;
			return z;
		case let tp: ast::access_tuple =>
			let z = 0z;
			const needs_parens = !is_postfix(tp.object);
			if (needs_parens) {
				z += syn(ctx, "(", synkind::PUNCTUATION)?;
			};
			z += _expr(ctx, syn, tp.object)?;
			if (needs_parens) {
				z += syn(ctx, ")", synkind::PUNCTUATION)?;
			};
			z += syn(ctx, ".", synkind::OPERATOR)?;
			z += _expr(ctx, syn, tp.value)?;
			return z;
		};
	case let e: ast::align_expr =>
		let z = syn(ctx, "align", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += __type(ctx, syn, e)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::alloc_expr =>
		let z = syn(ctx, "alloc", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e.init)?;
		match (e.capacity) {
		case null =>
			if (e.form == ast::alloc_form::COPY) {
				z += syn(ctx, "...", synkind::OPERATOR)?;
			};
		case let e: *ast::expr =>
			z += syn(ctx, ",", synkind::PUNCTUATION)?;
			z += space(ctx)?;
			z += _expr(ctx, syn, e)?;
		};
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case ast::append_expr =>
		return append_insert_expr(ctx, syn, e);
	case let e: ast::assert_expr =>
		return assert_expr(ctx, syn, &e);
	case let e: ast::assign_expr =>
		let z = 0z;
		z += _expr(ctx, syn, e.object)?;
		const op = match (e.op) {
		case void =>
			yield "=";
		case let op: binarithm_op =>
			yield switch (op) {
			case binarithm_op::BAND =>
				yield "&=";
			case binarithm_op::LAND =>
				yield "&&=";
			case binarithm_op::BOR =>
				yield "|=";
			case binarithm_op::LOR =>
				yield "||=";
			case binarithm_op::DIV =>
				yield "/=";
			case binarithm_op::LSHIFT =>
				yield "<<=";
			case binarithm_op::MINUS =>
				yield "-=";
			case binarithm_op::MODULO =>
				yield "%=";
			case binarithm_op::PLUS =>
				yield "+=";
			case binarithm_op::RSHIFT =>
				yield ">>=";
			case binarithm_op::TIMES =>
				yield "*=";
			case binarithm_op::BXOR =>
				yield "^=";
			case binarithm_op::LXOR =>
				yield "^^=";
			case binarithm_op::GT, binarithm_op::GTEQ,
				binarithm_op::LESS, binarithm_op::LESSEQ,
				binarithm_op::LEQUAL, binarithm_op::NEQUAL =>
				abort(); // unreachable
			};
		};
		z += space(ctx)?;
		z += syn(ctx, op, synkind::OPERATOR)?;
		z += space(ctx)?;
		z += _expr(ctx, syn, e.value)?;
		return z;
	case let e: ast::binarithm_expr =>
		const prec = binprecedence(e.op);
		let z = binexprval(ctx, syn, e.lvalue, prec)?;
		z += space(ctx)?;
		z += syn(ctx, switch (e.op) {
		case binarithm_op::BAND =>
			yield "&";
		case binarithm_op::BOR =>
			yield "|";
		case binarithm_op::DIV =>
			yield "/";
		case binarithm_op::GT =>
			yield ">";
		case binarithm_op::GTEQ =>
			yield ">=";
		case binarithm_op::LAND =>
			yield "&&";
		case binarithm_op::LEQUAL =>
			yield "==";
		case binarithm_op::LESS =>
			yield "<";
		case binarithm_op::LESSEQ =>
			yield "<=";
		case binarithm_op::LOR =>
			yield "||";
		case binarithm_op::LSHIFT =>
			yield "<<";
		case binarithm_op::LXOR =>
			yield "^^";
		case binarithm_op::MINUS =>
			yield "-";
		case binarithm_op::MODULO =>
			yield "%";
		case binarithm_op::NEQUAL =>
			yield "!=";
		case binarithm_op::PLUS =>
			yield "+";
		case binarithm_op::RSHIFT =>
			yield ">>";
		case binarithm_op::TIMES =>
			yield "*";
		case binarithm_op::BXOR =>
			yield "^";
		}, synkind::OPERATOR)?;
		z += space(ctx)?;
		z += binexprval(ctx, syn, e.rvalue, prec)?;
		return z;
	case let e: ast::binding_expr =>
		return binding_expr(ctx, syn, &e, "=")?;
	case let e: ast::break_expr =>
		let z = syn(ctx, "break", synkind::KEYWORD)?;
		if (e != "") {
			z += space(ctx)?;
			z += syn(ctx, ":", synkind::LABEL)?;
			z += syn(ctx, e, synkind::LABEL)?;
		};
		return z;
	case let e: ast::call_expr =>
		let z = 0z;
		const needs_parens = !is_postfix(e.lvalue);
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e.lvalue)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		for (let i = 0z; i < len(e.args); i += 1) {
			z += _expr(ctx, syn, e.args[i])?;
			if (i + 1 < len(e.args)) {
				z += syn(ctx, ",", synkind::PUNCTUATION)?;
				z += space(ctx)?;
			};
		};
		if (e.variadic) {
			z += syn(ctx, "...", synkind::OPERATOR)?;
		};
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::cast_expr =>
		let z = 0z;
		const needs_parens = !is_cast(e.value);
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e.value)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		switch (e.kind) {
		case ast::cast_kind::CAST =>
			z += syn(ctx, ":", synkind::OPERATOR)?;
			z += space(ctx)?;
		case ast::cast_kind::ASSERTION =>
			z += space(ctx)?;
			z += syn(ctx, "as", synkind::OPERATOR)?;
			z += space(ctx)?;
		case ast::cast_kind::TEST =>
			z += space(ctx)?;
			z += syn(ctx, "is", synkind::OPERATOR)?;
			z += space(ctx)?;
		};
		z += __type(ctx, syn, e._type)?;
		return z;
	case let e: ast::literal_expr =>
		return literal(ctx, syn, e)?;
	case let e: ast::continue_expr =>
		let z = syn(ctx, "continue", synkind::KEYWORD)?;
		if (e != "") {
			z += space(ctx)?;
			z += syn(ctx, ":", synkind::LABEL)?;
			z += syn(ctx, e, synkind::LABEL)?;
		};
		return z;
	case let e: ast::defer_expr =>
		let z = syn(ctx, "defer", synkind::KEYWORD)?;
		z += space(ctx)?;
		z += _expr(ctx, syn, e)?;
		return z;
	case let e: ast::delete_expr =>
		let z = 0z;
		if (e.is_static) {
			z += syn(ctx, "static", synkind::KEYWORD)?;
			z += space(ctx)?;
		};
		z += syn(ctx, "delete", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e.object)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::error_assert_expr =>
		let z = 0z;
		const needs_parens = !is_postfix(e);
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		z += syn(ctx, "!", synkind::OPERATOR)?;
		return z;
	case let e: ast::for_expr =>
		return for_expr(ctx, syn, &e)?;
	case let e: ast::free_expr =>
		let z = syn(ctx, "free", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::if_expr =>
		let z = syn(ctx, "if", synkind::KEYWORD)?;
		z += space(ctx)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e.cond)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		z += space(ctx)?;
		z += _expr(ctx, syn, e.tbranch)?;
		match (e.fbranch) {
		case null => void;
		case let e: *ast::expr =>
			z += space(ctx)?;
			z += syn(ctx, "else", synkind::KEYWORD)?;
			z += space(ctx)?;
			z += _expr(ctx, syn, e)?;
		};
		return z;
	case ast::insert_expr =>
		return append_insert_expr(ctx, syn, e);
	case let e: ast::compound_expr =>
		let z = 0z;
		if (e.label != "") {
			z += syn(ctx, ":", synkind::LABEL)?;
			z += syn(ctx, e.label, synkind::LABEL)?;
			z += space(ctx)?;
		};
		z += syn(ctx, "{", synkind::PUNCTUATION)?;
		ctx.indent += 1;
		for (let expr .. e.exprs) {
			z += newline(ctx)?;
			z += stmt(ctx, syn, expr)?;
		};
		ctx.indent -= 1;
		z += newline(ctx)?;
		z += syn(ctx, "}", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::match_expr =>
		return match_expr(ctx, syn, &e)?;
	case let e: ast::len_expr =>
		let z = syn(ctx, "len", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::size_expr =>
		let z = syn(ctx, "size", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += __type(ctx, syn, e)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::offset_expr =>
		let z = syn(ctx, "offset", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e)?;
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::propagate_expr =>
		let z = 0z;
		const needs_parens = !is_postfix(e);
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		z += syn(ctx, "?", synkind::OPERATOR)?;
		return z;
	case let e: ast::return_expr =>
		let z = syn(ctx, "return", synkind::KEYWORD)?;
		match (e) {
		case null => void;
		case let e: *ast::expr =>
			z += space(ctx)?;
			z += _expr(ctx, syn, e)?;
		};
		return z;
	case let e: ast::slice_expr =>
		let z = 0z;
		const needs_parens = !is_postfix(e.object);
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e.object)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		z += syn(ctx, "[", synkind::PUNCTUATION)?;
		match (e.start) {
		case null => void;
		case let e: *ast::expr =>
			z += _expr(ctx, syn, e)?;
		};
		z += syn(ctx, "..", synkind::OPERATOR)?;
		match (e.end) {
		case null => void;
		case let e: *ast::expr =>
			z += _expr(ctx, syn, e)?;
		};
		z += syn(ctx, "]", synkind::PUNCTUATION)?;
		return z;
	case let e: ast::switch_expr =>
		return switch_expr(ctx, syn, &e)?;
	case let e: ast::unarithm_expr =>
		let z = syn(ctx, switch (e.op) {
		case ast::unarithm_op::ADDR =>
			yield "&";
		case ast::unarithm_op::BNOT =>
			yield "~";
		case ast::unarithm_op::DEREF =>
			yield "*";
		case ast::unarithm_op::LNOT =>
			yield "!";
		case ast::unarithm_op::MINUS =>
			yield "-";
		}, synkind::OPERATOR)?;
		const needs_parens = match (e.operand.expr) {
		case let inner: ast::unarithm_expr =>
			yield e.op == ast::unarithm_op::ADDR
				&& inner.op == e.op;
		case =>
			yield !is_unary(e.operand);
		};
		if (needs_parens) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
		};
		z += _expr(ctx, syn, e.operand)?;
		if (needs_parens) {
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		return z;
	case let e: ast::variadic_expr =>
		match (e) {
		case ast::vastart_expr =>
			let z = syn(ctx, "vastart", synkind::KEYWORD)?;
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
			return z;
		case let e: ast::vaarg_expr =>
			let z = syn(ctx, "vaarg", synkind::KEYWORD)?;
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
			z += _expr(ctx, syn, e)?;
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
			return z;
		case let e: ast::vaend_expr =>
			let z = syn(ctx, "vaend", synkind::KEYWORD)?;
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
			z += _expr(ctx, syn, e)?;
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
			return z;
		};
	case let e: ast::yield_expr =>
		let z = syn(ctx, "yield", synkind::KEYWORD)?;
		if (e.label != "") {
			z += space(ctx)?;
			z += syn(ctx, ":", synkind::LABEL)?;
			z += syn(ctx, e.label, synkind::LABEL)?;
		};
		match (e.value) {
		case null => void;
		case let v: *ast::expr =>
			if (e.label != "") {
				z += syn(ctx, ",", synkind::PUNCTUATION)?;
			};
			z += space(ctx)?;
			z += _expr(ctx, syn, v)?;
		};
		return z;
	};
};

fn binprecedence(op: binarithm_op) uint = {
	switch (op) {
	case binarithm_op::DIV, binarithm_op::MODULO, binarithm_op::TIMES =>
		return 10;
	case binarithm_op::MINUS, binarithm_op::PLUS =>
		return 9;
	case binarithm_op::LSHIFT, binarithm_op::RSHIFT =>
		return 8;
	case binarithm_op::BAND =>
		return 7;
	case binarithm_op::BXOR =>
		return 6;
	case binarithm_op::BOR =>
		return 5;
	case binarithm_op::GT, binarithm_op::GTEQ,
		binarithm_op::LESS, binarithm_op::LESSEQ =>
		return 4;
	case binarithm_op::LEQUAL, binarithm_op::NEQUAL =>
		return 3;
	case binarithm_op::LAND =>
		return 2;
	case binarithm_op::LXOR =>
		return 1;
	case binarithm_op::LOR =>
		return 0;
	};
};

fn binexprval(
	ctx: *context,
	syn: *synfunc,
	e: *ast::expr,
	prec: uint,
) (size | io::error) = {
	let z = 0z;
	match (e.expr) {
	case let b: ast::binarithm_expr =>
		if (binprecedence(b.op) < prec) {
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
			z += _expr(ctx, syn, e)?;
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
			return z;
		};
	case => void;
	};
	const needs_parens = !is_cast(e) && !(e.expr is ast::binarithm_expr);
	if (needs_parens) {
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
	};
	z += _expr(ctx, syn, e)?;
	if (needs_parens) {
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
	};
	return z;
};

fn stmt(ctx: *context, syn: *synfunc, e: *ast::expr) (size | io::error) = {
	let n = _expr(ctx, syn, e)?;
	n += syn(ctx, ";", synkind::PUNCTUATION)?;
	return n;
};

fn literal(
	ctx: *context,
	syn: *synfunc,
	e: ast::literal_expr,
) (size | io::error) = {
	match (e) {
	case void =>
		return syn(ctx, "void", synkind::KEYWORD)?;
	case let v: ast::value =>
		match (v) {
		case void => abort();
		case ast::_null =>
			return syn(ctx, "null", synkind::KEYWORD)?;
		case let b: bool =>
			return syn(ctx, if (b) "true" else "false",
				synkind::KEYWORD)?;
		case let s: str =>
			const s = strings::multireplace(s,
				(`\`, `\\`), (`"`, `\"`));
			defer free(s);
			const s = fmt::asprintf(`"{}"`, s);
			defer free(s);
			return syn(ctx, s, synkind::RUNE_STRING)?;
		case let r: rune =>
			// 4 for unicode codepoint + 2 's
			let buf: [6]u8 = [0...];
			if (r == '\'' || r == '\\') {
				return syn(ctx, fmt::bsprintf(buf, `'\{}'`, r),
					synkind::RUNE_STRING)?;
			} else {
				return syn(ctx, fmt::bsprintf(buf, "'{}'", r),
					synkind::RUNE_STRING)?;
			};
		};
	case let ac: ast::array_literal =>
		let z = syn(ctx, "[", synkind::PUNCTUATION)?;
		for (let i = 0z; i < len(ac.values); i += 1) {
			z += _expr(ctx, syn, ac.values[i])?;
			if (i + 1 < len(ac.values)) {
				z += syn(ctx, ",", synkind::PUNCTUATION)?;
				z += space(ctx)?;
			};
		};
		if (ac.expand) {
			z += syn(ctx, "...", synkind::OPERATOR)?;
		};
		z += syn(ctx, "]", synkind::PUNCTUATION)?;
		return z;
	case let v: ast::number_literal =>
		const s = fmt::asprintf("{}{}", v.value, switch (v.suff) {
		case ltok::LIT_U8 =>
			yield "u8";
		case ltok::LIT_U16 =>
			yield "u16";
		case ltok::LIT_U32 =>
			yield "u32";
		case ltok::LIT_U64 =>
			yield "u64";
		case ltok::LIT_UINT =>
			yield "u";
		case ltok::LIT_SIZE =>
			yield "z";
		case ltok::LIT_I8 =>
			yield "i8";
		case ltok::LIT_I16 =>
			yield "i16";
		case ltok::LIT_I32 =>
			yield "i32";
		case ltok::LIT_I64 =>
			yield "i64";
		case ltok::LIT_INT =>
			yield "i";
		case ltok::LIT_ICONST, ltok::LIT_FCONST =>
			yield "";
		case ltok::LIT_F32 =>
			yield "f32";
		case ltok::LIT_F64 =>
			yield "f64";
		case => abort();
		});
		defer free(s);
		return syn(ctx, s, synkind::NUMBER)?;
	case let sc: ast::struct_literal =>
		return struct_literal(ctx, syn, sc)?;
	case let tu: ast::tuple_literal =>
		let z = syn(ctx, "(", synkind::PUNCTUATION)?;
		for (let i = 0z; i < len(tu); i += 1) {
			z += _expr(ctx, syn, tu[i])?;
			if (i + 1 < len(tu)) {
				z += syn(ctx, ",", synkind::PUNCTUATION)?;
				z += space(ctx)?;
			};
		};
		z += syn(ctx, ")", synkind::PUNCTUATION)?;
		return z;
	};
};

fn struct_literal(
	ctx: *context,
	syn: *synfunc,
	sc: ast::struct_literal,
) (size | io::error) = {
	let z = 0z;
	z += if (len(sc.alias) != 0) {
		yield _ident(ctx, syn, sc.alias, synkind::IDENT)?;
	} else {
		yield syn(ctx, "struct", synkind::KEYWORD)?;
	};
	z += space(ctx)?;
	z += syn(ctx, "{", synkind::PUNCTUATION)?;
	ctx.indent += 1;
	for (let field .. sc.fields) {
		z += newline(ctx)?;
		match (field) {
		case let sv: ast::struct_value =>
			z += syn(ctx, sv.name, synkind::SECONDARY)?;
			match (sv._type) {
			case null => void;
			case let t: *ast::_type =>
				z += syn(ctx, ":", synkind::PUNCTUATION)?;
				z += space(ctx)?;
				z += __type(ctx, syn, t)?;
			};
			z += space(ctx)?;
			z += syn(ctx, "=", synkind::OPERATOR)?;
			z += space(ctx)?;
			z += _expr(ctx, syn, sv.init)?;
		case let sc: *ast::struct_literal =>
			z += literal(ctx, syn, *sc)?;
		};
		z += syn(ctx, ",", synkind::PUNCTUATION)?;
	};
	if (sc.autofill) {
		z += newline(ctx)?;
		z += syn(ctx, "...", synkind::OPERATOR)?;
	};
	ctx.indent -= 1;
	z += newline(ctx)?;
	z += syn(ctx, "}", synkind::PUNCTUATION)?;
	return z;
};

fn binding_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::binding_expr,
	assign_op: str
) (size | io::error) = {
	let z = 0z;
	if (e.is_static) {
		z += syn(ctx, "static", synkind::KEYWORD)?;
		z += space(ctx)?;
	};
	switch (e.kind) {
	case ast::binding_kind::DEF =>
		z += syn(ctx, "def", synkind::KEYWORD)?;
	case ast::binding_kind::CONST =>
		z += syn(ctx, "const", synkind::KEYWORD)?;
	case ast::binding_kind::LET =>
		z += syn(ctx, "let", synkind::KEYWORD)?;
	};
	z += space(ctx)?;
	for (let i = 0z; i < len(e.bindings); i += 1) {
		let binding = e.bindings[i];

		match (binding.name) {
		case let s: str =>
			z += syn(ctx, s, synkind::IDENT)?;
		case let u: ast::binding_unpack =>
			z += syn(ctx, "(", synkind::PUNCTUATION)?;
			for (let i = 0z; i < len(u); i += 1) {
				match (u[i]) {
				case let s: str =>
					z += syn(ctx, s,
						synkind::IDENT)?;
				case void =>
					z += syn(ctx, "_",
						synkind::OPERATOR)?;
				};
				if (i + 1 < len(u)) {
					z += syn(ctx, ",",
						synkind::PUNCTUATION)?;
					z += space(ctx)?;
				};
			};
			z += syn(ctx, ")", synkind::PUNCTUATION)?;
		};
		match (binding._type) {
		case let t: *ast::_type =>
			z += syn(ctx, ":", synkind::PUNCTUATION)?;
			z += space(ctx)?;
			z += __type(ctx, syn, t)?;
		case null => void;
		};
		z += space(ctx)?;
		z += syn(ctx, assign_op, synkind::OPERATOR)?;
		z += space(ctx)?;
		z += _expr(ctx, syn, binding.init)?;
		if (i + 1 < len(e.bindings)) {
			z += syn(ctx, ",", synkind::PUNCTUATION)?;
			z += space(ctx)?;
		};
	};
	return z;
};

fn for_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::for_expr,
) (size | io::error) = {
	let z = syn(ctx, "for", synkind::KEYWORD)?;
	z += space(ctx)?;
	if (e.label != "") {
		z += syn(ctx, ":", synkind::LABEL)?;
		z += syn(ctx, e.label, synkind::LABEL)?;
		z += space(ctx)?;
	};
	z += syn(ctx, "(", synkind::PUNCTUATION)?;

	let assign_op = switch (e.kind) {
	case ast::for_kind::ACCUMULATOR =>
		yield "=";
	case ast::for_kind::EACH_VALUE =>
		yield "..";
	case ast::for_kind::EACH_POINTER =>
		yield "&..";
	case ast::for_kind::ITERATOR =>
		yield "=>";
	};

	match (e.bindings) {
	case let bind_expr: *ast::expr =>
		z += binding_expr(ctx, syn,
			&(bind_expr.expr as ast::binding_expr), assign_op)?;

		if (e.kind == ast::for_kind::ACCUMULATOR) {
			z += syn(ctx, ";", synkind::PUNCTUATION)?;
			z += space(ctx)?;
		};
	case null => void;
	};

	if (e.kind == ast::for_kind::ACCUMULATOR) {
		z += _expr(ctx, syn, e.cond as *ast::expr)?;

		match (e.afterthought) {
		case null => void;
		case let e: *ast::expr =>
			z += syn(ctx, ";", synkind::PUNCTUATION)?;
			z += space(ctx)?;
			z += _expr(ctx, syn, e)?;
		};
	};

	z += syn(ctx, ")", synkind::PUNCTUATION)?;
	z += space(ctx)?;
	z += _expr(ctx, syn, e.body)?;
	return z;
};

fn switch_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::switch_expr,
) (size | io::error) = {
	let z = syn(ctx, "switch", synkind::KEYWORD)?;
	z += space(ctx)?;
	if (e.label != "") {
		z += syn(ctx, ":", synkind::LABEL)?;
		z += syn(ctx, e.label, synkind::LABEL)?;
		z += space(ctx)?;
	};
	z += syn(ctx, "(", synkind::PUNCTUATION)?;
	z += _expr(ctx, syn, e.value)?;
	z += syn(ctx, ")", synkind::PUNCTUATION)?;
	z += space(ctx)?;
	z += syn(ctx, "{", synkind::PUNCTUATION)?;

	for (let item .. e.cases) {
		z += newline(ctx)?;
		z += syn(ctx, "case", synkind::KEYWORD)?;
		z += space(ctx)?;
		if (len(item.options) == 0) {
			z += syn(ctx, "=>", synkind::OPERATOR)?;
		} else {
			for (let j = 0z; j < len(item.options); j += 1) {
				const opt = item.options[j];
				z += _expr(ctx, syn, opt)?;
				if (j + 1 < len(item.options)) {
					z += syn(ctx, ",",
						synkind::PUNCTUATION)?;
					z += space(ctx)?;
				};
			};
			z += space(ctx)?;
			z += syn(ctx, "=>", synkind::OPERATOR)?;
		};
		z += case_exprs(ctx, syn, item.exprs)?;
	};

	z += newline(ctx)?;
	z += syn(ctx, "}", synkind::PUNCTUATION)?;
	return z;
};

fn match_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::match_expr,
) (size | io::error) = {
	let z = syn(ctx, "match", synkind::KEYWORD)?;
	z += space(ctx)?;
	if (e.label != "") {
		z += syn(ctx, ":", synkind::LABEL)?;
		z += syn(ctx, e.label, synkind::LABEL)?;
		z += space(ctx)?;
	};
	z += syn(ctx, "(", synkind::PUNCTUATION)?;
	z += _expr(ctx, syn, e.value)?;
	z += syn(ctx, ")", synkind::PUNCTUATION)?;
	z += space(ctx)?;
	z += syn(ctx, "{", synkind::PUNCTUATION)?;

	for (let item .. e.cases) {
		z += newline(ctx)?;
		z += syn(ctx, "case", synkind::KEYWORD)?;
		if (len(item.name) > 0) {
			z += space(ctx)?;
			z += syn(ctx, "let", synkind::KEYWORD)?;
			z += space(ctx)?;
			z += syn(ctx, item.name, synkind::IDENT)?;
		};
		match (item._type) {
		case let typ: *ast::_type =>
			if (len(item.name) > 0) {
				z += syn(ctx, ":", synkind::PUNCTUATION)?;
			};
			z += space(ctx)?;
			z += __type(ctx, syn, typ)?;
		case null => void;
		};
		z += space(ctx)?;
		z += syn(ctx, "=>", synkind::OPERATOR)?;
		z += case_exprs(ctx, syn, item.exprs)?;
	};

	z += newline(ctx)?;
	z += syn(ctx, "}", synkind::PUNCTUATION)?;
	return z;
};

fn case_exprs(
	ctx: *context,
	syn: *synfunc,
	exprs: []*ast::expr,
) (size | io::error) = {
	let z = 0z;

	if (len(exprs) == 1) match (exprs[0].expr) {
	case let e: ast::assert_expr =>
		if (e.cond == null) {
			// abort() expression
			z += space(ctx)?;
			z += assert_expr(ctx, syn, &e)?;
			z += syn(ctx, ";", synkind::PUNCTUATION)?;
			return z;
		};
	case let e: ast::value =>
		if (e is void) {
			z += space(ctx)?;
			{
				ctx.stack = &stack {
					cur = exprs[0],
					up = ctx.stack,
					...
				};
				defer ctx.stack = (ctx.stack as *stack).up;
				z += syn(ctx, "void", synkind::KEYWORD)?;
			};
			z += syn(ctx, ";", synkind::PUNCTUATION)?;
			return z;
		};
	case => void;
	};
	ctx.indent += 1;
	for (let expr .. exprs) {
		z += newline(ctx)?;
		z += stmt(ctx, syn, expr)?;
	};
	ctx.indent -= 1;

	return z;
};

fn is_plain(e: *ast::expr) bool = {
	match (e.expr) {
	case ast::literal_expr =>
		return true;
	case ast::access_identifier =>
		return true;
	case =>
		return false;
	};
};

fn is_postfix(e: *ast::expr) bool = {
	if (is_plain(e)) {
		return true;
	};

	match (e.expr) {
	case ast::call_expr =>
		return true;
	case ast::access_expr =>
		return true;
	case ast::slice_expr =>
		return true;
	case ast::error_assert_expr =>
		return true;
	case ast::propagate_expr =>
		return true;
	case =>
		return false;
	};
};

fn is_builtin(e: *ast::expr) bool = {
	if (is_postfix(e)) {
		return true;
	};

	match (e.expr) {
	case ast::alloc_expr =>
		return true;
	case ast::assert_expr =>
		return true;
	case ast::variadic_expr =>
		return true;
	// measurement-expression
	case ast::len_expr =>
		return true;
	case ast::align_expr =>
		return true;
	case ast::size_expr =>
		return true;
	case ast::offset_expr =>
		return true;
	// slice-mutation-expression
	case ast::append_expr =>
		return true;
	case ast::insert_expr =>
		return true;
	case =>
		return false;
	};
};

fn is_unary(e: *ast::expr) bool = {
	if (is_builtin(e)) {
		return true;
	};

	match (e.expr) {
	case ast::compound_expr =>
		return true;
	case ast::match_expr =>
		return true;
	case ast::switch_expr =>
		return true;
	case ast::unarithm_expr =>
		return true;
	case =>
		return false;
	};
};

fn is_cast(e: *ast::expr) bool = {
	return is_unary(e) || (e.expr is ast::cast_expr);
};

fn assert_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::assert_expr,
) (size | io::error) = {
	let z = 0z;
	if (e.is_static) {
		z += syn(ctx, "static", synkind::KEYWORD)?;
		z += space(ctx)?;
	};
	// assert without a condition = abort
	match (e.cond) {
	case let e: *ast::expr =>
		z += syn(ctx, "assert", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
		z += _expr(ctx, syn, e)?;
	case null =>
		z += syn(ctx, "abort", synkind::KEYWORD)?;
		z += syn(ctx, "(", synkind::PUNCTUATION)?;
	};
	match (e.message) {
	case let m: *ast::expr =>
		match (e.cond) {
		case null => void;
		case *ast::expr =>
			z += syn(ctx, ",", synkind::PUNCTUATION)?;
			z += space(ctx)?;
		};
		z += _expr(ctx, syn, m)?;
	case null => void;
	};
	z += syn(ctx, ")", synkind::PUNCTUATION)?;
	return z;
};

fn append_insert_expr(
	ctx: *context,
	syn: *synfunc,
	e: *ast::expr,
) (size | io::error) = {
	let z = 0z;
	const e: *ast::append_expr = match (e.expr) {
	case let e: ast::append_expr =>
		if (e.is_static) {
			z += syn(ctx, "static", synkind::KEYWORD)?;
			z += space(ctx)?;
		};
		z += syn(ctx, "append", synkind::KEYWORD)?;
		yield &e;
	case let e: ast::insert_expr =>
		if (e.is_static) {
			z += syn(ctx, "static", synkind::KEYWORD)?;
			z += space(ctx)?;
		};
		z += syn(ctx, "insert", synkind::KEYWORD)?;
		yield &e;
	case => abort(); // unreachable
	};
	z += syn(ctx, "(", synkind::PUNCTUATION)?;
	z += _expr(ctx, syn, e.object)?;
	z += syn(ctx, ",", synkind::PUNCTUATION)?;
	z += space(ctx)?;
	z += _expr(ctx, syn, e.value)?;
	if (e.variadic) {
		z += syn(ctx, "...", synkind::OPERATOR)?;
	};
	match (e.length) {
	case null => void;
	case let l: *ast::expr =>
		z += syn(ctx, ",", synkind::PUNCTUATION)?;
		z += space(ctx)?;
		z += _expr(ctx, syn, l)?;
	};
	z += syn(ctx, ")", synkind::PUNCTUATION)?;
	return z;
};
