use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use io;
use os;
use strings;
use strio;

// Formats output as Hare source code (prototypes)
fn emit_hare(ctx: *context) (void | error) = {
	const summary = ctx.summary;

	let first = true;
	match (ctx.readme) {
		readme: io::file => {
			first = false;
			for (true) match (bufio::scanline(&readme)?) {
				b: []u8 => {
					fmt::printfln("// {}", strings::fromutf8(b))?;
					free(b);
				},
				io::EOF => break,
			};
		},
		void => void,
	};

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		if (!first) {
			fmt::println()?;
		};
		first = false;
		details_hare(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		if (!first) {
			fmt::println()?;
		};
		first = false;
		details_hare(ctx, summary.errors[i])?;
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		if (!first) {
			fmt::println()?;
		};
		first = false;
		details_hare(ctx, summary.globals[i])?;
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		if (!first) {
			fmt::println()?;
		};
		first = false;
		details_hare(ctx, summary.funcs[i])?;
	};
};

fn details_hare(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	const iter = strings::tokenize(decl.docs, "\n");
	for (true) match (strings::next_token(&iter)) {
		s: str => if (len(s) != 0) {
			fmt::printfln("//{}", s)?;
		},
		void => break,
	};

	unparse_hare(os::stdout, decl)?;
	fmt::println()?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_hare(out: *io::stream, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
		g: []ast::decl_global => {
			n += fmt::fprint(out,
				if (g[0].is_const) "def " else "let ")?;
			for (let i = 0z; i < len(g); i += 1) {
				if (len(g[i].symbol) != 0) {
					n += fmt::fprintf(out,
						"@symbol(\"{}\") ", g[i].symbol)?;
				};
				n += unparse::ident(out, g[i].ident)?;
				n += fmt::fprint(out, ": ")?;
				n += unparse::_type(out, 0, g[i]._type)?;
				if (i + 1 < len(g)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
		},
		t: []ast::decl_type => {
			n += fmt::fprint(out, "type ")?;
			for (let i = 0z; i < len(t); i += 1) {
				n += unparse::ident(out, t[i].ident)?;
				n += fmt::fprint(out, " = ")?;
				n += unparse::_type(out, 0, t[i]._type)?;
				if (i + 1 < len(t)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
		},
		f: ast::decl_func => {
			n += fmt::fprint(out, switch (f.attrs) {
				ast::fndecl_attrs::NONE => "",
				ast::fndecl_attrs::FINI => "@fini ",
				ast::fndecl_attrs::INIT => "@init ",
				ast::fndecl_attrs::TEST => "@test ",
			})?;
			let p = f.prototype.repr as ast::func_type;
			if (p.attrs & ast::func_attrs::NORETURN != 0) {
				n += fmt::fprint(out, "@noreturn ")?;
			};
			if (len(f.symbol) != 0) {
				n += fmt::fprintf(out, "@symbol(\"{}\") ",
					f.symbol)?;
			};
			n += fmt::fprint(out, "fn ")?;
			n += unparse::ident(out, f.ident)?;
			n += prototype_hare(out, 0,
				f.prototype.repr as ast::func_type)?;
		},
	};
	n += fmt::fprint(out, ";")?;
	return n;
};

fn prototype_hare(
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
		n += unparse::_type(out, indent, *param._type)?;
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
	n += unparse::_type(out, indent, *t.result)?;
	return n;
};
