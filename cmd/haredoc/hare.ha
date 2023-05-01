// License: GPL-3.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::module;
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
	case let readme: io::file =>
		first = false;
		for (true) {
			match (bufio::scanline(readme)?) {
			case io::EOF => break;
			case let b: []u8 =>
				fmt::fprintfln(ctx.out,
					"// {}", strings::fromutf8(b)!)?;
				free(b);
			};
		};
	case void => void;
	};

	emit_submodules_hare(ctx)?;

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.constants); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.constants[i])?;
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.errors[i])?;
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.globals[i])?;
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.funcs[i])?;
	};
};

fn emit_submodules_hare(ctx: *context) (void | error) = {
	const submodules = submodules(ctx)?;
	defer strings::freeall(submodules);

	if (len(submodules) != 0) {
		fmt::fprintln(ctx.out)?;
		if (len(ctx.ident) == 0) {
			fmt::fprintln(ctx.out, "// Modules")?;
		} else {
			fmt::fprintln(ctx.out, "// Submodules")?;
		};
		for (let i = 0z; i < len(submodules); i += 1) {
			let submodule = if (len(ctx.ident) != 0) {
				const s = unparse::identstr(ctx.ident);
				defer free(s);
				yield strings::concat(s, "::", submodules[i]);
			} else {
				yield strings::dup(submodules[i]);
			};
			defer free(submodule);

			fmt::fprintf(ctx.out, "// - [[")?;
			fmt::fprintf(ctx.out, submodule)?;
			fmt::fprintfln(ctx.out, "]]")?;
		};
	};
};

fn details_hare(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	const iter = strings::tokenize(decl.docs, "\n");
	for (true) {
		match (strings::next_token(&iter)) {
		case void => break;
		case let s: str =>
			if (len(s) != 0) {
				fmt::fprintfln(ctx.out, "//{}", s)?;
			};
		};
	};

	unparse_hare(ctx.out, decl)?;
	fmt::fprintln(ctx.out)?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_hare(out: io::handle, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
	case let g: []ast::decl_global =>
		n += fmt::fprint(out,
			if (g[0].is_const) "const " else "let ")?;
		for (let i = 0z; i < len(g); i += 1) {
			if (len(g[i].symbol) != 0) {
				n += fmt::fprintf(out,
					"@symbol(\"{}\") ", g[i].symbol)?;
			};
			n += unparse::ident(out, g[i].ident)?;
			match (g[i]._type) {
			case null =>
				yield;
			case let ty: *ast::_type =>
				n += fmt::fprint(out, ": ")?;
				n += unparse::_type(out, 0, *ty)?;
			};
			if (i + 1 < len(g)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let t: []ast::decl_type =>
		n += fmt::fprint(out, "type ")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += unparse::ident(out, t[i].ident)?;
			n += fmt::fprint(out, " = ")?;
			n += unparse::_type(out, 0, t[i]._type)?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let c: []ast::decl_const =>
		n += fmt::fprint(out, "def ")?;
		for (let i = 0z; i < len(c); i += 1) {
			n += unparse::ident(out, c[i].ident)?;
			n += fmt::fprint(out, ": ")?;
			match (c[i]._type) {
			case null =>
				yield;
			case let ty: *ast::_type =>
				n += fmt::fprint(out, ": ")?;
				n += unparse::_type(out, 0, *ty)?;
			};
			if (i + 1 < len(c)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let f: ast::decl_func =>
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
		n += unparse::prototype(out, 0,
			f.prototype.repr as ast::func_type)?;
	};
	n += fmt::fprint(out, ";")?;
	return n;
};
