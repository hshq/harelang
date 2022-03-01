// License: GPL-3.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
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
	case let readme: io::file =>
		for (true) match (bufio::scanline(readme)?) {
		case io::EOF => break;
		case let b: []u8 =>
			firstline = false;
			fmt::fprintfln(ctx.out,
				"\x1b[1m" "// {}" "\x1b[0m",
				strings::fromutf8(b))?;
			free(b);
		};
	case void => void;
	};

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		details_tty(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.constants); i += 1) {
		details_tty(ctx, summary.constants[i])?;
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
	for (true) {
		match (strings::next(&iter)) {
		case let r: rune =>
			if (!ascii::isspace(r)) {
				return false;
			};
		case void => break;
		};
	};
	return true;
};

fn details_tty(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	if (!firstline) {
		fmt::fprintln(ctx.out)?;
	};
	firstline = false;

	const iter = strings::tokenize(decl.docs, "\n");
	for (true) {
		match (strings::next_token(&iter)) {
		case let s: str =>
			if (!(strings::peek_token(&iter) is void)) {
				fmt::fprintfln(ctx.out,
					"\x1b[1m" "//{}" "\x1b[0m", s)?;
			};
		case void => break;
		};
	};

	unparse_tty(ctx.out, decl)?;
	fmt::fprintln(ctx.out)?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_tty(out: io::handle, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
	case let g: []ast::decl_global =>
		n += fmt::fprint(out, "\x1b[34m")?;
		n += fmt::fprint(out,
			if (g[0].is_const) "const " else "let ")?;
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
	case let c: []ast::decl_const =>
		n += fmt::fprintf(out, "\x1b[34m" "def " "\x1b[0m")?;
		for (let i = 0z; i < len(c); i += 1) {
			n += unparse::ident(out, c[i].ident)?;
			n += fmt::fprint(out, ": ")?;
			n += type_tty(out, 0, c[i]._type)?;
			if (i + 1 < len(c)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let t: []ast::decl_type =>
		n += fmt::fprint(out, "\x1b[34m" "type " "\x1b[0m")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += unparse::ident(out, t[i].ident)?;
			n += fmt::fprint(out, " = ")?;
			n += type_tty(out, 0, t[i]._type)?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let f: ast::decl_func =>
		n += fmt::fprint(out, "\x1b[33m")?;
		n += fmt::fprint(out, switch (f.attrs) {
		case ast::fndecl_attrs::NONE =>
			yield "";
		case ast::fndecl_attrs::FINI =>
			yield "@fini ";
		case ast::fndecl_attrs::INIT =>
			yield "@init ";
		case ast::fndecl_attrs::TEST =>
			yield "@test ";
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
	};
	n += fmt::fprint(out, ";")?;
	return n;
};

fn prototype_tty(
	out: io::handle,
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
	out: io::handle,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let z = 0z;
	let membs = match (t.repr) {
	case let st: ast::struct_type =>
		z += fmt::fprint(out,
			"\x1b[36m" "struct" "\x1b[0m" " {")?;
		yield st: []ast::struct_member;
	case let ut: ast::union_type =>
		z += fmt::fprint(out,
			"\x1b[36m" "union" "\x1b[0m" " {")?;
		yield ut: []ast::struct_member;
	};

	indent += 1z;
	for (let i = 0z; i < len(membs); i += 1) {
		z += newline(out, indent)?;

		match (membs[i]._offset) {
		case null => void;
		case let ex: *ast::expr =>
			z += fmt::fprint(out, "\x1b[33m" "@offset(")?;
			z += unparse::expr(out, indent, *ex)?;
			z += fmt::fprint(out, ") \x1b[0m")?;
		};

		match (membs[i].member) {
		case let se: ast::struct_embedded =>
			z += type_tty(out, indent, *se)?;
		case let sa: ast::struct_alias =>
			z += unparse::ident(out, sa)?;
		case let sf: ast::struct_field =>
			z += fmt::fprintf(out, "{}: ", sf.name)?;
			z += type_tty(out, indent, *sf._type)?;
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
	out: io::handle,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let n = 0z;
	if (t.flags & ast::type_flags::CONST != 0
			&& !(t.repr is ast::func_type)) {
		n += fmt::fprint(out, "\x1b[36m" "const " "\x1b[0m")?;
	};
	if (t.flags & ast::type_flags::ERROR != 0) {
		n += fmt::fprint(out, "!")?;
	};

	match (t.repr) {
	case let a: ast::alias_type =>
		n += fmt::fprint(out, "\x1b[36m")?;
		if (a.unwrap) {
			n += fmt::fprint(out, "...")?;
		};
		n += unparse::ident(out, a.ident)?;
		n += fmt::fprint(out, "\x1b[0m")?;
	case let b: ast::builtin_type =>
		n += fmt::fprintf(out, "\x1b[36m" "{}" "\x1b[0m",
			unparse::builtin_type(b))?;
	case let e: ast::enum_type =>
		n += fmt::fprint(out, "\x1b[36m" "enum " "\x1b[0m")?;
		if (e.storage != ast::builtin_type::INT) {
			n += fmt::fprintf(out,
				"\x1b[36m" "{} " "\x1b[0m",
				unparse::builtin_type(e.storage))?;
		};
		n += fmt::fprint(out, "{")?;
		indent += 1;
		for (let i = 0z; i < len(e.values); i += 1) {
			n += newline(out, indent)?;
			let value = e.values[i];
			n += fmt::fprint(out, value.name)?;
			match (value.value) {
			case null => void;
			case let e: *ast::expr =>
				n += fmt::fprint(out, " = ")?;
				n += unparse::expr(out, indent, *e)?;
			};
			n += fmt::fprint(out, ",")?;
		};
		indent -= 1;
		n += newline(out, indent)?;
		n += fmt::fprint(out, "}")?;
	case let f: ast::func_type =>
		if (f.attrs & ast::func_attrs::NORETURN != 0) {
			n += fmt::fprint(out,
				"\x1b[33m" "@noreturn " "\x1b[0m")?;
		};
		n += fmt::fprint(out, "\x1b[34m" "fn" "\x1b[0m")?;
		n += prototype_tty(out, indent, f)?;
	case let l: ast::list_type =>
		n += fmt::fprint(out, "[")?;
		match (l.length) {
		case ast::len_slice => void;
		case ast::len_unbounded =>
			n += fmt::fprint(out, "*")?;
		case ast::len_contextual =>
			n += fmt::fprint(out, "_")?;
		case let e: *ast::expr =>
			n += unparse::expr(out, indent, *e)?;
		};
		n += fmt::fprint(out, "]")?;
		n += type_tty(out, indent, *l.members)?;
	case let p: ast::pointer_type =>
		if (p.flags & ast::pointer_flags::NULLABLE != 0) {
			n += fmt::fprint(out,
				"\x1b[36m" "nullable " "\x1b[0m")?;
		};
		n += fmt::fprint(out, "*")?;
		n += type_tty(out, indent, *p.referent)?;
	case ast::struct_type =>
		n += struct_union_type_tty(out, indent, t)?;
	case ast::union_type =>
		n += struct_union_type_tty(out, indent, t)?;
	case let t: ast::tagged_type =>
		n += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += type_tty(out, indent, *t[i])?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, " | ")?;
			};
		};
		n += fmt::fprint(out, ")")?;
	case let t: ast::tuple_type =>
		n += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += type_tty(out, indent, *t[i])?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
		n += fmt::fprint(out, ")")?;
	};
	return n;
};
