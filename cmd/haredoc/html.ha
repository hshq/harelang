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
		fmt::fprintf(ctx.out, "<h2><span class='heading-body'>{}</span><span class='heading-extra'>", ident)?;
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
	fmt::fprint(ctx.out, "'><span class='heading-body'>")?;
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
	fmt::fprint(ctx.out, "</span><span class='heading-extra'><a href='#")?;
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

const harriet_b64 = "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";

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
<title>{}</title>
<link rel='icon' type='image/png' href='data:image/png;base64,{}'>", title, harriet_b64)?;
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

.heading-body {
	word-wrap: anywhere;
}

.heading-extra {
	align-self: flex-end;
	flex-grow: 1;
	padding-left: 0.5rem;
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
</style>")?;
	fmt::printfln("<nav>
	<img src='data:image/png;base64,{}'
		class='mascot'
		alt='An inked drawing of the Hare mascot, a fuzzy rabbit'
		width='128' height='128' />
	<h1>Hare documentation</h1>
	<ul>
		<li>
			<a href='https://harelang.org'>Home</a>
		</li>", harriet_b64)?;
	fmt::printf("<li>{}</li>", breadcrumb)?;
	fmt::print("</ul>
</nav>
<main>")?;
	return;
};
