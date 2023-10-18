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
	for (let i = 0z; i < len(summary.constants); i += 1) {
		const name = decl_ident(&summary.constants[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		const name = decl_ident(&summary.errors[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.types); i += 1) {
		const name = decl_ident(&summary.types[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		const name = decl_ident(&summary.globals[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		const name = decl_ident(&summary.funcs[i])[0];
		if (name == what[0]) {
			return true;
		};
	};

	return false;
};

fn lookup_local_enum(ctx: *context, what: ast::ident) (ast::ident | void) = {
	for (let i = 0z; i < len(ctx.summary.types); i += 1) {
		const decl = &ctx.summary.types[i];
		const name = decl_ident(decl)[0];
		if (name == what[0]) {
			const t = (decl.decl as []ast::decl_type)[0];
			const e = match (t._type.repr) {
			case let e: ast::enum_type =>
				yield e;
			case =>
				return;
			};
			for (let i = 0z; i < len(e.values); i += 1) {
				if (e.values[i].name == what[1]) {
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
		for (let i = 0z; i < len(decls); i += 1) {
			ast::decl_finish(decls[i]);
		};
		free(decls);
	};
	for (let i = 0z; i < len(srcs.ha); i += 1) {
		const in = srcs.ha[i];
		let u = scan(in)?;
		append(decls, u.decls...);
	};

	for (let i = 0z; i < len(decls); i += 1) {
		const decl = match (decls[i].decl) {
		case let t: []ast::decl_type =>
			yield t;
		case =>
			continue;
		};
		for (let i = 0z; i < len(decl); i += 1) {
			if (decl[i].ident[0] == decl_name) {
				const e = match (decl[i]._type.repr) {
				case let e: ast::enum_type =>
					yield e;
				case =>
					abort();
				};
				for (let i = 0z; i < len(e.values); i += 1) {
					if (e.values[i].name == member) {
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
