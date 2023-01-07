// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2022 Alexey Yerin <yyp@disroot.org>
use fmt;
use hare::ast;
use hare::module;
use path;

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
fn resolve(ctx: *context, what: ast::ident) ((ast::ident, symkind) | void) = {
	if (is_local(ctx, what)) {
		return (what, symkind::LOCAL);
	};

	if (len(what) > 1) {
		// Look for symbol in remote module
		let partial = what[..len(what) - 1];

		match (module::lookup(ctx.mctx, partial)) {
		case let ver: module::version =>
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
		match (lookup_remote_enum(ctx, what)) {
		case let id: ast::ident =>
			return (id, symkind::ENUM_REMOTE);
		case => void;
		};
	};

	match (module::lookup(ctx.mctx, what)) {
	case let ver: module::version =>
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
		const name = decl_ident(summary.constants[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		const name = decl_ident(summary.errors[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.types); i += 1) {
		const name = decl_ident(summary.types[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		const name = decl_ident(summary.globals[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		const name = decl_ident(summary.funcs[i])[0];
		if (name == what[0]) {
			return true;
		};
	};

	return false;
};

fn lookup_local_enum(ctx: *context, what: ast::ident) (ast::ident | void) = {
	for (let i = 0z; i < len(ctx.summary.types); i += 1) {
		const decl = ctx.summary.types[i];
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

fn lookup_remote_enum(ctx: *context, what: ast::ident) (ast::ident | void) = {
	// mod::decl_name::member
	const mod = what[..len(what) - 2];
	const decl_name = what[len(what) - 2];
	const member = what[len(what) - 1];

	const version = match (module::lookup(ctx.mctx, mod)) {
	case let ver: module::version =>
		yield ver;
	case module::error =>
		abort();
	};

	// This would take a lot of memory to load
	let decls: []ast::decl = [];
	defer {
		for (let i = 0z; i < len(decls); i += 1) {
			ast::decl_finish(decls[i]);
		};
		free(decls);
	};
	for (let i = 0z; i < len(version.inputs); i += 1) {
		const in = version.inputs[i];
		const ext = path::extension(in.path);
		if (ext.1 != ".ha") {
			continue;
		};
		match (scan(in.path)) {
		case let u: ast::subunit =>
			append(decls, u.decls...);
		case let err: error =>
			fmt::fatal("Error:", strerror(err));
		};
	};

	for (let i = 0z; i < len(decls); i += 1) {
		const decl = match (decls[i].decl) {
		case let t: []ast::decl_type =>
			yield t;
		case => continue;
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
