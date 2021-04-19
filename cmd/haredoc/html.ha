use fmt;
use format::html;
use hare::ast;
use hare::lex;
use hare::module;
use hare::unparse;
use io;
use os;
use strings;
use strio;

// Formats output as HTML
fn emit_html(ctx: *context) (void | error) = {
	const decls = ctx.summary;
	const ident = unparse::identstr(ctx.ident);
	defer free(ident);

	if (ctx.template) head(ctx.ident)?;

	fmt::printf("<h2>{} <span class='heading-extra'>", ident);
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		const mode = switch (ctx.tags[i].mode) {
			module::tag_mode::INCLUSIVE => '+',
			module::tag_mode::EXCLUSIVE => '-',
		};
		fmt::printf("{}{} ", mode, ctx.tags[i].name);
	};
	fmt::println("</span></h2>")?;

	match (ctx.readme) {
		null => void,
		f: *io::stream => {
			// TODO: Format as haredoc markup
			fmt::println("<div class='readme'>")?;
			fmt::println("<p>")?;
			io::copy(os::stdout, f)?;
			fmt::println("</div>")?;
		},
	};

	if (len(decls.types) != 0) {
		fmt::println("<h4>Types</h4>")?;
		fmt::println("<pre>")?;
		for (let i = 0z; i < len(decls.types); i += 1) {
			tocentry(decls.types[i])?;
		};
		fmt::print("</pre>")?;
	};

	if (len(decls.globals) != 0) {
		fmt::println("<h4>Globals</h4>")?;
		fmt::print("<pre>")?;
		for (let i = 0z; i < len(decls.globals); i += 1) {
			tocentry(decls.globals[i])?;
		};
		fmt::print("</pre>")?;
	};

	if (len(decls.funcs) != 0) {
		fmt::println("<h4>Functions</h4>")?;
		fmt::print("<pre>")?;
		for (let i = 0z; i < len(decls.funcs); i += 1) {
			tocentry(decls.funcs[i])?;
		};
		fmt::println("</pre>")?;
	};
	fmt::println("<hr />")?;

	for (let i = 0z; i < len(decls.types); i += 1) {
		details(decls.types[i])?;
	};
	for (let i = 0z; i < len(decls.globals); i += 1) {
		details(decls.globals[i])?;
	};
	for (let i = 0z; i < len(decls.funcs); i += 1) {
		details(decls.funcs[i])?;
	};
};

fn tocentry(decl: ast::decl) (void | error) = {
	fmt::printf("{} ",
		match (decl.decl) {
			_: ast::decl_func => "fn",
			_: []ast::decl_type => "type",
			_: []ast::decl_global => "let",
		});
	fmt::printf("<a href='#");
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::printf("'>");
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("</a>");

	match (decl.decl) {
		g: []ast::decl_global => {
			let g = g[0];
			fmt::fprint(os::stdout, ": ")?;
			type_html(os::stdout, 0, g._type, true)?;
		},
		t: []ast::decl_type => void,
		f: ast::decl_func => prototype_html(os::stdout, 0,
			f.prototype._type as ast::func_type,
			true)?,
	};
	fmt::println(";");
	return;
};

fn details(decl: ast::decl) (void | error) = {
	fmt::println("<section class='member'>");
	fmt::print("<h3 id='")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("'>")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	// TODO: Make this URL real
	fmt::print("<span class='heading-extra'>
		<a href='#'>[source]</a>
		<a href='#")?;
	unparse::ident(os::stdout, decl_ident(decl))?;
	fmt::print("'>[link]</a>
	</span>")?;
	fmt::println("</h3>")?;

	fmt::println("<pre class='decl'>")?;
	unparse_html(os::stdout, decl)?;
	fmt::println("</pre>")?;

	// TODO: Apply Hare formatting
	fmt::println("<p class='comment'>")?;
	const iter = strings::tokenize(decl.docs, "\n");
	for (true) match (strings::next_token(&iter)) {
		s: str => if (len(s) != 0) {
			html::escape(os::stdout, s)?;
		},
		_: void => break,
	};

	fmt::println("</section>")?;
	return;
};

// Forked from [[hare::unparse]]
fn unparse_html(out: *io::stream, d: ast::decl) (size | io::error) = {
	let n = 0z;
	match (d.decl) {
		g: []ast::decl_global => {
			n += fmt::fprintf(out, "<span class='keyword'>{}</span>",
				if (g[0].is_const) "def " else "let ")?;
			for (let i = 0z; i < len(g); i += 1) {
				n += unparse::ident(out, g[i].ident)?;
				n += fmt::fprint(out, ": ")?;
				n += type_html(out, 0, g[i]._type, false)?;
				if (i + 1 < len(g)) {
					n += fmt::fprint(out, ", ")?;
				};
			};
		},
		t: []ast::decl_type => {
			n += fmt::fprint(out, "<span class='keyword'>type</span> ")?;
			for (let i = 0z; i < len(t); i += 1) {
				n += unparse::ident(out, t[i].ident)?;
				n += fmt::fprint(out, " = ")?;
				n += type_html(out, 0, t[i]._type, false)?;
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
			let p = f.prototype._type as ast::func_type;
			if (p.attrs & ast::func_attrs::NORETURN != 0) {
				n += fmt::fprint(out, "@noreturn ")?;
			};
			n += fmt::fprint(out, "<span class='keyword'>fn</span> ")?;
			n += unparse::ident(out, f.ident)?;
			n += prototype_html(out, 0,
				f.prototype._type as ast::func_type,
				false)?;
		},
	};
	n += fmt::fprint(out, ";")?;
	return n;
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
		return html::escape(out, strio::string(buf))?;
	};

	// TODO: More detailed formatter which can find aliases nested deeper in
	// other types and highlight more keywords, like const
	let z = 0z;
	match (_type._type) {
		_: ast::builtin_type => {
			z += fmt::fprint(out, "<span class='type'>")?;
			z += html::escape(out, strio::string(buf))?;
			z += fmt::fprintf(out, "</span>")?;
		},
		* => z += html::escape(out, strio::string(buf))?,
	};
	z;
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

fn head(ident: ast::ident) (void | error) = {
	const ident = unparse::identstr(ident);
	defer free(ident);

	// TODO: Fix up breadcrumb
	// TODO: Move me to +embed?
	fmt::printfln("<!doctype html>
<html lang='en'>
<meta charset='utf-8' />
<title>{} — Hare documentation", ident)?;
	fmt::println("</title>
<style>
body {
	font-family: sans-serif;
	line-height: 1.3;
	margin: 0 auto;
}

nav:not(#TableOfContents) {
	max-width: 1000px;
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

.heading-extra {
	align-self: flex-end;
	flex-grow: 1;
	text-align: right;
	font-size: 0.8rem;
	color: #444;
}

@media(max-width: 1000px) {
	main {
		padding: 0;
	}
}
</style>
<nav>
	<img
		src='https://harelang.org/mascot.jpg'
		alt='An inked drawing of the Hare mascot, a fuzzy rabbit'
		width='128' height='128' />
	<h1>Hare documentation</h1>
	<ul>
		<li>
			<a href='https://harelang.org'>Home</a>
		</li>
		<li>
			<a href='#'>stdlib</a> »
			<a href='#'>hash</a>::fnv
		</li>
	</ul>
</nav>
<main>
")?;
	return;
};
