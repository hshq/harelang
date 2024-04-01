// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use io;
use os;
use path;
use types;

type symkind = enum {
	LOCAL,
	MODULE,
	SYMBOL,
	ENUM_LOCAL,
	ENUM_REMOTE,
};

// Resolves a reference. Given an identifier, determines if it refers to a local
// symbol, a module, or a symbol in a remote module, then returns this
// information combined with a corrected ident if necessary.
fn resolve(ctx: *context, what: ast::ident) ((ast::ident, symkind) | void | error) = {
	if (is_local(ctx, what)) {
		return (what, symkind::LOCAL);
	};

	if (len(what) > 1) {
		// Look for symbol in remote module
		let partial = what[..len(what) - 1];

		match (module::find(ctx.mctx, partial)) {
		case let r: (str, module::srcset) =>
			module::finish_srcset(&r.1);
			return (what, symkind::SYMBOL);
		case module::error => void;
		};
	};
	if (len(what) == 2) {
		match (lookup_local_enum(ctx, what)) {
		case let id: ast::ident =>
			return (id, symkind::ENUM_LOCAL);
		case => void;
		};
	};
	if (len(what) > 2) {
		match (lookup_remote_enum(ctx, what)?) {
		case let id: ast::ident =>
			return (id, symkind::ENUM_REMOTE);
		case => void;
		};
	};

	match (module::find(ctx.mctx, what)) {
	case let r: (str, module::srcset) =>
		module::finish_srcset(&r.1);
		return (what, symkind::MODULE);
	case module::error => void;
	};

	return;
};

fn is_local(ctx: *context, what: ast::ident) bool = {
	if (len(what) != 1) {
		return false;
	};

	const summary = ctx.summary;
	for (let c &.. summary.constants) {
		const name = decl_ident(c)[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let e &.. summary.errors) {
		const name = decl_ident(e)[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let t &.. summary.types) {
		const name = decl_ident(t)[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let g &.. summary.globals) {
		const name = decl_ident(g)[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let f &.. summary.funcs) {
		const name = decl_ident(f)[0];
		if (name == what[0]) {
			return true;
		};
	};

	return false;
};

fn lookup_local_enum(ctx: *context, what: ast::ident) (ast::ident | void) = {
	for (let decl &.. ctx.summary.types) {
		const name = decl_ident(decl)[0];
		if (name == what[0]) {
			const t = (decl.decl as []ast::decl_type)[0];
			const e = match (t._type.repr) {
			case let e: ast::enum_type =>
				yield e;
			case =>
				return;
			};
			for (let value .. e.values) {
				if (value.name == what[1]) {
					return what;
				};
			};
		};
	};
};

fn lookup_remote_enum(ctx: *context, what: ast::ident) (ast::ident | void | error) = {
	// mod::decl_name::member
	const mod = what[..len(what) - 2];
	const decl_name = what[len(what) - 2];
	const member = what[len(what) - 1];

	const srcs = match (module::find(ctx.mctx, mod)) {
	case let s: (str, module::srcset) =>
		yield s.1;
	case let e: module::error =>
		module::finish_error(e);
		return void;
	};

	// This would take a lot of memory to load
	let decls: []ast::decl = [];
	defer {
		for (let decl .. decls) {
			ast::decl_finish(decl);
		};
		free(decls);
	};
	for (let in .. srcs.ha) {
		let u = scan(in)?;
		append(decls, u.decls...);
	};

	for (let decl .. decls) {
		const decls = match (decl.decl) {
		case let t: []ast::decl_type =>
			yield t;
		case =>
			continue;
		};

		for (let d .. decls) {
			if (d.ident[0] == decl_name) {
				const e = match (d._type.repr) {
				case let e: ast::enum_type =>
					yield e;
				case =>
					abort();
				};
				for (let value .. e.values) {
					if (value.name == member) {
						return what;
					};
				};
			};
		};
	};
};

export fn scan(path: str) (ast::subunit | error) = {
	const input = match (os::open(path)) {
	case let f: io::file =>
		yield f;
	case let err: fs::error =>
		fmt::fatalf("Error reading {}: {}", path, fs::strerror(err));
	};
	defer io::close(input)!;
	let sc = bufio::newscanner(input, types::SIZE_MAX);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, path, lex::flag::COMMENTS);
	return parse::subunit(&lexer)?;
};
