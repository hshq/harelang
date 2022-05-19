// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use io;
use fmt;
use hare::ast;
use hare::ast::{binarithm_op};
use hare::lex::{ltok};
use hare::lex;
use strings;

// Unparses a [[hare::ast::expr]].
export fn expr(
	out: io::handle,
	indent: size,
	e: ast::expr
) (size | io::error) = {
	match (e.expr) {
	case let e: ast::access_expr =>
		match (e) {
		case let id: ast::access_identifier =>
			return ident(out, id);
		case let ix: ast::access_index =>
			let z = expr(out, indent, *ix.object)?;
			z += fmt::fprintf(out, "[")?;
			z += expr(out, indent, *ix.index)?;
			z += fmt::fprintf(out, "]")?;
			return z;
		case let fi: ast::access_field =>
			let z = expr(out, indent, *fi.object)?;
			z += fmt::fprintf(out, ".{}", fi.field)?;
			return z;
		case let tp: ast::access_tuple =>
			let z = expr(out, indent, *tp.object)?;
			z += fmt::fprintf(out, ".")?;
			z += expr(out, indent, *tp.value)?;
			return z;
		};
	case let e: ast::alloc_expr =>
		let z = fmt::fprint(out, "alloc(")?;
		z += expr(out, indent, *e.init)?;
		match (e.capacity) {
		case null =>
			if (e.form == ast::alloc_form::COPY) {
				z += fmt::fprint(out, "...")?;
			};
		case let e: *ast::expr =>
			z += fmt::fprint(out, ", ")?;
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::append_expr =>
		let z = if (e.is_static) fmt::fprint(out, "static ")? else 0z;
		z += fmt::fprint(out, "append(")?;
		z += expr(out, indent, *e.object)?;
		z += fmt::fprint(out, ", ")?;
		for (let i = 0z; i < len(e.values); i += 1) {
			let val = e.values[i];
			z += expr(out, indent, *val)?;
			if (i + 1 < len(e.values)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		match (e.variadic) {
		case null => void;
		case let v: *ast::expr =>
			if (len(e.values) != 0) {
				z += fmt::fprint(out, ", ")?;
			};
			z += expr(out, indent, *v)?;
			z += fmt::fprint(out, "...")?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::assert_expr =>
		let z = fmt::fprint(
			out, if (e.is_static) "static " else "")?;
		// assert without a condition = abort
		z += match (e.cond) {
		case let e: *ast::expr =>
			yield fmt::fprint(out, "assert(")? +
				expr(out, indent, *e)?;
		case null =>
			yield fmt::fprint(out, "abort(")?;
		};
		z += match (e.message) {
		case let m: *ast::expr =>
			let z = 0z;
			match (e.cond) {
			case null => void;
			case *ast::expr =>
				z += fmt::fprint(out, ", ")?;
			};
			z += expr(out, indent, *m)?;
			yield z;
		case null =>
			yield 0;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::assign_expr =>
		let z = 0z;
		if (e.indirect) {
			z += fmt::fprint(out, "*")?;
		};
		z += expr(out, indent, *e.object)?;
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
			};
		};
		z += fmt::fprintf(out, " {} ", op)?;
		z += expr(out, indent, *e.value)?;
		return z;
	case let e: ast::binarithm_expr =>
		const prec = binprecedence(e.op);
		let z = binexprval(out, indent, *e.lvalue, prec)?;
		z += fmt::fprintf(out, " {} ", switch (e.op) {
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
		})?;
		z += binexprval(out, indent, *e.rvalue, prec)?;
		return z;
	case let e: ast::binding_expr =>
		let z = fmt::fprintf(out, "{}{}",
			if (e.is_static) "static " else "",
			if (e.is_const) "const " else "let ")?;
		for (let i = 0z; i < len(e.bindings); i += 1) {
			let binding = e.bindings[i];
			z += match (binding._type) {
			case null =>
				yield fmt::fprint(out, binding.name)?;
			case let t: *ast::_type =>
				let z = 0z;
				z += fmt::fprintf(out, "{}: ",
					binding.name)?;
				z += _type(out, indent, *t)?;
				yield z;
			};
			z += fmt::fprint(out, " = ")?;
			z += expr(out, indent, *binding.init)?;
			if (i + 1 < len(e.bindings)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		return z;
	case let e: ast::break_expr =>
		let z = fmt::fprint(out, "break")?;
		if (e != "") {
			z += fmt::fprintf(out, " :{}", e)?;
		};
		return z;
	case let e: ast::call_expr =>
		let z = expr(out, indent, *e.lvalue)?;
		z += fmt::fprintf(out, "(")?;
		for (let i = 0z; i < len(e.args); i += 1) {
			z += expr(out, indent, *e.args[i])?;
			if (i + 1 < len(e.args)) {
				z += fmt::fprintf(out, ", ")?;
			};
		};
		if (e.variadic) {
			z += fmt::fprintf(out, "...")?;
		};
		z += fmt::fprintf(out, ")")?;
		return z;
	case let e: ast::cast_expr =>
		let z = expr(out, indent, *e.value)?;
		const op = switch (e.kind) {
		case ast::cast_kind::CAST =>
			yield ": ";
		case ast::cast_kind::ASSERTION =>
			yield " as ";
		case ast::cast_kind::TEST =>
			yield " is ";
		};
		z += fmt::fprintf(out, "{}", op)?;
		z += _type(out, indent, *e._type)?;
		return z;
	case let e: ast::constant_expr =>
		return constant(out, indent, e)?;
	case let e: ast::continue_expr =>
		let z = fmt::fprint(out, "continue")?;
		if (e != "") {
			z += fmt::fprintf(out, " :{}", e)?;
		};
		return z;
	case let e: ast::defer_expr =>
		return fmt::fprint(out, "defer ")? + expr(out, indent, *e)?;
	case let e: ast::delete_expr =>
		let z = if (e.is_static) fmt::fprint(out, "static ")? else 0z;
		z += fmt::fprint(out, "delete(")?;
		z += expr(out, indent, *e.object)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::for_expr =>
		return for_expr(out, indent, e)?;
	case let e: ast::free_expr =>
		return fmt::fprint(out, "free(")?
			+ expr(out, indent, *e)?
			+ fmt::fprint(out, ")")?;
	case let e: ast::if_expr =>
		let z = fmt::fprint(out, "if (")?;
		z += expr(out, indent, *e.cond)?;
		z += fmt::fprint(out, ") ")?;
		z += expr(out, indent, *e.tbranch)?;
		match (e.fbranch) {
		case null => void;
		case let e: *ast::expr =>
			z += fmt::fprint(out, " else ")?;
			z += expr(out, indent, *e)?;
		};
		return z;
	case let e: ast::insert_expr =>
		let z = if (e.is_static) fmt::fprint(out, "static ")? else 0z;
		z += fmt::fprint(out, "insert(")?;
		z += expr(out, indent, *e.object)?;
		z += fmt::fprint(out, ", ")?;
		for (let i = 0z; i < len(e.values); i += 1) {
			let val = e.values[i];
			z += expr(out, indent, *val)?;
			if (i + 1 < len(e.values)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		match (e.variadic) {
		case null => void;
		case let v: *ast::expr =>
			if (len(e.values) != 0) {
				z += fmt::fprint(out, ", ")?;
			};
			z += expr(out, indent, *v)?;
			z += fmt::fprint(out, "...")?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::compound_expr =>
		let z = 0z;
		if (e.label != "") {
			z += fmt::fprintf(out, ":{} ", e.label)?;
		};
		z += fmt::fprintf(out, "{{")?;
		for (let i = 0z; i < len(e.exprs); i += 1) {
			z += newline(out, indent + 1)?;
			z += stmt(out, indent + 1, *e.exprs[i])?;
		};
		z += newline(out, indent)?;
		z += fmt::fprintf(out, "}}")?;
		return z;
	case let e: ast::match_expr =>
		return match_expr(out, indent, e)?;
	case let e: ast::len_expr =>
		let z = fmt::fprint(out, "len(")?;
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::size_expr =>
		let z = fmt::fprint(out, "size(")?;
		z += _type(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::offset_expr =>
		let z = fmt::fprint(out, "offset(")?;
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case let e: ast::propagate_expr =>
		let z = expr(out, indent, *e.expr)?;
		z += fmt::fprintf(out, if (e.is_abort) "!" else "?")?;
		return z;
	case let e: ast::return_expr =>
		let z = fmt::fprint(out, "return")?;
		match (e) {
		case null => void;
		case let e: *ast::expr =>
			z += fmt::fprint(out, " ")?;
			z += expr(out, indent, *e)?;
		};
		return z;
	case let e: ast::slice_expr =>
		let z = expr(out, indent, *e.object)?;
		z += fmt::fprint(out, "[")?;
		match (e.start) {
		case null => void;
		case let e: *ast::expr =>
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, "..")?;
		match (e.end) {
		case null => void;
		case let e: *ast::expr =>
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, "]")?;
		return z;
	case let e: ast::switch_expr =>
		return switch_expr(out, indent, e)?;
	case let e: ast::unarithm_expr =>
		let z = fmt::fprintf(out, "{}", switch (e.op) {
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
		case ast::unarithm_op::PLUS =>
			yield "+";
		})?;
		z += expr(out, indent, *e.operand)?;
		return z;
	case let e: ast::variadic_expr =>
		match (e) {
		case ast::vastart_expr =>
			return fmt::fprint(out, "vastart()")?;
		case let e: ast::vaarg_expr =>
			let z = fmt::fprint(out, "vaarg(")?;
			z += expr(out, indent, *e)?;
			z += fmt::fprint(out, ")")?;
			return z;
		case let e: ast::vaend_expr =>
			let z = fmt::fprint(out, "vaend(")?;
			z += expr(out, indent, *e)?;
			z += fmt::fprint(out, ")")?;
			return z;
		};
	case let e: ast::yield_expr =>
		let z = fmt::fprint(out, "yield")?;
		if (e.label != "") {
			z += fmt::fprintf(out, " :{}", e.label)?;
		};
		match (e.value) {
		case null => void;
		case let v: *ast::expr =>
			z += fmt::fprint(out, if (e.label == "")
				" " else ", ")?;
			z += expr(out, indent, *v)?;
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
	out: io::handle,
	indent: size,
	e: ast::expr,
	prec: uint,
) (size | io::error) = {
	let z = 0z;
	match (e.expr) {
	case let b: ast::binarithm_expr =>
		if (binprecedence(b.op) < prec) {
			z += fmt::fprint(out, "(")?;
			z += expr(out, indent, e)?;
			z += fmt::fprint(out, ")")?;
			return z;
		};
	case => void;
	};
	z += expr(out, indent, e)?;
	return z;
};

fn stmt(
	out: io::handle,
	indent: size,
	e: ast::expr
) (size | io::error) = {
	let n = 0z;
	n += expr(out, indent, e)?;
	n += fmt::fprint(out, ";")?;
	return n;
};

fn constant(
	out: io::handle,
	indent: size,
	e: ast::constant_expr,
) (size | io::error) = {
	match (e) {
	case void =>
		return fmt::fprint(out, "void");
	case let v: ast::value =>
		return fmt::fprint(out, match (v) {
		case void => abort();
		case ast::_null =>
			yield "null";
		case let b: bool =>
			return fmt::fprint(out, b);
		case let s: str =>
			const s = strings::multireplace(s,
				(`\`, `\\`), (`"`, `\"`));
			defer free(s);
			return fmt::fprintf(out, `"{}"`, s);
		case let r: rune =>
			if (r == '\'' || r == '\\') {
				return fmt::fprintf(out, `'\{}'`, r);
			} else {
				return fmt::fprintf(out, "'{}'", r);
			};
		});
	case let ac: ast::array_constant =>
		let z = fmt::fprint(out, "[")?;
		for (let i = 0z; i < len(ac.values); i += 1) {
			z += expr(out, indent, *ac.values[i])?;
			if (i + 1 < len(ac.values)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		z += fmt::fprintf(out, "{}]",
			if (ac.expand) "..." else "")?;
		return z;
	case let v: ast::number_constant =>
		return fmt::fprintf(out, "{}{}", v.value, switch (v.suff) {
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
	case let sc: ast::struct_constant =>
		return struct_constant(out, indent, sc)?;
	case let tu: ast::tuple_constant =>
		let z = fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(tu); i += 1) {
			z += expr(out, indent, *tu[i])?;
			if (i + 1 < len(tu)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		z += fmt::fprint(out, ")")?;
		return z;
	};
};

fn struct_constant(
	out: io::handle,
	indent: size,
	sc: ast::struct_constant,
) (size | io::error) = {
	let z = 0z;
	z += if (len(sc.alias) != 0) {
		yield ident(out, sc.alias)?;
	} else {
		yield fmt::fprint(out, "struct")?;
	};
	z += fmt::fprint(out, " {")?;
	indent += 1;
	for (let i = 0z; i < len(sc.fields); i += 1) {
		z += newline(out, indent)?;
		match (sc.fields[i]) {
		case let sv: ast::struct_value =>
			match (sv._type) {
			case null =>
				z += fmt::fprintf(out, "{}", sv.name)?;
			case let t: *ast::_type =>
				z += fmt::fprintf(out, "{}: ", sv.name)?;
				z += _type(out, indent, *t)?;
			};
			z += fmt::fprint(out, " = ")?;
			z += expr(out, indent, *sv.init)?;
		case let sc: *ast::struct_constant =>
			z += constant(out, indent, *sc)?;
		};
		z += fmt::fprint(out, ",")?;
	};
	if (sc.autofill) {
		z += newline(out, indent)?;
		z += fmt::fprint(out, "...")?;
	};
	indent -= 1;
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

fn for_expr(
	out: io::handle,
	indent: size,
	e: ast::for_expr,
) (size | io::error) = {
	let z = fmt::fprintf(out, "for (")?;
	match (e.bindings) {
	case null => void;
	case let e: *ast::expr =>
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, "; ")?;
	};

	z += expr(out, indent, *e.cond)?;

	match (e.afterthought) {
	case null => void;
	case let e: *ast::expr =>
		z += fmt::fprint(out, "; ")?;
		z += expr(out, indent, *e)?;
	};

	z += fmt::fprintf(out, ") ")?;
	return z + expr(out, indent, *e.body)?;
};

fn switch_expr(
	out: io::handle,
	indent: size,
	e: ast::switch_expr,
) (size | io::error) = {
	let z = fmt::fprint(out, "switch (")?;
	z += expr(out, indent, *e.value)?;
	z += fmt::fprint(out, ") {")?;

	for (let i = 0z; i < len(e.cases); i += 1) {
		z += newline(out, indent)?;
		const item = e.cases[i];
		z += fmt::fprint(out, "case ")?;
		if (len(item.options) == 0) {
			z += fmt::fprint(out, "=>")?;
		} else {
			for (let j = 0z; j < len(item.options); j += 1) {
				const opt = item.options[j];
				z += expr(out, indent, *opt)?;
				if (j + 1 < len(item.options)) {
					z += fmt::fprint(out, ", ")?;
				};
			};
			z += fmt::fprint(out, " =>")?;
		};
		z += case_exprs(out, indent + 1, item.exprs)?;
	};

	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

fn match_expr(
	out: io::handle,
	indent: size,
	e: ast::match_expr,
) (size | io::error) = {
	let z = fmt::fprint(out, "match (")?;
	z += expr(out, indent, *e.value)?;
	z += fmt::fprint(out, ") {")?;

	for (let i = 0z; i < len(e.cases); i += 1) {
		z += newline(out, indent)?;
		z += fmt::fprint(out, "case")?;
		const item = e.cases[i];
		if (len(item.name) > 0) {
			z += fmt::fprintf(out, " let {}", item.name)?;
		};
		match (item._type) {
		case let typ: *ast::_type =>
			if (len(item.name) > 0) {
				z += fmt::fprint(out, ":")?;
			};
			z += fmt::fprint(out, " ")?;
			z += _type(out, indent, *typ)?;
		case null => void;
		};
		z += fmt::fprint(out, " =>")?;
		z += case_exprs(out, indent + 1, item.exprs)?;
	};

	if (len(e.default) != 0) {
		z += newline(out, indent)?;
		z += fmt::fprint(out, "case =>")?;
		z += case_exprs(out, indent + 1, e.default)!;
	};

	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

fn case_exprs(
	out: io::handle,
	indent: size,
	exprs: []*ast::expr,
) (size | io::error) = {
	let z = 0z;

	if (len(exprs) == 1) match (exprs[0].expr) {
	case let e: ast::assert_expr =>
		if (e.cond == null) {
			// abort() expression
			z += fmt::fprint(out, " ")?;
			z += stmt(out, indent, *exprs[0])?;
			return z;
		};
	case let e: ast::value =>
		if (e is void) return fmt::fprint(out, " void;")?;
	case => void;
	};
	for (let j = 0z; j < len(exprs); j += 1) {
		z += newline(out, indent)?;
		z += stmt(out, indent, *exprs[j])?;
	};

	return z;
};
