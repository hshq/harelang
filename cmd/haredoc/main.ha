// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use cmd::haredoc::doc;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use hare::unparse;
use io;
use memio;
use os;
use os::exec;
use path;
use strconv;
use strings;

const help: []getopt::help = [
	"reads and formats Hare documentation",
	('a', "show undocumented members (only applies to -Ftty)"),
	('t', "disable HTML template (requires postprocessing)"),
	('F', "format", "specify output format (tty or html)"),
	('T', "tagset", "set/unset build tags"),
	"[identifier|path]",
];

export fn main() void = {
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	match (doc(os::args[0], &cmd)) {
	case void => void;
	case let e: doc::error =>
		fmt::fatal(doc::strerror(e));
	case let e: exec::error =>
		fmt::fatal(exec::strerror(e));
	case let e: fs::error =>
		fmt::fatal(fs::strerror(e));
	case let e: io::error =>
		fmt::fatal(io::strerror(e));
	case let e: module::error =>
		fmt::fatal(module::strerror(e));
	case let e: path::error =>
		fmt::fatal(path::strerror(e));
	case let e: parse::error =>
		fmt::fatal(parse::strerror(e));
	case let e: strconv::error =>
		fmt::fatal(strconv::strerror(e));
	};
};

fn doc(name: str, cmd: *getopt::command) (void | error) = {
	let html = false;
	let template = true;
	let show_undocumented = false;
	let tags: []str = default_tags();
	defer free(tags);

	for (let (k, v) .. cmd.opts) {
		switch (k) {
		case 'F' =>
			switch (v) {
			case "tty" =>
				html = false;
			case "html" =>
				html = true;
			case =>
				fmt::fatal("Invalid format", v);
			};
		case 'T' =>
			merge_tags(&tags, v)?;
		case 't' =>
			template = false;
		case 'a' =>
			show_undocumented = true;
		case => abort();
		};
	};

	if (show_undocumented && html) {
		fmt::fatal("Option -a must be used only with -Ftty");
	};

	if (len(cmd.args) > 1) {
		getopt::printusage(os::stderr, os::args[0], help)!;
		os::exit(os::status::FAILURE);
	};

	let ctx = module::context {
		harepath = harepath(),
		harecache = harecache(),
		tags = tags,
	};

	let declpath = "";
	defer free(declpath);
	let declsrcs = module::srcset { ... };
	defer module::finish_srcset(&declsrcs);
	let modpath = "";
	defer free(modpath);
	let modsrcs = module::srcset { ... };
	defer module::finish_srcset(&modsrcs);
	let id: ast::ident = [];
	defer free(id);

	if (len(cmd.args) == 0) {
		let (p, s) = module::find(&ctx, []: ast::ident)?;
		modpath = strings::dup(p);
		modsrcs = s;
	} else match (parseident(cmd.args[0])) {
	case let ident: (ast::ident, bool) =>
		id = ident.0;
		const trailing = ident.1;
		if (!trailing) {
			// check if it's an ident inside a module
			match (module::find(&ctx, id[..len(id)-1])) {
			case let s: (str, module::srcset) =>
				declpath = strings::dup(s.0);
				declsrcs = s.1;
			case let e: module::error =>
				module::finish_error(e);
			};
		};
		// check if it's a module
		match (module::find(&ctx, id)) {
		case let s: (str, module::srcset) =>
			modpath = strings::dup(s.0);
			modsrcs = s.1;
		case let e: module::error =>
			module::finish_error(e);
			if (declpath == "") {
				const id = unparse::identstr(id);
				fmt::fatalf("Could not find {}{}", id,
					if (trailing) "::" else "");
			};
		};
	case void =>
		let buf = path::init(cmd.args[0])?;
		let (p, s) = module::find(&ctx, &buf)?;
		modpath = strings::dup(p);
		modsrcs = s;
	};

	let decls: []ast::decl = [];
	defer {
		for (let decl .. decls) {
			ast::decl_finish(decl);
		};
		free(decls);
	};

	if (declpath != "") {
		for (let ha .. declsrcs.ha) {
			let u = doc::scan(ha)?;
			ast::imports_finish(u.imports);
			append(decls, u.decls...);
		};

		let matching: []ast::decl = [];
		let notmatching: []ast::decl = [];

		for (let decl .. decls) {
			if (has_decl(decl, id[len(id) - 1])) {
				append(matching, decl);
			} else {
				append(notmatching, decl);
			};
		};
		get_init_funcs(&matching, &notmatching);

		for (let decl .. notmatching) {
			ast::decl_finish(decl);
		};
		free(notmatching);
		free(decls);
		decls = matching;

		if (len(matching) == 0) {
			if (modpath == "") {
				const id = unparse::identstr(id);
				fmt::fatalf("Could not find {}", id);
			};
		} else {
			show_undocumented = true;
		};
	};

	let readme: (io::file | void) = void;
	defer match (readme) {
	case void => void;
	case let f: io::file =>
		io::close(f)!;
	};

	const ambiguous = modpath != "" && len(decls) > 0;

	if (len(decls) == 0) {
		for (let ha .. modsrcs.ha) {
			let u = doc::scan(ha)?;
			ast::imports_finish(u.imports);
			append(decls, u.decls...);
		};

		const rpath = path::init(modpath, "README")!;
		match (os::open(path::string(&rpath))) {
		case let f: io::file =>
			readme = f;
		case fs::error => void;
		};
	};

	const submods: []str = if (!ambiguous && modpath != "") {
		yield match (doc::submodules(modpath, show_undocumented)) {
		case let s: []str =>
			yield s;
		case doc::error =>
			yield [];
		};
	} else [];
	const srcs = if (!ambiguous && modpath != "") modsrcs else declsrcs;
	const summary = doc::sort_decls(decls);
	defer doc::finish_summary(summary);
	const ctx = doc::context {
		mctx = &ctx,
		ident = id,
		tags = tags,
		ambiguous = ambiguous,
		srcs = srcs,
		submods = submods,
		summary = summary,
		template = template,
		readme = readme,
		show_undocumented = show_undocumented,
		out = os::stdout,
		pager = void,
	};

	const ret = if (html) {
		yield doc::emit_html(&ctx);
	} else {
		ctx.out = init_tty(&ctx);
		yield doc::emit_tty(&ctx);
	};

	io::close(ctx.out)!;
	match (ctx.pager) {
	case void => void;
	case let proc: exec::process =>
		exec::wait(&proc)!;
	};

	// TODO: remove ? (harec bug workaround)
	return ret?;
};

// Nearly identical to parse::identstr, except alphanumeric lexical tokens are
// converted to strings and there must be no trailing tokens that don't belong
// to the ident in the string. For example, this function will parse `rt::abort`
// as a valid identifier.
fn parseident(in: str) ((ast::ident, bool) | void) = {
	let buf = memio::fixed(strings::toutf8(in));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<string>");
	let success = false;
	let ident: ast::ident = [];
	defer if (!success) ast::ident_free(ident);
	let trailing = false;
	let z = 0z;
	for (true) {
		const tok = lex::lex(&lexer)!;
		const name = if (tok.0 == lex::ltok::NAME) {
			yield tok.1 as str;
		} else if (tok.0 < lex::ltok::LAST_KEYWORD) {
			yield strings::dup(lex::tokstr(tok));
		} else if (tok.0 == lex::ltok::EOF && len(ident) > 0) {
			trailing = true;
			break;
		} else {
			lex::unlex(&lexer, tok);
			return;
		};
		append(ident, name);
		z += len(name);
		const tok = lex::lex(&lexer)!;
		switch (tok.0) {
		case lex::ltok::EOF =>
			break;
		case lex::ltok::DOUBLE_COLON =>
			z += 1;
		case =>
			lex::unlex(&lexer, tok);
			return;
		};
	};
	if (z > ast::IDENT_MAX) {
		return;
	};
	success = true;
	return (ident, trailing);
};

fn init_tty(ctx: *doc::context) io::handle = {
	const pager = match (os::getenv("PAGER")) {
	case let name: str =>
		yield match (exec::cmd(name)) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			return os::stdout;
		};
	case void =>
		yield match (exec::cmd("less", "-R")) {
		case let cmd: exec::command =>
			yield cmd;
		case exec::error =>
			yield match (exec::cmd("more", "-R")) {
			case let cmd: exec::command =>
				yield cmd;
			case exec::error =>
				return os::stdout;
			};
		};
	};

	const pipe = exec::pipe();
	defer io::close(pipe.0)!;
	exec::addfile(&pager, os::stdin_file, pipe.0);
	// Get raw flag in if possible
	exec::setenv(&pager, "LESS", os::tryenv("LESS", "FRX"))!;
	exec::setenv(&pager, "MORE", os::tryenv("MORE", "R"))!;
	ctx.pager = exec::start(&pager)!;
	return pipe.1;
};

fn has_decl(decl: ast::decl, name: str) bool = {
	if (!decl.exported) {
		return false;
	};

	match (decl.decl) {
	case let consts: []ast::decl_const =>
		for (let d .. consts) {
			if (len(d.ident) == 1 && d.ident[0] == name) {
				return true;
			};
		};
	case let d: ast::decl_func =>
		if (len(d.ident) == 1 && d.ident[0] == name) {
			return true;
		};
		let tok = strings::rtokenize(d.symbol, ".");
		match (strings::next_token(&tok)) {
		case done => void;
		case let s: str =>
			return s == name;
		};
	case let globals: []ast::decl_global =>
		for (let d .. globals) {
			if (len(d.ident) == 1 && d.ident[0] == name) {
				return true;
			};
			let tok = strings::rtokenize(d.symbol, ".");
			match (strings::next_token(&tok)) {
			case done => void;
			case let s: str =>
				return s == name;
			};
		};
	case let types: []ast::decl_type =>
		for (let d .. types) {
			if (len(d.ident) == 1 && d.ident[0] == name) {
				return true;
			};
		};
	case ast::assert_expr => void;
	};
	return false;
};

@test fn parseident() void = {
	let (ident, trailing) = parseident("hare::lex") as (ast::ident, bool);
	defer ast::ident_free(ident);
	assert(ast::ident_eq(ident, ["hare", "lex"]));
	assert(!trailing);

	let (ident, trailing) = parseident("rt::abort") as (ast::ident, bool);
	defer ast::ident_free(ident);
	assert(ast::ident_eq(ident, ["rt", "abort"]));
	assert(!trailing);

	let (ident, trailing) = parseident("foo::bar::") as (ast::ident, bool);
	defer ast::ident_free(ident);
	assert(ast::ident_eq(ident, ["foo", "bar"]));
	assert(trailing);
	assert(parseident("strings::dup*{}&@") is void);
	assert(parseident("") is void);
	assert(parseident("::") is void);
};

fn get_init_funcs(matching: *[]ast::decl, notmatching: *[]ast::decl) void = {
	if (len(matching) != 1) {
		return;
	};
	let ident = match (matching[0].decl) {
	case let d: []ast::decl_type =>
		if (len(d) != 1 || len(d[0].ident) != 1) {
			return;
		};
		if (d[0]._type.flags & ast::type_flag::ERROR != 0) {
			return;
		};
		match (d[0]._type.repr) {
		case let repr: ast::builtin_type =>
			if (repr == ast::builtin_type::VOID) {
				return;
			};
		case => void;
		};
		yield d[0].ident;
	case =>
		return;
	};

	for (let i = 0z; i < len(notmatching); i += 1) {
		let _type = match (notmatching[i].decl) {
		case let d: []ast::decl_const =>
			yield match (d[0]._type) {
			case let t: *ast::_type =>
				yield t;
			case null =>
				continue;
			};
		case let d: []ast::decl_global =>
			yield match (d[0]._type) {
			case let t: *ast::_type =>
				yield t;
			case null =>
				continue;
			};
		case let d: ast::decl_func =>
			let _type = d.prototype.repr as ast::func_type;
			yield _type.result;
		case =>
			continue;
		};

		if (is_init_type(ident, _type)) {
			append(matching, notmatching[i]);
			delete(notmatching[i]);
			i -= 1;
		};
	};
};

fn is_init_type(ident: ast::ident, _type: *ast::_type) bool = {
	let type_ident = match (_type.repr) {
	case let repr: ast::alias_type =>
		yield repr.ident;
	case let repr: ast::list_type =>
		if (!(repr.length is ast::len_slice)) {
			return false;
		};
		yield match (repr.members.repr) {
		case let repr: ast::alias_type =>
			yield repr.ident;
		case =>
			return false;
		};
	case let repr: ast::pointer_type =>
		yield match (repr.referent.repr) {
		case let repr: ast::alias_type =>
			yield repr.ident;
		case =>
			return false;
		};
	case let repr: ast::tagged_type =>
		for (let t .. repr) {
			if (is_init_type(ident, t)) {
				return true;
			};
		};
		return false;
	case =>
		return false;
	};

	return ast::ident_eq(ident, type_ident);
};
