// Note: ast::ident should never have to be escaped
use bufio;
use encoding::utf8;
use fmt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::unparse;
use io;
use os;
use path;
use strings;
use strio;

// Prints a string to an output stream, escaping any of HTML's reserved
// characters.
fn html_escape(out: *io::stream, in: str) (size | io::error) = {
	let z = 0z;
	let iter = strings::iter(in);
	for (true) {
		match (strings::next(&iter)) {
		case void => break;
		case rn: rune =>
			z += io::write(out, switch (rn) {
			case '&' =>
				yield strings::toutf8("&amp;");
			case '<' =>
				yield strings::toutf8("&lt;");
			case '>' =>
				yield strings::toutf8("&gt;");
			case '"' =>
				yield strings::toutf8("&quot;");
			case '\'' =>
				yield strings::toutf8("&apos;");
			case =>
				yield utf8::encoderune(rn);
			})?;
		};
	};
	return z;
};

@test fn html_escape() void = {
       let sink = strio::dynamic();
       defer io::close(sink);
       html_escape(sink, "hello world!")!;
       assert(strio::string(sink) == "hello world!");

       let sink = strio::dynamic();
       defer io::close(sink);
       html_escape(sink, "\"hello world!\"")!;
       assert(strio::string(sink) == "&quot;hello world!&quot;");

       let sink = strio::dynamic();
       defer io::close(sink);
       html_escape(sink, "<hello & 'world'!>")!;
       assert(strio::string(sink) == "&lt;hello &amp; &apos;world&apos;!&gt;");
};

// Formats output as HTML
fn emit_html(ctx: *context) (void | error) = {
	const decls = ctx.summary;
	const ident = unparse::identstr(ctx.ident);
	defer free(ident);

	if (ctx.template) head(ctx.ident)?;

	if (len(ident) == 0) {
		fmt::printf("<h2>The Hare standard library <span class='heading-extra'>", ident)?;
	} else {
		fmt::printf("<h2>{} <span class='heading-extra'>", ident)?;
	};
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		const mode = switch (ctx.tags[i].mode) {
		case module::tag_mode::INCLUSIVE =>
			yield '+';
		case module::tag_mode::EXCLUSIVE =>
			yield '-';
		};
		fmt::printf("{}{} ", mode, ctx.tags[i].name)?;
	};
	fmt::println("</span></h2>")?;

	match (ctx.readme) {
	case void => void;
	case f: io::file =>
		fmt::println("<div class='readme'>")?;
		markup_html(ctx, &f)?;
		fmt::println("</div>")?;
	};

	if (len(ctx.version.subdirs) != 0) {
		// TODO: Verify that these are actually modules
		if (len(ctx.ident) == 0) {
			fmt::println("<h3>Modules</h3>")?;
		} else {
			fmt::println("<h3>Submodules</h3>")?;
		};
		fmt::println("<ul class='submodules'>")?;
		for (let i = 0z; i < len(ctx.version.subdirs); i += 1) {
			let dir = ctx.version.subdirs[i];
			if (dir == "cmd") continue;
			if (dir == "docs") continue;
			if (dir == "scripts") continue;

			let path = module::identpath(ctx.ident);
			defer free(path);
			let path = path::join("/", path, dir);
			defer free(path);

			fmt::printf("<li><a href='")?;
			html_escape(os::stdout, path)?;
			fmt::printf("'>")?;
			html_escape(os::stdout, dir)?;
			fmt::printfln("</a></li>")?;
		};
		fmt::println("</ul>")?;
	};

	if (len(decls.types) == 0
			&& len(decls.errors) == 0
			&& len(decls.constants) == 0
			&& len(decls.globals) == 0
			&& len(decls.funcs) == 0) {
		return;
	};

	fmt::println("<h3>Index</h3>")?;
	tocentries(decls.types, "Types", "types")?;
	tocentries(decls.errors, "Errors", "Errors")?;
	tocentries(decls.constants, "Constants", "constants")?;
	tocentries(decls.globals, "Globals", "globals")?;
	tocentries(decls.funcs, "Functions", "functions")?;

	if (len(decls.types) != 0) {
		fmt::println("<h3>Types</h3>")?;
		for (let i = 0z; i < len(decls.types); i += 1) {
			details(ctx, decls.types[i])?;
		};
	};

	if (len(decls.errors) != 0) {
		fmt::println("<h3>Errors</h3>")?;
		for (let i = 0z; i < len(decls.errors); i += 1) {
			details(ctx, decls.errors[i])?;
		};
	};

	if (len(decls.constants) != 0) {
		fmt::println("<h3>Constants</h3>")?;
		for (let i = 0z; i < len(decls.constants); i += 1) {
			details(ctx, decls.constants[i])?;
		};
	};

	if (len(decls.globals) != 0) {
		fmt::println("<h3>Globals</h3>")?;
		for (let i = 0z; i < len(decls.globals); i += 1) {
			details(ctx, decls.globals[i])?;
		};
	};

	if (len(decls.funcs) != 0) {
		fmt::println("<h3>Functions</h3>")?;
		for (let i = 0z; i < len(decls.funcs); i += 1) {
			details(ctx, decls.funcs[i])?;
		};
	};
};

fn tocentries(decls: []ast::decl, name: str, lname: str) (void | error) = {
	if (len(decls) == 0) {
		return;
	};
	fmt::printfln("<h4>{}</h4>", name)?;
	fmt::println("<pre>")?;
	let undoc = false;
	for (let i = 0z; i < len(decls); i += 1) {
		if (!undoc && decls[i].docs == "") {
			fmt::printfln(
				"{}<span style='color: #444'>// Undocumented {}:</span>",
				if (i == 0) "" else "\n",
				lname)?;
			undoc = true;
		};
		tocentry(decls[i])?;
	};
	fmt::print("</pre>")?;
	return;
};

fn tocentry(decl: ast::decl) (void | error) = {
	fmt::printf("{} ",
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
	fmt::printf("<a href='#")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::printf("'>")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("</a>")?;

	match (decl.decl) {
	case t: []ast::decl_type => void;
	case g: []ast::decl_global =>
		let g = g[0];
		fmt::print(": ")?;
		type_html(os::stdout, 0, g._type, true)?;
	case c: []ast::decl_const =>
		let c = c[0];
		fmt::print(": ")?;
		type_html(os::stdout, 0, c._type, true)?;
	case f: ast::decl_func =>
		prototype_html(os::stdout, 0,
			f.prototype.repr as ast::func_type,
			true)?;
	};
	fmt::println(";")?;
	return;
};

fn details(ctx: *context, decl: ast::decl) (void | error) = {
	fmt::println("<section class='member'>")?;
	fmt::print("<h4 id='")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("'>")?;
	fmt::printf("{} ", match (decl.decl) {
		case ast::decl_func =>
			yield "fn";
		case []ast::decl_type =>
			yield "type";
		case []ast::decl_const =>
			yield "def";
		case []ast::decl_global =>
			yield "let";
		})?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	// TODO: Add source URL
	fmt::print("<span class='heading-extra'><a href='#")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("'>[link]</a>
	</span>")?;
	fmt::println("</h4>")?;

	if (len(decl.docs) == 0) {
		fmt::println("<details>")?;
		fmt::println("<summary>Show undocumented member</summary>")?;
	};

	fmt::println("<pre class='decl'>")?;
	unparse_html(os::stdout, decl)?;
	fmt::println("</pre>")?;

	if (len(decl.docs) != 0) {
		const buf = strings::toutf8(decl.docs);
		markup_html(ctx, bufio::fixed(buf, io::mode::READ))?;
	} else {
		fmt::println("</details>")?;
	};

	fmt::println("</section>")?;
	return;
};

fn htmlref(ctx: *context, ref: ast::ident) (void | io::error) = {
	const ik =
		match (resolve(ctx, ref)) {
		case ik: (ast::ident, symkind) =>
			yield ik;
		case void =>
			const ident = unparse::identstr(ref);
			fmt::errorfln("Warning: Unresolved reference: {}", ident)?;
			fmt::printf("<a href='#' "
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
		fmt::printf("<a href='#{0}' class='ref'>{0}</a>", ident)?;
	case symkind::MODULE =>
		let ipath = module::identpath(id);
		defer free(ipath);
		fmt::printf("<a href='/{}' class='ref'>{}</a>",
			ipath, ident)?;
	case symkind::SYMBOL =>
		let ipath = module::identpath(id[..len(id) - 1]);
		defer free(ipath);
		fmt::printf("<a href='/{}#{}' class='ref'>{}</a>",
			ipath, id[len(id) - 1], ident)?;
	};
	free(ident);
};

fn markup_html(ctx: *context, in: *io::stream) (void | io::error) = {
	let parser = parsedoc(in);
	for (true) {
		const tok = match (scandoc(&parser)) {
			case void => break;
			case tok: token =>
				yield tok;
			};
		match (tok) {
		case paragraph =>
			fmt::println()?;
			fmt::print("<p>")?;
		case tx: text =>
			if (strings::has_prefix(tx, "https://")) {
				// Temporary hack
				fmt::print("<a rel='nofollow noopener' href='")?;
				html_escape(os::stdout, tx)?;
				fmt::print("'>")?;
				html_escape(os::stdout, tx)?;
				fmt::print("</a>")?;
				free(tx);
			} else {
				html_escape(os::stdout, tx)?;
				free(tx);
			};
		case re: reference =>
			htmlref(ctx, re)?;
		case sa: sample =>
			fmt::print("<pre class='sample'>")?;
			html_escape(os::stdout, sa)?;
			fmt::print("</pre>")?;
			free(sa);
		case li: list =>
			fmt::println("<ul>")?;
			for (let i = 0z; i < len(li); i += 1) {
				fmt::println("<li>")?;
				html_escape(os::stdout, li[i])?;
				fmt::println("</li>")?;
			};
			fmt::println("</ul>")?;
		};
	};
	fmt::println()?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_html(out: *io::stream, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
	case c: []ast::decl_const =>
		n += fmt::fprintf(out, "<span class='keyword'>def</span> ")?;
		for (let i = 0z; i < len(c); i += 1) {
			n += unparse::ident(out, c[i].ident)?;
			n += fmt::fprint(out, ": ")?;
			n += type_html(out, 0, c[i]._type, false)?;
			if (i + 1 < len(c)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case g: []ast::decl_global =>
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
	case t: []ast::decl_type =>
		n += fmt::fprint(out, "<span class='keyword'>type</span> ")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += unparse::ident(out, t[i].ident)?;
			n += fmt::fprint(out, " = ")?;
			n += type_html(out, 0, t[i]._type, false)?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
	case f: ast::decl_func =>
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

// Forked from [[hare::unparse]].
fn builtin_type(b: ast::builtin_type) str = {
	switch (b) {
	case ast::builtin_type::FCONST, ast::builtin_type::ICONST =>
		abort("ICONST and FCONST have no lexical representation");
	case ast::builtin_type::BOOL =>
		return "bool";
	case ast::builtin_type::CHAR =>
		return "char";
	case ast::builtin_type::F32 =>
		return "f32";
	case ast::builtin_type::F64 =>
		return "f64";
	case ast::builtin_type::I16 =>
		return "i16";
	case ast::builtin_type::I32 =>
		return "i32";
	case ast::builtin_type::I64 =>
		return "i64";
	case ast::builtin_type::I8 =>
		return "i8";
	case ast::builtin_type::INT =>
		return "int";
	case ast::builtin_type::NULL =>
		return "null";
	case ast::builtin_type::RUNE =>
		return "rune";
	case ast::builtin_type::SIZE =>
		return "size";
	case ast::builtin_type::STR =>
		return "str";
	case ast::builtin_type::U16 =>
		return "u16";
	case ast::builtin_type::U32 =>
		return "u32";
	case ast::builtin_type::U64 =>
		return "u64";
	case ast::builtin_type::U8 =>
		return "u8";
	case ast::builtin_type::UINT =>
		return "uint";
	case ast::builtin_type::UINTPTR =>
		return "uintptr";
	case ast::builtin_type::VOID =>
		return "void";
	};
};

// Forked from [[hare::unparse]].
fn newline(out: *io::stream, indent: size) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "\n")?;
	for (let i = 0z; i < indent; i += 1) {
		n += fmt::fprint(out, "\t")?;
	};
	return n;
};

fn enum_html(
	out: *io::stream,
	indent: size,
	t: ast::enum_type
) (size | io::error) = {
	let z = 0z;

	z += fmt::fprint(out, "<span class='type'>enum</span> ")?;
	if (t.storage != ast::builtin_type::INT) {
		z += fmt::fprintf(out, "<span class='type'>{}</span> ",
			builtin_type(t.storage))?;
	};
	z += fmt::fprint(out, "{")?;
	for (let i = 0z; i < len(t.values); i += 1) {
		const val = t.values[i];

		z += newline(out, indent + 1)?;
		z += fmt::fprint(out, val.name)?;

		match (val.value) {
		case null => void;
		case expr: *ast::expr =>
			z += fmt::fprint(out, " = ")?;
			z += unparse::expr(out, indent, *expr)?;
		};

		z += fmt::fprint(out, ",")?;
	};
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

fn struct_union_html(
	out: *io::stream,
	indent: size,
	t: ast::_type,
	brief: bool,
) (size | io::error) = {
	let z = 0z;
	let members = match (t.repr) {
	case t: ast::struct_type =>
		z += fmt::fprint(out, "<span class='keyword'>struct</span> {")?;
		yield t: []ast::struct_member;
	case t: ast::union_type =>
		z += fmt::fprint(out, "<span class='keyword'>union</span> {")?;
		yield t: []ast::struct_member;
	};

	indent += 1;
	for (let i = 0z; i < len(members); i += 1) {
		const member = members[i];

		z += newline(out, indent)?;
		match (member._offset) {
		case null => void;
		case expr: *ast::expr =>
			z += fmt::fprint(out, "@offset(")?;
			z += unparse::expr(out, indent, *expr)?;
			z += fmt::fprint(out, ") ")?;
		};

		match (member.member) {
		case f: ast::struct_field =>
			z += fmt::fprintf(out, "{}: ", f.name)?;
			z += type_html(out, indent, *f._type, brief)?;
		case embed: ast::struct_embedded =>
			z += type_html(out, indent, *embed, brief)?;
		case indent: ast::struct_alias =>
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
	out: *io::stream,
	indent: size,
	_type: ast::_type,
	brief: bool,
) (size | io::error) = {
	let buf = strio::dynamic();
	defer io::close(buf);
	unparse::_type(buf, indent, _type)?;
	if (brief) {
		return html_escape(out, strio::string(buf))?;
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
	case a: ast::alias_type =>
		if (a.unwrap) {
			z += fmt::fprint(out, "...")?;
		};
		z += unparse::ident(out, a.ident)?;
	case t: ast::builtin_type =>
		z += fmt::fprintf(out, "<span class='type'>{}</span>",
			builtin_type(t))?;
	case t: ast::tagged_type =>
		z += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			z += type_html(out, indent, *t[i], brief)?;
			if (i < len(t) - 1) {
				z += fmt::fprint(out, " | ")?;
			};
		};
		z += fmt::fprint(out, ")")?;
	case t: ast::tuple_type =>
		z += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			z += type_html(out, indent, *t[i], brief)?;
			if (i < len(t) - 1) {
				z += fmt::fprint(out, ", ")?;
			};
		};
		z += fmt::fprint(out, ")")?;
	case t: ast::pointer_type =>
		if (t.flags & ast::pointer_flags::NULLABLE != 0) {
			z += fmt::fprint(out, "<span class='type'>nullable</span> ")?;
		};
		z += fmt::fprint(out, "*")?;
		z += type_html(out, indent, *t.referent, brief)?;
	case t: ast::func_type =>
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
	case t: ast::enum_type =>
		z += enum_html(out, indent, t)?;
	case t: ast::list_type =>
		z += fmt::fprint(out, "[")?;
		match (t.length) {
		case expr: *ast::expr =>
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
	case t: ast::struct_type =>
		z += struct_union_html(out, indent, _type, brief)?;
	case t: ast::union_type =>
		z += struct_union_html(out, indent, _type, brief)?;
	};

	return z;
};

fn prototype_html(
	out: *io::stream,
	indent: size,
	t: ast::func_type,
	brief: bool,
) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "(")?;
	for (let i = 0z; i < len(t.params); i += 1) {
		let param = t.params[i];
		if (!brief) {
			n += fmt::fprintf(out, "{}: ",
				if (len(param.name) == 0) "_" else param.name)?;
		};
		n += type_html(out, indent, *param._type, brief)?;
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
	n += type_html(out, indent, *t.result, brief)?;
	return n;
};

fn breadcrumb(ident: ast::ident) str = {
	if (len(ident) == 0) {
		return "";
	};
	let buf = strio::dynamic();
	fmt::fprintf(buf, "<a href='/'>stdlib</a> » ")!;
	for (let i = 0z; i < len(ident) - 1; i += 1) {
		let ipath = module::identpath(ident[..i+1]);
		defer free(ipath);
		fmt::fprintf(buf, "<a href='/{}'>{}</a>::", ipath, ident[i])!;
	};
	fmt::fprint(buf, ident[len(ident) - 1])!;
	return strio::finish(buf);
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
<title>{}</title>", title)?;
	fmt::println("<style>
body {
	font-family: sans-serif;
	line-height: 1.3;
	margin: 0 auto;
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

@media(max-width: 1000px) {
	main {
		padding: 0;
	}
}
</style>
<nav>
	<img
		src='/mascot.jpg'
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
