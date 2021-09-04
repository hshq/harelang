use ascii;
use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use io;
use os;
use strings;
use strio;

let firstline: bool = true;

// Formats output as Hare source code (prototypes) with syntax highlighting
fn emit_tty(ctx: *context) (void | error) = {
	const summary = ctx.summary;

	match (ctx.readme) {
		readme: *io::stream => {
			for (true) match (bufio::scanline(readme)?) {
				b: []u8 => {
					firstline = false;
					fmt::printfln(
						"\x1b[1m" "// {}" "\x1b[0m",
						strings::fromutf8(b))?;
					free(b);
				},
				io::EOF => break,
			};
		},
		null => void,
	};

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		details_tty(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		details_tty(ctx, summary.errors[i])?;
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		details_tty(ctx, summary.globals[i])?;
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		details_tty(ctx, summary.funcs[i])?;
	};
};

fn isws(s: str) bool = {
	const iter = strings::iter(s);
	for (true) match (strings::next(&iter)) {
		r: rune => if (!ascii::isspace(r)) {
			return false;
		},
		void => break,
	};
	return true;
};

fn details_tty(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	if (!firstline) {
		fmt::println()?;
	};
	firstline = false;

	const iter = strings::tokenize(decl.docs, "\n");
	for (true) match (strings::next_token(&iter)) {
		s: str => if (!(strings::peek_token(&iter) is void)) {
			fmt::printfln("\x1b[1m" "//{}" "\x1b[0m", s)?;
		},
		void => break,
	};

	unparse_tty(os::stdout, decl)?;
	fmt::println()?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_tty(out: *io::stream, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
		g: []ast::decl_global => {
			n += fmt::fprint(out, "\x1b[34m")?;
			n += fmt::fprint(out,
				if (g[0].is_const) "def " else "let ")?;
			n += fmt::fprint(out, "\x1b[0m")?;
			for (let i = 0z; i < len(g); i += 1) {
				if (len(g[i].symbol) != 0) {
					n += fmt::fprintf(out,
						"\x1b[33m" "@symbol(\"{}\") " "\x1b[0m",
						g[i].symbol)?;
				};
				n += unparse::ident(out, g[i].ident)?;
				n += fmt::fprint(out, ": ")?;
				n += type_tty(out, 0, g[i]._type)?;
				if (i + 1 < len(g)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
		},
		t: []ast::decl_type => {
			n += fmt::fprint(out, "\x1b[34m" "type " "\x1b[0m")?;
			for (let i = 0z; i < len(t); i += 1) {
				n += unparse::ident(out, t[i].ident)?;
				n += fmt::fprint(out, " = ")?;
				n += type_tty(out, 0, t[i]._type)?;
				if (i + 1 < len(t)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
		},
		f: ast::decl_func => {
			n += fmt::fprint(out, "\x1b[33m")?;
			n += fmt::fprint(out, switch (f.attrs) {
				ast::fndecl_attrs::NONE => "",
				ast::fndecl_attrs::FINI => "@fini ",
				ast::fndecl_attrs::INIT => "@init ",
				ast::fndecl_attrs::TEST => "@test ",
			})?;
			n += fmt::fprint(out, "\x1b[0m")?;

			let p = f.prototype.repr as ast::func_type;
			if (p.attrs & ast::func_attrs::NORETURN != 0) {
				n += fmt::fprint(out,
					"\x1b[33m" "@noreturn " "\x1b[0m")?;
			};
			if (len(f.symbol) != 0) {
				n += fmt::fprintf(out,
					"\x1b[33m" "@symbol(\"{}\") " "\x1b[0m",
					f.symbol)?;
			};
			n += fmt::fprint(out, "\x1b[34m" "fn " "\x1b[0m")?;
			n += unparse::ident(out, f.ident)?;
			n += prototype_tty(out, 0,
				f.prototype.repr as ast::func_type)?;
		},
	};
	n += fmt::fprint(out, ";")?;
	return n;
};

fn prototype_tty(
	out: *io::stream,
	indent: size,
	t: ast::func_type,
) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "(")?;
	for (let i = 0z; i < len(t.params); i += 1) {
		let param = t.params[i];
		n += fmt::fprintf(out, "{}: ",
			if (len(param.name) == 0) "_" else param.name)?;
		n += type_tty(out, indent, *param._type)?;
		if (i + 1 == len(t.params)
				&& t.variadism == ast::variadism::HARE) {
			n += fmt::fprintf(out, "...")?;
		};
		if (i + 1 < len(t.params)) {
			n += fmt::fprint(out, ", ")?;
		};
	};
	if (t.variadism == ast::variadism::C) {
		n += fmt::fprint(out, ", ...")?;
	};
	n += fmt::fprint(out, ") ")?;
	n += type_tty(out, indent, *t.result)?;
	return n;
};

// newline() and builtin_type() are from cmd/haredoc/html.ha

// Forked from [[hare::unparse]]
fn struct_union_type_tty(
	out: *io::stream,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let z = 0z;
	let membs = match (t.repr) {
		st: ast::struct_type => {
			z += fmt::fprint(out,
				"\x1b[36m" "struct" "\x1b[0m" " {")?;
			yield st: []ast::struct_member;
		},
		ut: ast::union_type => {
			z += fmt::fprint(out,
				"\x1b[36m" "union" "\x1b[0m" " {")?;
			yield ut: []ast::struct_member;
		},
	};

	indent += 1z;
	for (let i = 0z; i < len(membs); i += 1) {
		z += newline(out, indent)?;

		z += match (membs[i]._offset) {
			null => 0z,
			ex: *ast::expr => fmt::fprint(out, "\x1b[33m" "@offset(")?
				+ unparse::expr(out, indent, *ex)?
				+ fmt::fprint(out, ") \x1b[0m")?,
		};

		z += match (membs[i].member) {
			se: ast::struct_embedded => type_tty(out, indent, *se)?,
			sa: ast::struct_alias => unparse::ident(out, sa)?,
			sf: ast::struct_field => {
				yield fmt::fprintf(out, "{}: ", sf.name)?
					+ type_tty(out, indent, *sf._type)?;
			},
		};

		z += fmt::fprint(out, ",")?;
	};

	indent -= 1;
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

// Forked from [[hare::unparse]]
fn type_tty(
	out: *io::stream,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let n = 0z;
	if (t.flags & ast::type_flags::CONST != 0
			&& !(t.repr is ast::func_type)) {
		n += fmt::fprint(out, "\x1b[36m" "const " "\x1b[0m")?;
	};
	if (t.flags & ast::type_flags::ERROR != 0) {
		if (t.repr is ast::builtin_type) {
			n += fmt::fprint(out, "\x1b[36m" "!" "\x1b[0m")?;
		} else {
			n += fmt::fprint(out, "!")?;
		};
	};

	match (t.repr) {
		a: ast::alias_type => {
			if (a.unwrap) {
				n += fmt::fprint(out, "...")?;
			};
			n += unparse::ident(out, a.ident)?;
		},
		b: ast::builtin_type => {
			n += fmt::fprintf(out, "\x1b[36m" "{}" "\x1b[0m",
				builtin_type(b))?;
		},
		e: ast::enum_type => {
			n += fmt::fprint(out, "\x1b[36m" "enum " "\x1b[0m")?;
			if (e.storage != ast::builtin_type::INT) {
				n += fmt::fprintf(out,
					"\x1b[36m" "{}" "\x1b[0m",
					builtin_type(e.storage))?;
			};
			n += fmt::fprint(out, " {")?;
			indent += 1;
			for (let i = 0z; i < len(e.values); i += 1) {
				n += newline(out, indent)?;
				let value = e.values[i];
				n += fmt::fprint(out, value.name)?;
				match (value.value) {
					null => void,
					e: *ast::expr => {
						n += fmt::fprint(out, " = ")?;
						n += unparse::expr(out, indent, *e)?;
					},
				};
				n += fmt::fprint(out, ",")?;
			};
			indent -= 1;
			n += newline(out, indent)?;
			n += fmt::fprint(out, "}")?;
		},
		f: ast::func_type => {
			if (f.attrs & ast::func_attrs::NORETURN != 0) {
				n += fmt::fprint(out,
					"\x1b[33m" "@noreturn " "\x1b[0m")?;
			};
			n += fmt::fprint(out, "\x1b[34m" "fn" "\x1b[0m")?;
			n += prototype_tty(out, indent, f)?;
		},
		l: ast::list_type => {
			n += fmt::fprint(out, "[")?;
			n += match (l.length) {
				ast::len_slice => 0,
				ast::len_unbounded => fmt::fprint(out, "*")?,
				ast::len_contextual => fmt::fprint(out, "_")?,
				e: *ast::expr => unparse::expr(out, indent, *e)?,
			};
			n += fmt::fprint(out, "]")?;
			n += type_tty(out, indent, *l.members)?;
		},
		p: ast::pointer_type => {
			if (p.flags & ast::pointer_flags::NULLABLE != 0) {
				n += fmt::fprint(out,
					"\x1b[36m" "nullable " "\x1b[0m")?;
			};
			n += fmt::fprint(out, "*")?;
			n += type_tty(out, indent, *p.referent)?;
		},
		ast::struct_type => n += struct_union_type_tty(out, indent, t)?,
		ast::union_type => n += struct_union_type_tty(out, indent, t)?,
		t: ast::tagged_type => {
			n += fmt::fprint(out, "(")?;
			for (let i = 0z; i < len(t); i += 1) {
				n += type_tty(out, indent, *t[i])?;
				if (i + 1 < len(t)) {
					n += fmt::fprint(out, " | ")?;
				};
			};
			n += fmt::fprint(out, ")")?;
		},
		t: ast::tuple_type => {
			n += fmt::fprint(out, "(")?;
			for (let i = 0z; i < len(t); i += 1) {
				n += type_tty(out, indent, *t[i])?;
				if (i + 1 < len(t)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
			n += fmt::fprint(out, ")")?;
		},
	};
	return n;
};
