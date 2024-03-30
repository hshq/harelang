// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use io;
use memio;

// Unparses a [[hare::ast::import]].
export fn import(
	out: io::handle,
	syn: *synfunc,
	import: *ast::import,
) (size | io::error) = {
	let n = 0z;
	let ctx = context {
		out = out,
		stack = &stack {
			cur = import,
			...
		},
		...
	};
	n += syn(&ctx, "use", synkind::KEYWORD)?;
	n += space(&ctx)?;
	match (import.bindings) {
	case void =>
		n += _ident(&ctx, syn, import.ident, synkind::IDENT)?;
	case let alias: ast::import_alias =>
		n += syn(&ctx, alias, synkind::IMPORT_ALIAS)?;
		n += space(&ctx)?;
		n += syn(&ctx, "=", synkind::OPERATOR)?;
		n += space(&ctx)?;
		n += _ident(&ctx, syn, import.ident, synkind::IDENT)?;
	case let objects: ast::import_members =>
		n += _ident(&ctx, syn, import.ident, synkind::IDENT)?;
		n += syn(&ctx, "::", synkind::IDENT)?;
		n += syn(&ctx, "{", synkind::PUNCTUATION)?;
		for (let i = 0z; i < len(objects); i += 1) {
			n += syn(&ctx, objects[i], synkind::SECONDARY)?;
			if (i + 1 < len(objects)) {
				n += syn(&ctx, ",", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
			};
		};
		n += syn(&ctx, "}", synkind::PUNCTUATION)?;
	case ast::import_wildcard =>
		n += _ident(&ctx, syn, import.ident, synkind::IDENT)?;
		n += syn(&ctx, "::", synkind::IDENT)?;
		n += syn(&ctx, "*", synkind::PUNCTUATION)?;
	};
	n += syn(&ctx, ";", synkind::PUNCTUATION)?;
	return n;
};

@test fn import() void = {
	let tests: [_](ast::import, str) = [
		(ast::import {
			ident = ["foo", "bar", "baz"],
			bindings = void,
			...
		}, "use foo::bar::baz;"),
		(ast::import {
			ident = ["foo"],
			bindings = "bar",
			...
		}, "use bar = foo;"),
		(ast::import {
			ident = ["foo"],
			bindings = ["bar", "baz"],
			...
		},  "use foo::{bar, baz};"),
		(ast::import {
			ident = ["foo", "bar"],
			bindings = ast::import_wildcard,
			...
		},  "use foo::bar::*;"),
	];
	for (let (ast_import, str_import) .. tests) {
		let buf = memio::dynamic();
		import(&buf, &syn_nowrap, &ast_import)!;
		let s = memio::string(&buf)!;
		assert(s == str_import);
		free(s);
	};
};
