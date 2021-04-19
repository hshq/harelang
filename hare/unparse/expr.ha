use io;
use fmt;
use hare::ast;
use hare::lex;

// Unparses an [ast::expr].
//
// A known limitation of the current implementation is that precedence between
// binary operators (e.g. +) is not accounted for, so such expressions may
// produce a different AST if parsed again.
export fn expr(
	out: *io::stream,
	indent: size,
	t: ast::expr
) (size | io::error) = {
	return match (t) {
		e: ast::access_expr => match (e) {
			id: ast::access_identifier => ident(out, id),
			ix: ast::access_index => {
				let z = expr(out, indent, *ix.object)?;
				z += fmt::fprintf(out, "[")?;
				z += expr(out, indent, *ix.index)?;
				z += fmt::fprintf(out, "]")?;
				z;
			},
			fi: ast::access_field => {
				let z = expr(out, indent, *fi.object)?;
				z + fmt::fprintf(out, ".{}", fi.field)?;
			},
			tp: ast::access_tuple => {
				let z = expr(out, indent, *tp.object)?;
				z += fmt::fprintf(out, ".")?;
				z + expr(out, indent, *tp.value)?;
			},
		},
		e: ast::alloc_expr => {
			let z = fmt::fprint(out, "alloc(")?;
			z += expr(out, indent, *e.init)?;
			match (e.capacity) {
				null => void,
				e: *ast::expr => {
					z += fmt::fprint(out, ", ")?;
					z += expr(out, indent, *e)?;
				},
			};
			z += fmt::fprint(out, ")")?;
			z;
		},
		e: ast::append_expr => {
			let z = fmt::fprint(out, "append(")?;
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
				null => void,
				e: *ast::expr => {
					z += fmt::fprint(out, ", ")?;
					z += expr(out, indent, *e)?;
					z += fmt::fprint(out, "...")?;
				},
			};
			z + fmt::fprint(out, ")")?;
		},
		e: ast::assert_expr => {
			let z = fmt::fprint(
				out, if (e.is_static) "static " else "")?;
			// assert without a condition = abort
			z += match (e.cond) {
				e: *ast::expr => {
					fmt::fprint(out, "assert(")? +
						expr(out, indent, *e)?;
				},
				null => fmt::fprint(out, "abort(")?,
			};
			z += match (e.message) {
				m: *ast::expr => {
					let z = 0z;
					match (e.cond) {
						*ast::expr => {
							z += fmt::fprint(out, ", ")?;
						},
						null => void,
					};
					z + expr(out, indent, *m)?;
				},
				null => 0,
			};
			z + fmt::fprint(out, ")")?;
		},
		e: ast::assign_expr => {
			let z = 0z;
			if (e.indirect) {
				z += fmt::fprint(out, "*")?;
			};
			z += expr(out, indent, *e.object)?;
			const op = match (e.op) {
				void => "=",
				op: ast::binarithm_op => switch (op) {
					ast::binarithm_op::BAND => "&=",
					ast::binarithm_op::BOR => "|=",
					ast::binarithm_op::DIV => "/=",
					ast::binarithm_op::LSHIFT => "<<=",
					ast::binarithm_op::MINUS => "-=",
					ast::binarithm_op::MODULO => "%=",
					ast::binarithm_op::PLUS	 => "+=",
					ast::binarithm_op::RSHIFT => ">>=",
					ast::binarithm_op::TIMES => "*=",
					ast::binarithm_op::BXOR => "^=",
					* => abort(),
				},
			};
			z += fmt::fprintf(out, " {} ", op)?;
			z += expr(out, indent, *e.value)?;
			z;
		},
		e: ast::binarithm_expr => {
			let z = expr(out, indent, *e.lvalue)?;
			z += fmt::fprintf(out, " {} ", switch (e.op) {
				ast::binarithm_op::BAND		=> "&",
				ast::binarithm_op::BOR		=> "|",
				ast::binarithm_op::DIV		=> "/",
				ast::binarithm_op::GT		=> ">",
				ast::binarithm_op::GTEQ		=> ">=",
				ast::binarithm_op::LAND		=> "&&",
				ast::binarithm_op::LEQUAL	=> "==",
				ast::binarithm_op::LESS		=> "<",
				ast::binarithm_op::LESSEQ	=> "<=",
				ast::binarithm_op::LOR		=> "||",
				ast::binarithm_op::LSHIFT	=> "<<",
				ast::binarithm_op::LXOR		=> "^^",
				ast::binarithm_op::MINUS	=> "-",
				ast::binarithm_op::MODULO	=> "%",
				ast::binarithm_op::NEQUAL	=> "!=",
				ast::binarithm_op::PLUS		=> "+",
				ast::binarithm_op::RSHIFT	=> ">>",
				ast::binarithm_op::TIMES	=> "*",
				ast::binarithm_op::BXOR		=> "^",
			})?;
			z += expr(out, indent, *e.rvalue)?;
			z;
		},
		e: ast::binding_expr => {
			let z = fmt::fprintf(out, "{}{}",
				if (e.is_static) "static " else "",
				if (e.is_const) "const " else "let ")?;
			for (let i = 0z; i < len(e.bindings); i += 1) {
				let binding = e.bindings[i];
				z += match (binding._type) {
					null => fmt::fprint(out, binding.name)?,
					t: *ast::_type => {
						fmt::fprintf(out, "{}: ",
							binding.name)?
						+ _type(out, indent, *t)?;
					},
				};
				z += fmt::fprint(out, " = ")?;
				z += expr(out, indent, *binding.init)?;
				if (i + 1 < len(e.bindings)) {
					z += fmt::fprint(out, ", ")?;
				};
			};
			z;
		},
		e: ast::break_expr => {
			let z = fmt::fprint(out, "break")?;
			if (e != "") {
				z += fmt::fprintf(out, " :{}", e)?;
			};
			z;
		},
		e: ast::call_expr => {
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
			z;
		},
		e: ast::cast_expr => {
			let z = expr(out, indent, *e.value)?;
			const op = switch (e.kind) {
				ast::cast_kind::CAST => ": ",
				ast::cast_kind::ASSERTION => " as ",
				ast::cast_kind::TEST => " is ",
			};
			z += fmt::fprintf(out, "{}", op)?;
			z += _type(out, indent, *e._type)?;
			z;
		},
		e: ast::constant_expr => constant(out, indent, e)?,
		e: ast::continue_expr => {
			let z = fmt::fprint(out, "continue")?;
			if (e != "") {
				z += fmt::fprintf(out, " :{}", e)?;
			};
			z;
		},
		e: ast::defer_expr =>
			fmt::fprint(out, "defer ")? + expr(out, indent, *e)?,
		e: ast::delete_expr =>
			fmt::fprint(out, "delete(")?
			+ expr(out, indent, *e)?
			+ fmt::fprint(out, ")")?,
		e: ast::for_expr => for_expr(out, indent, e)?,
		e: ast::free_expr =>
			fmt::fprint(out, "free(")?
			+ expr(out, indent, *e)?
			+ fmt::fprint(out, ")")?,
		e: ast::if_expr => {
			let z = fmt::fprint(out, "if (")?;
			z += expr(out, indent, *e.cond)?;
			z += fmt::fprint(out, ") ")?;
			z += expr(out, indent, *e.tbranch)?;
			match (e.fbranch) {
				null => void,
				e: *ast::expr => {
					z += fmt::fprint(out, " else ")?;
					z += expr(out, indent, *e)?;
				},
			};
			z;
		},
		e: ast::list_expr => {
			let z = fmt::fprintf(out, "{{")?;
			for (let i = 0z; i < len(e); i += 1) {
				z += newline(out, indent + 1)?;
				z += expr(out, indent + 1, *e[i])?;
				z += fmt::fprintf(out, ";")?;
			};
			z += newline(out, indent)?;
			z += fmt::fprintf(out, "}}")?;
			z;
		},
		e: ast::match_expr => abort(),
		e: ast::len_expr => {
			let z = fmt::fprint(out, "len(")?;
			z += expr(out, indent, *e)?;
			z + fmt::fprint(out, ")")?;
		},
		e: ast::size_expr => {
			let z = fmt::fprint(out, "size(")?;
			z += _type(out, indent, *e)?;
			z + fmt::fprint(out, ")")?;
		},
		e: ast::offset_expr => abort(),
		e: ast::propagate_expr => {
			let z = expr(out, indent, *e)?;
			z + fmt::fprintf(out, "?")?;
		},
		e: ast::return_expr => {
			let z = fmt::fprint(out, "return")?;
			match (e) {
				null => void,
				e: *ast::expr => {
					z += fmt::fprint(out, " ")?;
					z += expr(out, indent, *e)?;
				},
			};
			z;
		},
		e: ast::slice_expr => {
			let z = expr(out, indent, *e.object)?;
			z += fmt::fprint(out, "[")?;
			z += match (e.start) {
				null => 0z,
				e: *ast::expr => expr(out, indent, *e)?,
			};
			z += fmt::fprint(out, "..")?;
			z += match (e.end) {
				null => 0z,
				e: *ast::expr => expr(out, indent, *e)?,
			};
			z += fmt::fprint(out, "]")?;
			z;
		},
		e: ast::switch_expr => switch_expr(out, indent, e)?,
		e: ast::unarithm_expr => {
			let z = fmt::fprintf(out, "{}", switch (e.op) {
				ast::unarithm_op::ADDR	=> "&",
				ast::unarithm_op::BNOT	=> "~",
				ast::unarithm_op::DEREF	=> "*",
				ast::unarithm_op::LNOT	=> "!",
				ast::unarithm_op::MINUS	=> "-",
				ast::unarithm_op::PLUS	=> "+",
			})?;
			z += expr(out, indent, *e.operand)?;
			z;
		},
	};
};

fn constant(
	out: *io::stream,
	indent: size,
	e: ast::constant_expr,
) (size | io::error) = {
	return match (e) {
		void => fmt::fprint(out, "void"),
		ast::_null => fmt::fprint(out, "null"),
		b: bool => fmt::fprint(out, b),
		v: lex::value => fmt::fprint(out, match (v) {
			void => abort(),
			v: (i64 | u64 | f64) => v,
			// TODO: Escape these:
			s: str => return fmt::fprintf(out, "\"{}\"", s),
			r: rune => return fmt::fprintf(out, "'{}'", r),
		}),
		ac: ast::array_constant => {
			let z = fmt::fprint(out, "[")?;
			for (let i = 0z; i < len(ac.values); i += 1) {
				z += expr(out, indent, *ac.values[i])?;
				if (i + 1 < len(ac.values)) {
					z += fmt::fprint(out, ", ")?;
				};
			};
			z + fmt::fprintf(out, "{}]",
				if (ac.expand) "..." else "")?;
		},
		sc: ast::struct_constant => struct_constant(out, indent, sc)?,
		tu: ast::tuple_constant => {
			let z = fmt::fprint(out, "(")?;
			for (let i = 0z; i < len(tu); i += 1) {
				z += expr(out, indent, *tu[i])?;
				if (i + 1 < len(tu)) {
					z += fmt::fprint(out, ", ")?;
				};
			};
			z + fmt::fprint(out, ")")?;
		},
	};
};

fn struct_constant(
	out: *io::stream,
	indent: size,
	sc: ast::struct_constant,
) (size | io::error) = {
	let z = 0z;
	z += if (len(sc.alias) != 0) {
		ident(out, sc.alias)?;
	} else {
		fmt::fprint(out, "struct")?;
	};
	z += fmt::fprint(out, " {")?;
	indent += 1;
	for (let i = 0z; i < len(sc.fields); i += 1) {
		newline(out, indent)?;
		match (sc.fields[i]) {
			sv: ast::struct_value => {
				z += match (sv._type) {
					null => fmt::fprintf(out, "{}", sv.name)?,
					t: *ast::_type =>
						fmt::fprintf(out, "{}: ", sv.name)?
						+ _type(out, indent, *t)?,
				};
				z += fmt::fprint(out, " = ")?;
				z += expr(out, indent, *sv.init)?;
			},
			sc: *ast::struct_constant => {
				z += constant(out, indent, *sc)?;
			},
		};
		z += fmt::fprint(out, ",")?;
	};
	indent -= 1;
	newline(out, indent)?;
	fmt::fprint(out, "}");
	return z;
};

fn for_expr(
	out: *io::stream,
	indent: size,
	e: ast::for_expr,
) (size | io::error) = {
	let z = 0z;
	if (e.label != "") {
		z += fmt::fprintf(out, ":{} ", e.label)?;
	};
	z += fmt::fprintf(out, "for (")?;
	z += match (e.bindings) {
		null => 0z,
		e: *ast::expr => expr(out, indent, *e)?
			+ fmt::fprint(out, "; ")?,
	};
	z += expr(out, indent, *e.cond)?;
	z += match (e.afterthought) {
		null => 0z,
		e: *ast::expr => fmt::fprint(out, "; ")?
			+ expr(out, indent, *e)?,
	};
	z += fmt::fprintf(out, ") ")?;
	return z + expr(out, indent, *e.body)?;
};

fn switch_expr(
	out: *io::stream,
	indent: size,
	e: ast::switch_expr,
) (size | io::error) = {
	let z = fmt::fprint(out, "switch (")?;
	z += expr(out, indent, *e.value)?;
	z += fmt::fprint(out, ") {")?;
	indent += 1;

	for (let i = 0z; i < len(e.cases); i += 1) {
		z += newline(out, indent)?;
		const case = e.cases[i];
		if (len(case.options) == 0) {
			z += fmt::fprint(out, "* => ")?;
		} else {
			for (let j = 0z; j < len(case.options); j += 1) {
				const opt = case.options[j];
				z += expr(out, indent, *opt)?;
				if (j + 1 < len(case.options)) {
					z += fmt::fprint(out, ", ")?;
				};
			};
			z += fmt::fprint(out, " => ")?;
		};
		z += expr(out, indent, *case.value)?;
		z += fmt::fprint(out, ",")?;
	};

	indent -= 1;
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};
