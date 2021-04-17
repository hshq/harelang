use io;
use fmt;
use hare::ast;
use hare::lex;

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
		e: ast::alloc_expr => abort(),
		e: ast::append_expr => abort(),
		e: ast::assert_expr => abort(),
		e: ast::assign_expr => abort(),
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
		e: []ast::binding_expr => abort(),
		e: ast::break_expr => {
			let z = fmt::fprint(out, "break")?;
			// TODO: https://todo.sr.ht/~sircmpwn/hare/380
			let l = e: ast::label: str;
			if (l != "") {
				z += fmt::fprintf(out, " :{}", l)?;
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
			// TODO: https://todo.sr.ht/~sircmpwn/hare/380
			let l = e: ast::label: str;
			if (l != "") {
				z += fmt::fprintf(out, " :{}", l)?;
			};
			z;
		},
		e: ast::defer_expr => abort(),
		e: ast::delete_expr => abort(),
		e: ast::for_expr => abort(),
		e: ast::free_expr => abort(),
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
		e: ast::len_expr => abort(),
		e: ast::size_expr => abort(),
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
		e: ast::switch_expr => abort(),
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
		ast::struct_constant => abort(), // TODO
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
