// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2022 Byron Torres <b@torresjrjr.com>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
// (c) 2022 Umar Getagazov <umar@handlerug.me>

// Note: ast::ident should never have to be escaped
use bufio;
use encoding::utf8;
use fmt;
use hare::ast;
use hare::ast::{variadism};
use hare::lex;
use hare::module;
use hare::unparse;
use io;
use net::ip;
use net::uri;
use os;
use path;
use strings;
use strio;

// Prints a string to an output handle, escaping any of HTML's reserved
// characters.
fn html_escape(out: io::handle, in: str) (size | io::error) = {
	let z = 0z;
	let iter = strings::iter(in);
	for (true) {
		match (strings::next(&iter)) {
		case void => break;
		case let rn: rune =>
			z += fmt::fprint(out, switch (rn) {
			case '&' =>
				yield "&amp;";
			case '<' =>
				yield "&lt;";
			case '>' =>
				yield "&gt;";
			case '"' =>
				yield "&quot;";
			case '\'' =>
				yield "&apos;";
			case =>
				yield strings::fromutf8(utf8::encoderune(rn))!;
			})?;
		};
	};
	return z;
};

@test fn html_escape() void = {
	let sink = strio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "hello world!")!;
	assert(strio::string(&sink) == "hello world!");

	let sink = strio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "\"hello world!\"")!;
	assert(strio::string(&sink) == "&quot;hello world!&quot;");

	let sink = strio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "<hello & 'world'!>")!;
	assert(strio::string(&sink) == "&lt;hello &amp; &apos;world&apos;!&gt;");
};

// Formats output as HTML
fn emit_html(ctx: *context) (void | error) = {
	const decls = ctx.summary;
	const ident = unparse::identstr(ctx.ident);
	defer free(ident);

	if (ctx.template) head(ctx.ident)?;

	if (len(ident) == 0) {
		fmt::fprintf(ctx.out, "<h2>The Hare standard library <span class='heading-extra'>")?;
	} else {
		fmt::fprintf(ctx.out, "<h2>{} <span class='heading-extra'>", ident)?;
	};
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		const mode = switch (ctx.tags[i].mode) {
		case module::tag_mode::INCLUSIVE =>
			yield '+';
		case module::tag_mode::EXCLUSIVE =>
			yield '-';
		};
		fmt::fprintf(ctx.out, "{}{} ", mode, ctx.tags[i].name)?;
	};
	fmt::fprintln(ctx.out, "</span></h2>")?;

	match (ctx.readme) {
	case void => void;
	case let f: io::file =>
		fmt::fprintln(ctx.out, "<div class='readme'>")?;
		markup_html(ctx, f)?;
		fmt::fprintln(ctx.out, "</div>")?;
	};

	let identpath = module::identpath(ctx.ident);
	defer free(identpath);

	let submodules: []str = [];
	defer free(submodules);

	for (let i = 0z; i < len(ctx.version.subdirs); i += 1) {
		let dir = ctx.version.subdirs[i];
		// XXX: the list of reserved directory names is not yet
		// finalized. See https://todo.sr.ht/~sircmpwn/hare/516
		if (dir == "contrib") continue;
		if (dir == "cmd") continue;
		if (dir == "docs") continue;
		if (dir == "ext") continue;
		if (dir == "vendor") continue;
		if (dir == "scripts") continue;

		let submod = [identpath, dir]: ast::ident;
		if (module::lookup(ctx.mctx, submod) is module::error) {
			continue;
		};

		append(submodules, dir);
	};

	if (len(submodules) != 0) {
		if (len(ctx.ident) == 0) {
			fmt::fprintln(ctx.out, "<h3>Modules</h3>")?;
		} else {
			fmt::fprintln(ctx.out, "<h3>Submodules</h3>")?;
		};
		fmt::fprintln(ctx.out, "<ul class='submodules'>")?;
		for (let i = 0z; i < len(submodules); i += 1) {
			let submodule = submodules[i];
			let path = path::join("/", identpath, submodule);
			defer free(path);

			fmt::fprintf(ctx.out, "<li><a href='")?;
			html_escape(ctx.out, path)?;
			fmt::fprintf(ctx.out, "'>")?;
			html_escape(ctx.out, submodule)?;
			fmt::fprintfln(ctx.out, "</a></li>")?;
		};
		fmt::fprintln(ctx.out, "</ul>")?;
	};

	if (len(decls.types) == 0
			&& len(decls.errors) == 0
			&& len(decls.constants) == 0
			&& len(decls.globals) == 0
			&& len(decls.funcs) == 0) {
		return;
	};

	fmt::fprintln(ctx.out, "<h3>Index</h3>")?;
	tocentries(ctx.out, decls.types, "Types", "types")?;
	tocentries(ctx.out, decls.errors, "Errors", "Errors")?;
	tocentries(ctx.out, decls.constants, "Constants", "constants")?;
	tocentries(ctx.out, decls.globals, "Globals", "globals")?;
	tocentries(ctx.out, decls.funcs, "Functions", "functions")?;

	if (len(decls.types) != 0) {
		fmt::fprintln(ctx.out, "<h3>Types</h3>")?;
		for (let i = 0z; i < len(decls.types); i += 1) {
			details(ctx, decls.types[i])?;
		};
	};

	if (len(decls.errors) != 0) {
		fmt::fprintln(ctx.out, "<h3>Errors</h3>")?;
		for (let i = 0z; i < len(decls.errors); i += 1) {
			details(ctx, decls.errors[i])?;
		};
	};

	if (len(decls.constants) != 0) {
		fmt::fprintln(ctx.out, "<h3>Constants</h3>")?;
		for (let i = 0z; i < len(decls.constants); i += 1) {
			details(ctx, decls.constants[i])?;
		};
	};

	if (len(decls.globals) != 0) {
		fmt::fprintln(ctx.out, "<h3>Globals</h3>")?;
		for (let i = 0z; i < len(decls.globals); i += 1) {
			details(ctx, decls.globals[i])?;
		};
	};

	if (len(decls.funcs) != 0) {
		fmt::fprintln(ctx.out, "<h3>Functions</h3>")?;
		for (let i = 0z; i < len(decls.funcs); i += 1) {
			details(ctx, decls.funcs[i])?;
		};
	};
};

fn comment_html(out: io::handle, s: str) (size | io::error) = {
	// TODO: handle [[references]]
	let z = fmt::fprint(out, "<span class='comment'>//")?;
	z += html_escape(out, s)?;
	z += fmt::fprint(out, "</span><br>")?;
	return z;
};

fn docs_html(out: io::handle, s: str, indent: size) (size | io::error) = {
	const iter = strings::tokenize(s, "\n");
	let z = 0z;
	for (true) match (strings::next_token(&iter)) {
	case let s: str =>
		if (!(strings::peek_token(&iter) is void)) {
			z += comment_html(out, s)?;
			for (let i = 0z; i < indent; i += 1) {
				z += fmt::fprint(out, "\t")?;
			};
		};
	case void => break;
	};

	return z;
};

fn tocentries(
	out: io::handle,
	decls: []ast::decl,
	name: str,
	lname: str,
) (void | error) = {
	if (len(decls) == 0) {
		return;
	};
	fmt::fprintfln(out, "<h4>{}</h4>", name)?;
	fmt::fprintln(out, "<pre>")?;
	let undoc = false;
	for (let i = 0z; i < len(decls); i += 1) {
		if (!undoc && decls[i].docs == "") {
			fmt::fprintfln(
				out,
				"{}<span class='comment'>// Undocumented {}:</span>",
				if (i == 0) "" else "\n",
				lname)?;
			undoc = true;
		};
		tocentry(out, decls[i])?;
	};
	fmt::fprint(out, "</pre>")?;
	return;
};

fn tocentry(out: io::handle, decl: ast::decl) (void | error) = {
	fmt::fprintf(out, "{} ",
		match (decl.decl) {
		case ast::decl_func =>
			yield "fn";
		case []ast::decl_type =>
			yield "type";
		case []ast::decl_const =>
			yield "const";
		case []ast::decl_global =>
			yield "let";
		})?;
	fmt::fprintf(out, "<a href='#")?;
	unparse::ident(out, decl_ident(decl))?;
	fmt::fprintf(out, "'>")?;
	unparse::ident(out, decl_ident(decl))?;
	fmt::fprint(out, "</a>")?;

	match (decl.decl) {
	case let t: []ast::decl_type => void;
	case let g: []ast::decl_global =>
		let g = g[0];
		fmt::fprint(out, ": ")?;
		type_html(out, 0, g._type, true)?;
	case let c: []ast::decl_const =>
		let c = c[0];
		fmt::fprint(out, ": ")?;
		type_html(out, 0, c._type, true)?;
	case let f: ast::decl_func =>
		prototype_html(out, 0,
			f.prototype.repr as ast::func_type,
			true)?;
	};
	fmt::fprintln(out, ";")?;
	return;
};

fn details(ctx: *context, decl: ast::decl) (void | error) = {
	fmt::fprintln(ctx.out, "<section class='member'>")?;
	fmt::fprint(ctx.out, "<h4 id='")?;
	unparse::ident(ctx.out, decl_ident(decl))?;
	fmt::fprint(ctx.out, "'>")?;
	fmt::fprintf(ctx.out, "{} ", match (decl.decl) {
		case ast::decl_func =>
			yield "fn";
		case []ast::decl_type =>
			yield "type";
		case []ast::decl_const =>
			yield "def";
		case []ast::decl_global =>
			yield "let";
		})?;
	unparse::ident(ctx.out, decl_ident(decl))?;
	// TODO: Add source URL
	fmt::fprint(ctx.out, "<span class='heading-extra'><a href='#")?;
	unparse::ident(ctx.out, decl_ident(decl))?;
	fmt::fprint(ctx.out, "'>[link]</a>
	</span>")?;
	fmt::fprintln(ctx.out, "</h4>")?;

	if (len(decl.docs) == 0) {
		fmt::fprintln(ctx.out, "<details>")?;
		fmt::fprintln(ctx.out, "<summary>Show undocumented member</summary>")?;
	};

	fmt::fprintln(ctx.out, "<pre class='decl'>")?;
	unparse_html(ctx.out, decl)?;
	fmt::fprintln(ctx.out, "</pre>")?;

	if (len(decl.docs) != 0) {
		const trimmed = trim_comment(decl.docs);
		defer free(trimmed);
		const buf = strings::toutf8(trimmed);
		markup_html(ctx, &bufio::fixed(buf, io::mode::READ))?;
	} else {
		fmt::fprintln(ctx.out, "</details>")?;
	};

	fmt::fprintln(ctx.out, "</section>")?;
	return;
};

fn htmlref(ctx: *context, ref: ast::ident) (void | io::error) = {
	const ik =
		match (resolve(ctx, ref)) {
		case let ik: (ast::ident, symkind) =>
			yield ik;
		case void =>
			const ident = unparse::identstr(ref);
			fmt::errorfln("Warning: Unresolved reference: {}", ident)?;
			fmt::fprintf(ctx.out, "<a href='#' "
				"class='ref invalid' "
				"title='This reference could not be found'>{}</a>",
				ident)?;
			free(ident);
			return;
		};

	// TODO: The reference is not necessarily in the stdlib
	const kind = ik.1, id = ik.0;
	const ident = unparse::identstr(id);
	switch (kind) {
	case symkind::LOCAL =>
		fmt::fprintf(ctx.out, "<a href='#{0}' class='ref'>{0}</a>", ident)?;
	case symkind::MODULE =>
		let ipath = module::identpath(id);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}' class='ref'>{}</a>",
			ipath, ident)?;
	case symkind::SYMBOL =>
		let ipath = module::identpath(id[..len(id) - 1]);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}#{}' class='ref'>{}</a>",
			ipath, id[len(id) - 1], ident)?;
	case symkind::ENUM_LOCAL =>
		fmt::fprintf(ctx.out, "<a href='#{}' class='ref'>{}</a>",
			id[len(id) - 2], ident)?;
	case symkind::ENUM_REMOTE =>
		let ipath = module::identpath(id[..len(id) - 2]);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}#{}' class='ref'>{}</a>",
			ipath, id[len(id) - 2], ident)?;
	};
	free(ident);
};

fn markup_html(ctx: *context, in: io::handle) (void | io::error) = {
	let parser = parsedoc(in);
	let waslist = false;
	for (true) {
		const tok = match (scandoc(&parser)) {
			case void =>
				if (waslist) {
					fmt::fprintln(ctx.out, "</ul>")?;
				};
				break;
			case let tok: token =>
				yield tok;
			};
		match (tok) {
		case paragraph =>
			if (waslist) {
				fmt::fprintln(ctx.out, "</ul>")?;
				waslist = false;
			};
			fmt::fprintln(ctx.out)?;
			fmt::fprint(ctx.out, "<p>")?;
		case let tx: text =>
			defer free(tx);
			match (uri::parse(strings::trim(tx))) {
			case let uri: uri::uri =>
				defer uri::finish(&uri);
				if (uri.host is net::ip::addr || len(uri.host as str) > 0) {
					fmt::fprint(ctx.out, "<a rel='nofollow noopener' href='")?;
					uri::fmt(ctx.out, &uri)?;
					fmt::fprint(ctx.out, "'>")?;
					html_escape(ctx.out, tx)?;
					fmt::fprint(ctx.out, "</a>")?;
				} else {
					html_escape(ctx.out, tx)?;
				};
			case uri::invalid =>
				html_escape(ctx.out, tx)?;
			};
		case let re: reference =>
			htmlref(ctx, re)?;
		case let sa: sample =>
			if (waslist) {
				fmt::fprintln(ctx.out, "</ul>")?;
				waslist = false;
			};
			fmt::fprint(ctx.out, "<pre class='sample'>")?;
			html_escape(ctx.out, sa)?;
			fmt::fprint(ctx.out, "</pre>")?;
			free(sa);
		case listitem =>
			if (!waslist) {
				fmt::fprintln(ctx.out, "<ul>")?;
				waslist = true;
			};
			fmt::fprint(ctx.out, "<li>")?;
		};
	};
	fmt::fprintln(ctx.out)?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_html(out: io::handle, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
	case let c: []ast::decl_const =>
		n += fmt::fprintf(out, "<span class='keyword'>def</span> ")?;
		for (let i = 0z; i < len(c); i += 1) {
			n += unparse::ident(out, c[i].ident)?;
			n += fmt::fprint(out, ": ")?;
			n += type_html(out, 0, c[i]._type, false)?;
			if (i + 1 < len(c)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let g: []ast::decl_global =>
		n += fmt::fprintf(out, "<span class='keyword'>{}</span>",
			if (g[0].is_const) "const " else "let ")?;
		for (let i = 0z; i < len(g); i += 1) {
			n += unparse::ident(out, g[i].ident)?;
			n += fmt::fprint(out, ": ")?;
			n += type_html(out, 0, g[i]._type, false)?;
			if (i + 1 < len(g)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case let t: []ast::decl_type =>
		n += fmt::fprint(out, "<span class='keyword'>type</span> ")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += unparse::ident(out, t[i].ident)?;
			n += fmt::fprint(out, " = ")?;
			n += type_html(out, 0, t[i]._type, false)?;
			if (i + 1 < len(t)) {
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
		n += fmt::fprint(out, "<span class='keyword'>fn</span> ")?;
		n += unparse::ident(out, f.ident)?;
		n += prototype_html(out, 0,
			f.prototype.repr as ast::func_type,
			false)?;
	};
	n += fmt::fprint(out, ";")?;
	return n;
};

fn enum_html(
	out: io::handle,
	indent: size,
	t: ast::enum_type
) (size | io::error) = {
	let z = 0z;

	z += fmt::fprint(out, "<span class='type'>enum</span> ")?;
	if (t.storage != ast::builtin_type::INT) {
		z += fmt::fprintf(out, "<span class='type'>{}</span> ",
			unparse::builtin_type(t.storage))?;
	};
	z += fmt::fprintln(out, "{")?;
	indent += 1;
	for (let i = 0z; i < len(t.values); i += 1) {
		for (let i = 0z; i < indent; i += 1) {
			z += fmt::fprint(out, "\t")?;
		};
		const val = t.values[i];
		let wrotedocs = false;
		if (val.docs != "") {
			// Check if comment should go above or next to field
			if (multiline_comment(val.docs)) {
				z += docs_html(out, val.docs, indent)?;
				wrotedocs = true;
			};
		};

		z += fmt::fprint(out, val.name)?;

		match (val.value) {
		case null => void;
		case let expr: *ast::expr =>
			z += fmt::fprint(out, " = ")?;
			z += unparse::expr(out, indent, *expr)?;
		};

		z += fmt::fprint(out, ",")?;

		if (val.docs != "" && !wrotedocs) {
			z += fmt::fprint(out, " ")?;
			z += docs_html(out, val.docs, 0)?;
		} else {
			z += fmt::fprintln(out)?;
		};
	};
	indent -= 1;
	for (let i = 0z; i < indent; i += 1) {
		z += fmt::fprint(out, "\t")?;
	};
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

fn struct_union_html(
	out: io::handle,
	indent: size,
	t: ast::_type,
	brief: bool,
) (size | io::error) = {
	let z = 0z;
	let members = match (t.repr) {
	case let t: ast::struct_type =>
		z += fmt::fprint(out, "<span class='keyword'>struct</span>")?;
		if (t.packed) {
			z += fmt::fprint(out, " @packed")?;
		};
		z += fmt::fprint(out, " {")?;
		yield t.members: []ast::struct_member;
	case let t: ast::union_type =>
		z += fmt::fprint(out, "<span class='keyword'>union</span> {")?;
		yield t: []ast::struct_member;
	};

	indent += 1;
	for (let i = 0z; i < len(members); i += 1) {
		const member = members[i];

		z += newline(out, indent)?;
		if (member.docs != "" && !brief) {
			z += docs_html(out, member.docs, indent)?;
		};
		match (member._offset) {
		case null => void;
		case let expr: *ast::expr =>
			z += fmt::fprint(out, "@offset(")?;
			z += unparse::expr(out, indent, *expr)?;
			z += fmt::fprint(out, ") ")?;
		};

		match (member.member) {
		case let f: ast::struct_field =>
			z += fmt::fprintf(out, "{}: ", f.name)?;
			z += type_html(out, indent, *f._type, brief)?;
		case let embed: ast::struct_embedded =>
			z += type_html(out, indent, *embed, brief)?;
		case let indent: ast::struct_alias =>
			z += unparse::ident(out, indent)?;
		};
		z += fmt::fprint(out, ",")?;
	};

	indent -= 1;
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;

	return z;
};

fn type_html(
	out: io::handle,
	indent: size,
	_type: ast::_type,
	brief: bool,
) (size | io::error) = {
	if (brief) {
		let buf = strio::dynamic();
		defer io::close(&buf)!;
		unparse::_type(&buf, indent, _type)?;
		return html_escape(out, strio::string(&buf))?;
	};

	// TODO: More detailed formatter which can find aliases nested deeper in
	// other types and highlight more keywords, like const
	let z = 0z;

	if (_type.flags & ast::type_flags::CONST != 0
			&& !(_type.repr is ast::func_type)) {
		z += fmt::fprint(out, "<span class='keyword'>const</span> ")?;
	};

	if (_type.flags & ast::type_flags::ERROR != 0) {
		if (_type.repr is ast::builtin_type) {
			z += fmt::fprint(out, "<span class='type'>!</span>")?;
		} else {
			z += fmt::fprint(out, "!")?;
		};
	};

	match (_type.repr) {
	case let a: ast::alias_type =>
		if (a.unwrap) {
			z += fmt::fprint(out, "...")?;
		};
		z += unparse::ident(out, a.ident)?;
	case let t: ast::builtin_type =>
		z += fmt::fprintf(out, "<span class='type'>{}</span>",
			unparse::builtin_type(t))?;
	case let t: ast::tagged_type =>
		// rough estimate of current line length
		let linelen: size = z + (indent + 1) * 8;
		z = 0;
		linelen += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			linelen += type_html(out, indent, *t[i], brief)?;
			if (i + 1 == len(t)) break;
			linelen += fmt::fprint(out, " |")?;
			// use 72 instead of 80 to give a bit of leeway for long
			// type names
			if (linelen > 72) {
				z += linelen;
				linelen = (indent + 1) * 8;
				z += fmt::fprintln(out)?;
				for (let i = 0z; i < indent; i += 1) {
					z += fmt::fprint(out, "\t")?;
				};
			} else {
				linelen += fmt::fprint(out, " ")?;
			};
		};
		z += linelen;
		z += fmt::fprint(out, ")")?;
	case let t: ast::tuple_type =>
		// rough estimate of current line length
		let linelen: size = z + (indent + 1) * 8;
		z = 0;
		linelen += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			linelen += type_html(out, indent, *t[i], brief)?;
			if (i + 1 == len(t)) break;
			linelen += fmt::fprint(out, ",")?;
			// use 72 instead of 80 to give a bit of leeway for long
			// type names
			if (linelen > 72) {
				z += linelen;
				linelen = (indent + 1) * 8;
				z += fmt::fprintln(out)?;
				for (let i = 0z; i < indent; i += 1) {
					z += fmt::fprint(out, "\t")?;
				};
			} else {
				linelen += fmt::fprint(out, " ")?;
			};
		};
		z += linelen;
		z += fmt::fprint(out, ")")?;
	case let t: ast::pointer_type =>
		if (t.flags & ast::pointer_flags::NULLABLE != 0) {
			z += fmt::fprint(out, "<span class='type'>nullable</span> ")?;
		};
		z += fmt::fprint(out, "*")?;
		z += type_html(out, indent, *t.referent, brief)?;
	case let t: ast::func_type =>
		if (t.attrs & ast::func_attrs::NORETURN == ast::func_attrs::NORETURN) {
			z += fmt::fprint(out, "@noreturn ")?;
		};

		z += fmt::fprint(out, "<span class='keyword'>fn</span>(")?;
		for (let i = 0z; i < len(t.params); i += 1) {
			const param = t.params[i];
			z += fmt::fprintf(out, "{}: ",
				if (len(param.name) == 0) "_" else param.name)?;
			z += type_html(out, indent, *param._type, brief)?;

			if (i + 1 == len(t.params)
					&& t.variadism == ast::variadism::HARE) {
				// TODO: Highlight that as well
				z += fmt::fprint(out, "...")?;
			};
			if (i + 1 < len(t.params)) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		if (t.variadism == ast::variadism::C) {
			z += fmt::fprint(out, ", ...")?;
		};
		z += fmt::fprint(out, ") ")?;
		z += type_html(out, indent, *t.result, brief)?;
	case let t: ast::enum_type =>
		z += enum_html(out, indent, t)?;
	case let t: ast::list_type =>
		z += fmt::fprint(out, "[")?;
		match (t.length) {
		case let expr: *ast::expr =>
			z += unparse::expr(out, indent, *expr)?;
		case ast::len_slice =>
			z += 0;
		case ast::len_unbounded =>
			z += fmt::fprintf(out, "*")?;
		case ast::len_contextual =>
			z += fmt::fprintf(out, "_")?;
		};
		z += fmt::fprint(out, "]")?;

		z += type_html(out, indent, *t.members, brief)?;
	case let t: ast::struct_type =>
		z += struct_union_html(out, indent, _type, brief)?;
	case let t: ast::union_type =>
		z += struct_union_html(out, indent, _type, brief)?;
	};

	return z;
};

fn prototype_html(
	out: io::handle,
	indent: size,
	t: ast::func_type,
	brief: bool,
) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "(")?;

	// estimate length of prototype to determine if it should span multiple
	// lines
	const linelen = if (len(t.params) == 0 || brief) {
		yield 0z; // If no parameters or brief, only use one line.
	} else {
		let linelen = indent * 8 + 5;
		linelen += if (len(t.params) != 0) len(t.params) * 3 - 1 else 0;
		for (let i = 0z; i < len(t.params); i += 1) {
			const param = t.params[i];
			linelen += unparse::_type(io::empty, indent,
				*param._type)?;
			linelen += if (param.name == "") 1 else len(param.name);
		};
		switch (t.variadism) {
		case variadism::NONE => void;
		case variadism::HARE =>
			linelen += 3;
		case variadism::C =>
			linelen += 5;
		};
		linelen += unparse::_type(io::empty, indent, *t.result)?;
		yield linelen;
	};

	// use 72 instead of 80 to give a bit of leeway for preceding text
	if (linelen > 72) {
		indent += 1;
		for (let i = 0z; i < len(t.params); i += 1) {
			const param = t.params[i];
			n += newline(out, indent)?;
			n += fmt::fprintf(out, "{}: ",
				if (param.name == "") "_" else param.name)?;
			n += type_html(out, indent, *param._type, brief)?;
			if (i + 1 == len(t.params)
					&& t.variadism == variadism::HARE) {
				n += fmt::fprint(out, "...")?;
			} else {
				n += fmt::fprint(out, ",")?;
			};
		};
		if (t.variadism == variadism::C) {
			n += newline(out, indent)?;
			n += fmt::fprint(out, "...")?;
		};
		indent -= 1;
		n += newline(out, indent)?;
	} else for (let i = 0z; i < len(t.params); i += 1) {
		const param = t.params[i];
		if (!brief) {
			n += fmt::fprintf(out, "{}: ",
				if (param.name == "") "_" else param.name)?;
		};
		n += type_html(out, indent, *param._type, brief)?;
		if (i + 1 == len(t.params)) {
			switch (t.variadism) {
			case variadism::NONE => void;
			case variadism::HARE =>
				n += fmt::fprint(out, "...")?;
			case variadism::C =>
				n += fmt::fprint(out, ", ...")?;
			};
		} else {
			n += fmt::fprint(out, ", ")?;
		};
	};

	n += fmt::fprint(out, ") ")?;
	n += type_html(out, indent, *t.result, brief)?;
	return n;
};

fn breadcrumb(ident: ast::ident) str = {
	if (len(ident) == 0) {
		return "";
	};
	let buf = strio::dynamic();
	fmt::fprintf(&buf, "<a href='/'>stdlib</a> » ")!;
	for (let i = 0z; i < len(ident) - 1; i += 1) {
		let ipath = module::identpath(ident[..i+1]);
		defer free(ipath);
		fmt::fprintf(&buf, "<a href='/{}'>{}</a>::", ipath, ident[i])!;
	};
	fmt::fprint(&buf, ident[len(ident) - 1])!;
	return strio::string(&buf);
};

fn head(ident: ast::ident) (void | error) = {
	const id = unparse::identstr(ident);
	defer free(id);

	let breadcrumb = breadcrumb(ident);
	defer free(breadcrumb);

	const title =
		if (len(id) == 0)
			fmt::asprintf("Hare documentation")
		else
			fmt::asprintf("{} — Hare documentation", id);
	defer free(title);

	// TODO: Move bits to +embed?
	fmt::printfln("<!doctype html>
<html lang='en'>
<meta charset='utf-8' />
<meta name='viewport' content='width=device-width, initial-scale=1' />
<title>{}</title>", title)?;
	fmt::println("<style>
body {
	font-family: sans-serif;
	line-height: 1.3;
	margin: 0 auto;
	padding: 0 1rem;
}

nav:not(#TableOfContents) {
	max-width: calc(800px + 128px + 128px);
	margin: 1rem auto 0;
	display: grid;
	grid-template-rows: auto auto 1fr;
	grid-template-columns: auto 1fr;
	grid-template-areas:
		'logo header'
		'logo nav'
		'logo none';
}

nav:not(#TableOfContents) img {
	grid-area: logo;
}

nav:not(#TableOfContents) h1 {
	grid-area: header;
	margin: 0;
	padding: 0;
}

nav:not(#TableOfContents) ul {
	grid-area: nav;
	margin: 0.5rem 0 0 0;
	padding: 0;
	list-style: none;
	display: flex;
	flex-direction: row;
	justify-content: left;
	flex-wrap: wrap;
}

nav:not(#TableOfContents) li:not(:first-child) {
	margin-left: 2rem;
}

#TableOfContents {
	font-size: 1.1rem;
}

main {
	padding: 0 128px;
	max-width: 800px;
	margin: 0 auto;

}

pre {
	background-color: #eee;
	padding: 0.25rem 1rem;
	margin: 0 -1rem 1rem;
	font-size: 1.2rem;
	max-width: calc(100% + 1rem);
	overflow-x: auto;
}

pre .keyword {
    color: #008;
}

pre .type {
	color: #44F;
}

ol {
	padding-left: 0;
	list-style: none;
}

ol li {
	padding-left: 0;
}

h2, h3, h4 {
	display: flex;
}

h3 {
	border-bottom: 1px solid #ccc;
	padding-bottom: 0.25rem;
}

.invalid {
	color: red;
}

.heading-extra {
	align-self: flex-end;
	flex-grow: 1;
	text-align: right;
	font-size: 0.8rem;
	color: #444;
}

h4:target + pre {
	background: #ddf;
}

details {
	background: #eee;
	margin: 1rem -1rem 1rem;
}

summary {
	cursor: pointer;
	padding: 0.5rem 1rem;
}

details pre {
	margin: 0;
}

.comment {
	color: #000;
	font-weight: bold;
}

@media(max-width: 1000px) {
	main {
		padding: 0;
	}
}

@media(prefers-color-scheme: dark) {
	body {
		background: #121415;
		color: #e1dfdc;
	}

	img.mascot {
		filter: invert(.92);
	}

	a {
		color: #78bef8;
	}

	a:visited {
		color: #48a7f5;
	}

	summary {
		background: #16191c;
	}

	h3 {
		border-bottom: solid #16191c;
	}

	h4:target + pre {
		background: #162329;
	}

	pre {
		background-color: #16191c;
	}

	pre .keyword {
		color: #69f;
	}

	pre .type {
		color: #3cf;
	}

	.comment {
		color: #fff;
	}

	.heading-extra {
		color: #9b9997;
	}
}
</style>
<nav>
	<img
		src='data:image/png;base64,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'
		class='mascot'
		alt='An inked drawing of the Hare mascot, a fuzzy rabbit'
		width='128' height='128' />
	<h1>Hare documentation</h1>
	<ul>
		<li>
			<a href='https://harelang.org'>Home</a>
		</li>")?;
	fmt::printf("<li>{}</li>", breadcrumb)?;
	fmt::print("</ul>
</nav>
<main>")?;
	return;
};
