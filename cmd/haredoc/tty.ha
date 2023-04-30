// License: GPL-3.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use ascii;
use bufio;
use fmt;
use hare::ast;
use hare::ast::{variadism};
use hare::lex;
use hare::unparse;
use io;
use os;
use strings;
use strio;

let firstline: bool = true;

// Formats output as Hare source code (prototypes) with syntax highlighting
fn emit_tty(ctx: *context) (void | error) = {
	init_colors();
	const summary = ctx.summary;

	match (ctx.readme) {
	case let readme: io::file =>
		for (true) match (bufio::scanline(readme)?) {
		case io::EOF => break;
		case let b: []u8 =>
			defer free(b);
			firstline = false;
			insert(b[0], ' ');
			comment_tty(ctx.out, strings::fromutf8(b)!)?;
		};
	case void => void;
	};

	emit_submodules_tty(ctx)?;

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

fn emit_submodules_tty(ctx: *context) (void | error) = {
	const submodules = submodules(ctx)?;
	defer strings::freeall(submodules);

	if (len(submodules) != 0) {
		fmt::fprintln(ctx.out)?;
		if (len(ctx.ident) == 0) {
			render(ctx.out, syn::COMMENT)?;
			fmt::fprintln(ctx.out, "// Modules")?;
			render(ctx.out, syn::NORMAL)?;
		} else {
			render(ctx.out, syn::COMMENT)?;
			fmt::fprintln(ctx.out, "// Submodules")?;
			render(ctx.out, syn::NORMAL)?;
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

			render(ctx.out, syn::COMMENT)?;
			fmt::fprintfln(ctx.out, "// - [[{}]]", submodule)?;
			render(ctx.out, syn::NORMAL)?;
		};
	};
};

fn comment_tty(out: io::handle, s: str) (size | io::error) = {
	let n = 0z;
	n += render(out, syn::COMMENT)?;
	n += fmt::fprintfln(out, "//{}", s)?;
	n += render(out, syn::NORMAL)?;
	return n;
};

fn docs_tty(out: io::handle, s: str, indent: size) (size | io::error) = {
	const iter = strings::tokenize(s, "\n");
	let z = 0z;
	for (true) match (strings::next_token(&iter)) {
	case let s: str =>
		if (!(strings::peek_token(&iter) is void)) {
			z += comment_tty(out, s)?;
			for (let i = 0z; i < indent; i += 1) {
				z += fmt::fprint(out, "\t")?;
			};
		};
	case void => break;
	};

	return z;
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

	docs_tty(ctx.out, decl.docs, 0)?;
	unparse_tty(ctx.out, decl)?;
	fmt::fprintln(ctx.out)?;
};

// Forked from [[hare::unparse]]
fn unparse_tty(out: io::handle, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
	case let g: []ast::decl_global =>
		n += render(out, syn::KEYWORD)?;
		n += fmt::fprint(out, if (g[0].is_const) "const " else "let ")?;
		for (let i = 0z; i < len(g); i += 1) {
			if (len(g[i].symbol) != 0) {
				n += render(out, syn::ATTRIBUTE)?;
				n += fmt::fprintf(out, "@symbol(")?;
				n += render(out, syn::STRING)?;
				n += fmt::fprintf(out, `"{}"`, g[i].symbol)?;
				n += render(out, syn::ATTRIBUTE)?;
				n += fmt::fprintf(out, ") ")?;
				n += render(out, syn::NORMAL)?;
			};
			n += render(out, syn::GLOBAL)?;
			n += unparse::ident(out, g[i].ident)?;
			match (g[i]._type) {
			case null =>
				yield;
			case let ty: *ast::_type =>
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ": ")?;
				n += type_html(out, 0, *ty, false)?;
			};
			if (i + 1 < len(g)) {
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ", ")?;
			};
			n += render(out, syn::NORMAL)?;
		};
	case let c: []ast::decl_const =>
		n += render(out, syn::KEYWORD)?;
		n += fmt::fprintf(out, "def ")?;
		for (let i = 0z; i < len(c); i += 1) {
			n += render(out, syn::CONSTANT)?;
			n += unparse::ident(out, c[i].ident)?;
			n += render(out, syn::PUNCTUATION)?;
			match (c[i]._type) {
			case null =>
				yield;
			case let ty: *ast::_type =>
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ": ")?;
				n += type_html(out, 0, *ty, false)?;
			};
			if (i + 1 < len(c)) {
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let t: []ast::decl_type =>
		n += render(out, syn::KEYWORD)?;
		n += fmt::fprint(out, "type ")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += render(out, syn::TYPEDEF)?;
			n += unparse::ident(out, t[i].ident)?;
			n += render(out, syn::PUNCTUATION)?;
			n += fmt::fprint(out, " = ")?;
			n += type_tty(out, 0, t[i]._type)?;
			if (i + 1 < len(t)) {
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let f: ast::decl_func =>
		n += render(out, syn::ATTRIBUTE)?;
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
		n += render(out, syn::NORMAL)?;

		let p = f.prototype.repr as ast::func_type;
		if (p.attrs & ast::func_attrs::NORETURN != 0) {
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprint(out, "@noreturn ")?;
			n += render(out, syn::NORMAL)?;
		};
		if (len(f.symbol) != 0) {
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprintf(out, "@symbol(")?;
			n += render(out, syn::STRING)?;
			n += fmt::fprintf(out, `"{}"`, f.symbol)?;
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprintf(out, ") ")?;
			n += render(out, syn::NORMAL)?;
		};
		n += render(out, syn::KEYWORD)?;
		n += fmt::fprint(out, "fn ")?;
		n += render(out, syn::FUNCTION)?;
		n += unparse::ident(out, f.ident)?;
		n += fmt::fprint(out, "\x1b[0m")?;
		n += prototype_tty(out, 0,
			f.prototype.repr as ast::func_type)?;
	};
	n += render(out, syn::PUNCTUATION)?;
	n += fmt::fprint(out, ";")?;
	return n;
};

fn prototype_tty(
	out: io::handle,
	indent: size,
	t: ast::func_type,
) (size | io::error) = {
	let n = 0z;
	n += render(out, syn::PUNCTUATION)?;
	n += fmt::fprint(out, "(")?;

	let typenames: []str = [];
	// TODO: https://todo.sr.ht/~sircmpwn/hare/581
	if (len(t.params) > 0) {
		typenames = alloc([""...], len(t.params));
	};
	defer strings::freeall(typenames);
	let retname = "";
	defer free(retname);

	// estimate length of prototype to determine if it should span multiple
	// lines
	const linelen = if (len(t.params) == 0) {
		let strm = strio::dynamic();
		defer io::close(&strm)!;
		type_tty(&strm, indent, *t.result)?;
		retname = strings::dup(strio::string(&strm));
		yield 0z; // only use one line if there's no parameters
	} else {
		let strm = strio::dynamic();
		defer io::close(&strm)!;
		let linelen = indent * 8 + 5;
		linelen += if (len(t.params) != 0) len(t.params) * 3 - 1 else 0;
		for (let i = 0z; i < len(t.params); i += 1) {
			const param = t.params[i];
			linelen += unparse::_type(&strm, indent, *param._type)?;
			typenames[i] = strings::dup(strio::string(&strm));
			linelen += if (param.name == "") 1 else len(param.name);
			strio::reset(&strm);
		};
		switch (t.variadism) {
		case variadism::NONE => void;
		case variadism::HARE =>
			linelen += 3;
		case variadism::C =>
			linelen += 5;
		};
		linelen += type_tty(&strm, indent, *t.result)?;
		retname = strings::dup(strio::string(&strm));
		yield linelen;
	};

	// use 72 instead of 80 to give a bit of leeway for preceding text
	if (linelen > 72) {
		indent += 1;
		for (let i = 0z; i < len(t.params); i += 1) {
			const param = t.params[i];
			n += newline(out, indent)?;
			n += render(out, syn::SECONDARY)?;
			n += fmt::fprint(out,
				if (param.name == "") "_" else param.name)?;
			n += render(out, syn::PUNCTUATION)?;
			n += fmt::fprint(out, ": ")?;
			n += render(out, syn::TYPE)?;
			n += fmt::fprint(out, typenames[i])?;
			if (i + 1 == len(t.params)
					&& t.variadism == variadism::HARE) {
				n += render(out, syn::OPERATOR)?;
				n += fmt::fprint(out, "...")?;
			} else {
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ",")?;
			};
		};
		if (t.variadism == variadism::C) {
			n += newline(out, indent)?;
			n += render(out, syn::OPERATOR)?;
			n += fmt::fprint(out, "...")?;
		};
		indent -= 1;
		n += newline(out, indent)?;
	} else for (let i = 0z; i < len(t.params); i += 1) {
		const param = t.params[i];
		n += render(out, syn::SECONDARY)?;
		n += fmt::fprint(out,
			if (param.name == "") "_" else param.name)?;
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, ": ")?;
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, typenames[i])?;
		if (i + 1 == len(t.params)) {
			switch (t.variadism) {
			case variadism::NONE => void;
			case variadism::HARE =>
				n += render(out, syn::OPERATOR)?;
				n += fmt::fprint(out, "...")?;
			case variadism::C =>
				n += render(out, syn::PUNCTUATION)?;
				n += fmt::fprint(out, ", ")?;
				n += render(out, syn::OPERATOR)?;
				n += fmt::fprint(out, "...")?;
			};
		} else {
			n += render(out, syn::PUNCTUATION)?;
			n += fmt::fprint(out, ", ")?;
		};
	};

	n += render(out, syn::PUNCTUATION)?;
	n += fmt::fprint(out, ")", retname)?;
	return n;
};

// Forked from [[hare::unparse]]
fn struct_union_type_tty(
	out: io::handle,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let n = 0z;
	let membs = match (t.repr) {
	case let st: ast::struct_type =>
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, "struct")?;
		if (st.packed) {
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprint(out, " @packed")?;
		};
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, " {")?;
		yield st.members: []ast::struct_member;
	case let ut: ast::union_type =>
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, "union")?;
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, " {")?;
		yield ut: []ast::struct_member;
	};

	indent += 1z;
	for (let i = 0z; i < len(membs); i += 1) {
		n += newline(out, indent)?;
		if (membs[i].docs != "") {
			n += docs_tty(out, membs[i].docs, indent)?;
		};

		match (membs[i]._offset) {
		case null => void;
		case let ex: *ast::expr =>
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprint(out, "@offset(")?;
			n += render(out, syn::NUMBER)?;
			n += unparse::expr(out, indent, *ex)?;
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprint(out, ")")?;
			n += render(out, syn::NORMAL)?;
		};

		match (membs[i].member) {
		case let se: ast::struct_embedded =>
			n += type_tty(out, indent, *se)?;
		case let sa: ast::struct_alias =>
			n += unparse::ident(out, sa)?;
		case let sf: ast::struct_field =>
			n += render(out, syn::SECONDARY)?;
			n += fmt::fprint(out, sf.name)?;
			n += render(out, syn::PUNCTUATION)?;
			n += fmt::fprint(out, ": ")?;
			n += type_tty(out, indent, *sf._type)?;
		};

		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, ",")?;
	};

	indent -= 1;
	n += newline(out, indent)?;
	n += render(out, syn::PUNCTUATION)?;
	n += fmt::fprint(out, "}")?;
	return n;
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
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, "const ")?;
	};
	if (t.flags & ast::type_flags::ERROR != 0) {
		n += render(out, syn::OPERATOR)?;
		n += fmt::fprint(out, "!")?;
	};

	match (t.repr) {
	case let a: ast::alias_type =>
		if (a.unwrap) {
			n += render(out, syn::OPERATOR)?;
			n += fmt::fprint(out, "...")?;
		};
		n += render(out, syn::TYPE)?;
		n += unparse::ident(out, a.ident)?;
	case let b: ast::builtin_type =>
		n += render(out, syn::TYPE)?;
		n += fmt::fprintf(out, "{}", unparse::builtin_type(b))?;
	case let e: ast::enum_type =>
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, "enum ")?;
		if (e.storage != ast::builtin_type::INT) {
			n += fmt::fprintf(out,
				"{} ", unparse::builtin_type(e.storage))?;
		};
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprintln(out, "{")?;
		indent += 1;
		for (let i = 0z; i < len(e.values); i += 1) {
			for (let i = 0z; i < indent; i += 1) {
				n += fmt::fprint(out, "\t")?;
			};
			let value = e.values[i];
			let wrotedocs = false;
			if (value.docs != "") {
				// Check if comment should go above or next to
				// field
				if (multiline_comment(value.docs)) {
					n += docs_tty(out, value.docs, indent)?;
					wrotedocs = true;
				};
			};
			n += render(out, syn::SECONDARY)?;
			n += fmt::fprint(out, value.name)?;
			match (value.value) {
			case null => void;
			case let e: *ast::expr =>
				n += render(out, syn::OPERATOR)?;
				n += fmt::fprint(out, " = ")?;
				n += render(out, syn::NORMAL)?;
				n += unparse::expr(out, indent, *e)?;
			};
			n += render(out, syn::PUNCTUATION)?;
			n += fmt::fprint(out, ",")?;
			if (value.docs != "" && !wrotedocs) {
				n += fmt::fprint(out, " ")?;
				n += docs_tty(out, value.docs, 0)?;
			} else {
				n += fmt::fprintln(out)?;
			};
		};
		indent -= 1;
		for (let i = 0z; i < indent; i += 1) {
			n += fmt::fprint(out, "\t")?;
		};
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, "}")?;
	case let f: ast::func_type =>
		if (f.attrs & ast::func_attrs::NORETURN != 0) {
			n += render(out, syn::ATTRIBUTE)?;
			n += fmt::fprint(out, "@noreturn ")?;
		};
		n += render(out, syn::TYPE)?;
		n += fmt::fprint(out, "fn")?;
		n += prototype_tty(out, indent, f)?;
	case let l: ast::list_type =>
		n += render(out, syn::OPERATOR)?;
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
		n += render(out, syn::OPERATOR)?;
		n += fmt::fprint(out, "]")?;
		n += type_tty(out, indent, *l.members)?;
	case let p: ast::pointer_type =>
		if (p.flags & ast::pointer_flags::NULLABLE != 0) {
			n += render(out, syn::TYPE)?;
			n += fmt::fprint(out, "nullable ")?;
		};
		n += render(out, syn::OPERATOR)?;
		n += fmt::fprint(out, "*")?;
		n += type_tty(out, indent, *p.referent)?;
	case ast::struct_type =>
		n += struct_union_type_tty(out, indent, t)?;
	case ast::union_type =>
		n += struct_union_type_tty(out, indent, t)?;
	case let t: ast::tagged_type =>
		// rough estimate of current line length
		let linelen: size = n + (indent + 1) * 8;
		n = 0;
		n += render(out, syn::PUNCTUATION)?;
		linelen += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			linelen += type_tty(out, indent, *t[i])?;
			if (i + 1 == len(t)) break;
			n += render(out, syn::PUNCTUATION)?;
			linelen += fmt::fprint(out, " |")?;
			// use 72 instead of 80 to give a bit of leeway for long
			// type names
			if (linelen > 72) {
				n += linelen;
				linelen = (indent + 1) * 8;
				n += fmt::fprintln(out)?;
				for (let i = 0z; i <= indent; i += 1) {
					n += fmt::fprint(out, "\t")?;
				};
			} else {
				linelen += fmt::fprint(out, " ")?;
			};
		};
		n += linelen;
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, ")")?;
	case let t: ast::tuple_type =>
		// rough estimate of current line length
		let linelen: size = n + (indent + 1) * 8;
		n = 0;
		n += render(out, syn::PUNCTUATION)?;
		linelen += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			linelen += type_tty(out, indent, *t[i])?;
			if (i + 1 == len(t)) break;
			n += render(out, syn::PUNCTUATION)?;
			linelen += fmt::fprint(out, ",")?;
			// use 72 instead of 80 to give a bit of leeway for long
			// type names
			if (linelen > 72) {
				n += linelen;
				linelen = (indent + 1) * 8;
				n += fmt::fprintln(out)?;
				for (let i = 0z; i <= indent; i += 1) {
					n += fmt::fprint(out, "\t")?;
				};
			} else {
				linelen += fmt::fprint(out, " ")?;
			};
		};
		n += linelen;
		n += render(out, syn::PUNCTUATION)?;
		n += fmt::fprint(out, ")")?;
	};
	return n;
};
