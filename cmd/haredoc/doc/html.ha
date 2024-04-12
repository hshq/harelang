// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

// Note: ast::ident should never have to be escaped
use encoding::utf8;
use fmt;
use hare::ast;
use hare::lex;
use hare::parse::doc;
use hare::unparse;
use io;
use memio;
use net::ip;
use net::uri;
use path;
use strings;

// Prints a string to an output handle, escaping any of HTML's reserved
// characters.
fn html_escape(out: io::handle, in: str) (size | io::error) = {
	let z = 0z;
	let iter = strings::iter(in);
	for (let rn => strings::next(&iter)) {
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
	return z;
};

@test fn html_escape() void = {
	let sink = memio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "hello world!")!;
	assert(memio::string(&sink)! == "hello world!");

	let sink = memio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "\"hello world!\"")!;
	assert(memio::string(&sink)! == "&quot;hello world!&quot;");

	let sink = memio::dynamic();
	defer io::close(&sink)!;
	html_escape(&sink, "<hello & 'world'!>")!;
	assert(memio::string(&sink)! == "&lt;hello &amp; &apos;world&apos;!&gt;");
};

// Formats output as HTML
export fn emit_html(ctx: *context) (void | error) = {
	const decls = ctx.summary;
	const ident = unparse::identstr(ctx.ident);
	defer free(ident);

	if (ctx.template) {
		head(ctx.ident)?;
	};

	if (len(ident) == 0) {
		fmt::fprintf(ctx.out, "<h2>The Hare standard library <span class='heading-extra'>")?;
	} else {
		fmt::fprintf(ctx.out, "<h2><span class='heading-body'>{}</span><span class='heading-extra'>", ident)?;
	};
	for (let tag .. ctx.tags) {
		fmt::fprintf(ctx.out, "+{} ", tag)?;
	};
	fmt::fprintln(ctx.out, "</span></h2>")?;

	match (ctx.readme) {
	case void => void;
	case let f: io::file =>
		fmt::fprintln(ctx.out, "<div class='readme'>")?;
		markup_html(ctx, f, lex::location {
			path = "README", // XXX: this is meh
			line = 1,
			col = 1,
		})?;
		fmt::fprintln(ctx.out, "</div>")?;
	};

	let identpath = strings::join("/", ctx.ident...);
	defer free(identpath);

	if (len(ctx.submods) != 0) {
		if (len(ctx.ident) == 0) {
			fmt::fprintln(ctx.out, "<h3>Modules</h3>")?;
		} else {
			fmt::fprintln(ctx.out, "<h3>Submodules</h3>")?;
		};
		fmt::fprintln(ctx.out, "<ul class='submodules'>")?;
		for (let submodule .. ctx.submods) {
			let path = path::init("/", identpath, submodule)!;

			fmt::fprintf(ctx.out, "<li><a href='")?;
			html_escape(ctx.out, path::string(&path))?;
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
		for (let t &.. decls.types) {
			details(ctx, t)?;
		};
	};

	if (len(decls.errors) != 0) {
		fmt::fprintln(ctx.out, "<h3>Errors</h3>")?;
		for (let e &.. decls.errors) {
			details(ctx, e)?;
		};
	};

	if (len(decls.constants) != 0) {
		fmt::fprintln(ctx.out, "<h3>Constants</h3>")?;
		for (let c &.. decls.constants) {
			details(ctx, c)?;
		};
	};

	if (len(decls.globals) != 0) {
		fmt::fprintln(ctx.out, "<h3>Globals</h3>")?;
		for (let g &.. decls.globals) {
			details(ctx, g)?;
		};
	};

	if (len(decls.funcs) != 0) {
		fmt::fprintln(ctx.out, "<h3>Functions</h3>")?;
		for (let f &.. decls.funcs) {
			details(ctx, f)?;
		};
	};
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
		unparse::decl(out, &syn_centry, &decls[i])?;
		fmt::fprintln(out)?;
	};
	fmt::fprint(out, "</pre>")?;
	return;
};

fn details(ctx: *context, decl: *ast::decl) (void | error) = {
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
		case ast::assert_expr => abort();
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
	unparse::decl(ctx.out, &syn_html, decl)?;
	fmt::fprintln(ctx.out, "</pre>")?;

	if (len(decl.docs) != 0) {
		const trimmed = trim_comment(decl.docs);
		defer free(trimmed);
		const buf = strings::toutf8(trimmed);
		markup_html(ctx, &memio::fixed(buf), decl.start)?;
	} else {
		fmt::fprintln(ctx.out, "</details>")?;
	};

	fmt::fprintln(ctx.out, "</section>")?;
	return;
};

fn html_decl_ref(ctx: *context, ref: ast::ident) (void | error) = {
	const ik =
		match (resolve(ctx, ref)?) {
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
		let ipath = strings::join("/", id...);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}' class='ref'>{}::</a>",
			ipath, ident)?;
	case symkind::SYMBOL =>
		let ipath = strings::join("/", id[..len(id) - 1]...);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}#{}' class='ref'>{}</a>",
			ipath, id[len(id) - 1], ident)?;
	case symkind::ENUM_LOCAL =>
		fmt::fprintf(ctx.out, "<a href='#{}' class='ref'>{}</a>",
			id[len(id) - 2], ident)?;
	case symkind::ENUM_REMOTE =>
		let ipath = strings::join("/", id[..len(id) - 2]...);
		defer free(ipath);
		fmt::fprintf(ctx.out, "<a href='/{}#{}' class='ref'>{}</a>",
			ipath, id[len(id) - 2], ident)?;
	};
	free(ident);
};

fn html_mod_ref(ctx: *context, ref: ast::ident) (void | error) = {
	const ident = unparse::identstr(ref);
	defer free(ident);
	let ipath = strings::join("/", ref...);
	defer free(ipath);
	fmt::fprintf(ctx.out, "<a href='/{}' class='ref'>{}::</a>",
		ipath, ident)?;
};


fn html_paragraph(ctx: *context, p: doc::paragraph) (void | error) = {
	for (let elem .. p) {
		match (elem) {
		case let s: str =>
			match (uri::parse(s)) {
			case let uri: uri::uri =>
				defer uri::finish(&uri);
				if (uri.host is ip::addr || len(uri.host as str) > 0) {
					fmt::fprint(ctx.out, "<a rel='nofollow noopener' href='")?;
					uri::fmt(ctx.out, &uri)?;
					fmt::fprint(ctx.out, "'>")?;
					html_escape(ctx.out, s)?;
					fmt::fprint(ctx.out, "</a>")?;
				} else {
					html_escape(ctx.out, s)?;
				};
			case uri::invalid =>
				html_escape(ctx.out, s)?;
			};
		case let d: doc::decl_ref =>
			html_decl_ref(ctx, d)?;
		case let m: doc::mod_ref =>
			html_mod_ref(ctx, m)?;
		};
	};
};

fn markup_html(
	ctx: *context,
	in: io::handle,
	loc: lex::location,
) (void | error) = {
	const doc = match (doc::parse(in, loc)) {
	case let doc: doc::doc =>
		yield doc;
	case let err: lex::syntax =>
		const err = lex::strerror(err);
		fmt::errorln("Warning:", err)?;
		fmt::fprint(ctx.out, "<p class='ref invalid'>Can't parse docs: ")?;
		html_escape(ctx.out, err)?;
		fmt::fprintln(ctx.out)?;
		return;
	};
	defer doc::freeall(doc);

	for (let elem .. doc) {
		match (elem) {
		case let p: doc::paragraph =>
			fmt::fprint(ctx.out, "<p>")?;
			html_paragraph(ctx, p)?;
			fmt::fprintln(ctx.out)?;
		case let l: doc::list =>
			fmt::fprintln(ctx.out, "<ul>")?;
			for (let entry .. l) {
				fmt::fprint(ctx.out, "<li>")?;
				html_paragraph(ctx, entry)?;
				fmt::fprintln(ctx.out)?;
			};
			fmt::fprintln(ctx.out, "</ul>")?;
		case let c: doc::code_sample =>
			fmt::fprint(ctx.out, "<pre class='sample'>")?;
			html_escape(ctx.out, c)?;
			fmt::fprintln(ctx.out, "</pre>")?;
		};
	};
};

fn syn_centry(
	ctx: *unparse::context,
	s: str,
	kind: unparse::synkind,
) (size | io::error) = {
	let z = 0z;
	switch (kind) {
	case unparse::synkind::CONSTANT,
		unparse::synkind::FUNCTION,
		unparse::synkind::GLOBAL,
		unparse::synkind::TYPEDEF =>
		z += fmt::fprint(ctx.out, "<a href='#")?;
		z += html_escape(ctx.out, s)?;
		z += fmt::fprint(ctx.out, "'>")?;
		z += html_escape(ctx.out, s)?;
		z += fmt::fprint(ctx.out, "</a>")?;
		ctx.linelen += len(s);
		return z;
	case =>
		return syn_html(ctx, s, kind);
	};
};

fn syn_html(
	ctx: *unparse::context,
	s: str,
	kind: unparse::synkind,
) (size | io::error) = {
	let z = 0z;
	const span = switch (kind) {
	case unparse::synkind::COMMENT =>
		const stack = ctx.stack as *unparse::stack;
		if (stack.cur is *ast::decl) {
			// doc comment is unparsed separately later
			return 0z;
		};
		z += fmt::fprint(ctx.out, "<span class='comment'>")?;
		yield true;
	case unparse::synkind::KEYWORD =>
		z += fmt::fprint(ctx.out, "<span class='keyword'>")?;
		yield true;
	case unparse::synkind::TYPE =>
		z += fmt::fprint(ctx.out, "<span class='type'>")?;
		yield true;
	case =>
		yield false;
	};

	z += html_escape(ctx.out, s)?;
	ctx.linelen += len(s);

	if (span) {
		z += fmt::fprint(ctx.out, "</span>")?;
	};
	return z;
};

fn breadcrumb(ident: ast::ident) str = {
	if (len(ident) == 0) {
		return "";
	};
	let buf = memio::dynamic();
	fmt::fprintf(&buf, "<a href='/'>stdlib</a> » ")!;
	for (let i = 0z; i < len(ident) - 1; i += 1) {
		let ipath = strings::join("/", ident[..i+1]...);
		defer free(ipath);
		fmt::fprintf(&buf, "<a href='/{}'>{}</a>::", ipath, ident[i])!;
	};
	fmt::fprint(&buf, ident[len(ident) - 1])!;
	return memio::string(&buf)!;
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
