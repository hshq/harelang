use io;
use fmt;
use hare::ast;
use hare::lex;

// Unparses an [[ast::expr]].
//
// A known limitation of the current implementation is that precedence between
// binary operators (e.g. +) is not accounted for, so such expressions may
// produce a different AST if parsed again.
export fn expr(
	out: io::handle,
	indent: size,
	e: ast::expr
) (size | io::error) = {
	match (e.expr) {
	case e: ast::access_expr =>
		match (e) {
		case id: ast::access_identifier =>
			return ident(out, id);
		case ix: ast::access_index =>
			let z = expr(out, indent, *ix.object)?;
			z += fmt::fprintf(out, "[")?;
			z += expr(out, indent, *ix.index)?;
			z += fmt::fprintf(out, "]")?;
			return z;
		case fi: ast::access_field =>
			let z = expr(out, indent, *fi.object)?;
			z += fmt::fprintf(out, ".{}", fi.field)?;
			return z;
		case tp: ast::access_tuple =>
			let z = expr(out, indent, *tp.object)?;
			z += fmt::fprintf(out, ".")?;
			z += expr(out, indent, *tp.value)?;
			return z;
		};
	case e: ast::alloc_expr =>
		let z = fmt::fprint(out, "alloc(")?;
		z += expr(out, indent, *e.init)?;
		match (e.capacity) {
		case null => void;
		case e: *ast::expr =>
			z += fmt::fprint(out, ", ")?;
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::append_expr =>
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
		case v: *ast::expr =>
			if (len(e.values) != 0) {
				z += fmt::fprint(out, ", ")?;
			};
			z += expr(out, indent, *v)?;
			z += fmt::fprint(out, "...")?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::assert_expr =>
		let z = fmt::fprint(
			out, if (e.is_static) "static " else "")?;
		// assert without a condition = abort
		z += match (e.cond) {
		case e: *ast::expr =>
			yield fmt::fprint(out, "assert(")? +
				expr(out, indent, *e)?;
		case null =>
			yield fmt::fprint(out, "abort(")?;
		};
		z += match (e.message) {
		case m: *ast::expr =>
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
	case e: ast::assign_expr =>
		let z = 0z;
		if (e.indirect) {
			z += fmt::fprint(out, "*")?;
		};
		z += expr(out, indent, *e.object)?;
		const op = match (e.op) {
		case void =>
			yield "=";
		case op: ast::binarithm_op =>
			yield switch (op) {
			case ast::binarithm_op::BAND =>
				yield "&=";
			case ast::binarithm_op::LAND =>
				yield "&&=";
			case ast::binarithm_op::BOR =>
				yield "|=";
			case ast::binarithm_op::LOR =>
				yield "||=";
			case ast::binarithm_op::DIV =>
				yield "/=";
			case ast::binarithm_op::LSHIFT =>
				yield "<<=";
			case ast::binarithm_op::MINUS =>
				yield "-=";
			case ast::binarithm_op::MODULO =>
				yield "%=";
			case ast::binarithm_op::PLUS =>
				yield "+=";
			case ast::binarithm_op::RSHIFT =>
				yield ">>=";
			case ast::binarithm_op::TIMES =>
				yield "*=";
			case ast::binarithm_op::BXOR =>
				yield "^=";
			case ast::binarithm_op::LXOR =>
				yield "^^=";
			};
		};
		z += fmt::fprintf(out, " {} ", op)?;
		z += expr(out, indent, *e.value)?;
		return z;
	case e: ast::binarithm_expr =>
		let z = expr(out, indent, *e.lvalue)?;
		z += fmt::fprintf(out, " {} ", switch (e.op) {
		case ast::binarithm_op::BAND =>
			yield "&";
		case ast::binarithm_op::BOR =>
			yield "|";
		case ast::binarithm_op::DIV =>
			yield "/";
		case ast::binarithm_op::GT =>
			yield ">";
		case ast::binarithm_op::GTEQ =>
			yield ">=";
		case ast::binarithm_op::LAND =>
			yield "&&";
		case ast::binarithm_op::LEQUAL =>
			yield "==";
		case ast::binarithm_op::LESS =>
			yield "<";
		case ast::binarithm_op::LESSEQ =>
			yield "<=";
		case ast::binarithm_op::LOR =>
			yield "||";
		case ast::binarithm_op::LSHIFT =>
			yield "<<";
		case ast::binarithm_op::LXOR =>
			yield "^^";
		case ast::binarithm_op::MINUS =>
			yield "-";
		case ast::binarithm_op::MODULO =>
			yield "%";
		case ast::binarithm_op::NEQUAL =>
			yield "!=";
		case ast::binarithm_op::PLUS =>
			yield "+";
		case ast::binarithm_op::RSHIFT =>
			yield ">>";
		case ast::binarithm_op::TIMES =>
			yield "*";
		case ast::binarithm_op::BXOR =>
			yield "^";
		})?;
		z += expr(out, indent, *e.rvalue)?;
		return z;
	case e: ast::binding_expr =>
		let z = fmt::fprintf(out, "{}{}",
			if (e.is_static) "static " else "",
			if (e.is_const) "const " else "let ")?;
		for (let i = 0z; i < len(e.bindings); i += 1) {
			let binding = e.bindings[i];
			z += match (binding._type) {
			case null =>
				yield fmt::fprint(out, binding.name)?;
			case t: *ast::_type =>
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
	case e: ast::break_expr =>
		let z = fmt::fprint(out, "break")?;
		if (e != "") {
			z += fmt::fprintf(out, " :{}", e)?;
		};
		return z;
	case e: ast::call_expr =>
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
	case e: ast::cast_expr =>
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
	case e: ast::constant_expr =>
		return constant(out, indent, e)?;
	case e: ast::continue_expr =>
		let z = fmt::fprint(out, "continue")?;
		if (e != "") {
			z += fmt::fprintf(out, " :{}", e)?;
		};
		return z;
	case e: ast::defer_expr =>
		return fmt::fprint(out, "defer ")? + expr(out, indent, *e)?;
	case e: ast::delete_expr =>
		let z = if (e.is_static) fmt::fprint(out, "static ")? else 0z;
		z += fmt::fprint(out, "delete(")?;
		z += expr(out, indent, *e.object)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::for_expr =>
		return for_expr(out, indent, e)?;
	case e: ast::free_expr =>
		return fmt::fprint(out, "free(")?
			+ expr(out, indent, *e)?
			+ fmt::fprint(out, ")")?;
	case e: ast::if_expr =>
		let z = fmt::fprint(out, "if (")?;
		z += expr(out, indent, *e.cond)?;
		z += fmt::fprint(out, ") ")?;
		z += expr(out, indent, *e.tbranch)?;
		match (e.fbranch) {
		case null => void;
		case e: *ast::expr =>
			z += fmt::fprint(out, " else ")?;
			z += expr(out, indent, *e)?;
		};
		return z;
	case e: ast::insert_expr =>
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
		case v: *ast::expr =>
			if (len(e.values) != 0) {
				z += fmt::fprint(out, ", ")?;
			};
			z += expr(out, indent, *v)?;
			z += fmt::fprint(out, "...")?;
		};
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::compound_expr =>
		let z = 0z;
		if (e.label != "") {
			z += fmt::fprintf(out, ":{} ", e.label)?;
		};
		z += fmt::fprintf(out, "{{")?;
		for (let i = 0z; i < len(e.exprs); i += 1) {
			z += newline(out, indent + 1)?;
			z += expr(out, indent + 1, *e.exprs[i])?;
			z += fmt::fprintf(out, ";")?;
		};
		z += newline(out, indent)?;
		z += fmt::fprintf(out, "}}")?;
		return z;
	case e: ast::match_expr =>
		return match_expr(out, indent, e)?;
	case e: ast::len_expr =>
		let z = fmt::fprint(out, "len(")?;
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::size_expr =>
		let z = fmt::fprint(out, "size(")?;
		z += _type(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::offset_expr =>
		let z = fmt::fprint(out, "offset(")?;
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, ")")?;
		return z;
	case e: ast::propagate_expr =>
		let z = expr(out, indent, *e.expr)?;
		z += fmt::fprintf(out, if (e.is_abort) "!" else "?")?;
		return z;
	case e: ast::return_expr =>
		let z = fmt::fprint(out, "return")?;
		match (e) {
		case null => void;
		case e: *ast::expr =>
			z += fmt::fprint(out, " ")?;
			z += expr(out, indent, *e)?;
		};
		return z;
	case e: ast::slice_expr =>
		let z = expr(out, indent, *e.object)?;
		z += fmt::fprint(out, "[")?;
		match (e.start) {
		case null => void;
		case e: *ast::expr =>
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, "..")?;
		match (e.end) {
		case null => void;
		case e: *ast::expr =>
			z += expr(out, indent, *e)?;
		};
		z += fmt::fprint(out, "]")?;
		return z;
	case e: ast::switch_expr =>
		return switch_expr(out, indent, e)?;
	case e: ast::unarithm_expr =>
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
	case e: ast::yield_expr =>
		let z = fmt::fprint(out, "yield")?;
		if (e.label != "") {
			z += fmt::fprintf(out, " :{}", e.label)?;
		};
		match (e.value) {
		case null => void;
		case v: *ast::expr =>
			z += fmt::fprint(out, if (e.label == "")
				" " else ", ")?;
			z += expr(out, indent, *v)?;
		};
		return z;
	};
};

fn constant(
	out: io::handle,
	indent: size,
	e: ast::constant_expr,
) (size | io::error) = {
	match (e) {
	case void =>
		return fmt::fprint(out, "void");
	case v: ast::value =>
		return fmt::fprint(out, match (v) {
		case void => abort();
		case ast::_null =>
			yield "null";
		case v: (i64 | u64 | f64) =>
			yield v;
		case b: bool =>
			return fmt::fprint(out, b);
		// TODO: Escape these:
		case s: str =>
			return fmt::fprintf(out, "\"{}\"", s);
		case r: rune =>
			return fmt::fprintf(out, "'{}'", r);
		});
	case ac: ast::array_constant =>
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
	case sc: ast::struct_constant =>
		return struct_constant(out, indent, sc)?;
	case tu: ast::tuple_constant =>
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
		newline(out, indent)?;
		match (sc.fields[i]) {
		case sv: ast::struct_value =>
			match (sv._type) {
			case null =>
				z += fmt::fprintf(out, "{}", sv.name)?;
			case t: *ast::_type =>
				z += fmt::fprintf(out, "{}: ", sv.name)?;
				z += _type(out, indent, *t)?;
			};
			z += fmt::fprint(out, " = ")?;
			z += expr(out, indent, *sv.init)?;
		case sc: *ast::struct_constant =>
			z += constant(out, indent, *sc)?;
		};
		z += fmt::fprint(out, ",")?;
	};
	if (sc.autofill) {
		newline(out, indent)?;
		fmt::fprint(out, "...")?;
	};
	indent -= 1;
	newline(out, indent)?;
	fmt::fprint(out, "}")?;
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
	case e: *ast::expr =>
		z += expr(out, indent, *e)?;
		z += fmt::fprint(out, "; ")?;
	};

	z += expr(out, indent, *e.cond)?;

	match (e.afterthought) {
	case null => void;
	case e: *ast::expr =>
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
	indent += 1;

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
		for (let j = 0z; j < len(item.exprs); j += 1) {
			z += newline(out, indent + 1)?;
			z += expr(out, indent + 1, *item.exprs[j])?;
			z += fmt::fprint(out, ";")?;
		};
	};

	indent -= 1;
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
		z += fmt::fprint(out, "case ")?;
		const item = e.cases[i];
		if (len(item.name) > 0) {
			z += fmt::fprintf(out, "{}: ", item.name)?;
		};
		z += _type(out, indent, *item._type)?;
		z += fmt::fprint(out, " =>")?;
		for (let i = 0z; i < len(item.exprs); i += 1) {
			z += newline(out, indent + 1)?;
			z += expr(out, indent + 1, *item.exprs[i])?;
			z += fmt::fprint(out, ";")?;
		};
	};

	if (len(e.default) != 0) {
		z += newline(out, indent)?;
		z += fmt::fprint(out, "case =>")?;
		for (let i = 0z; i < len(e.default); i += 1) {
			z += newline(out, indent + 1)?;
			z += expr(out, indent + 1, *e.default[i])?;
			z += fmt::fprint(out, ";")?;
		};
	};

	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};
