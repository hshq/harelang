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
	import: ast::import,
) (size | io::error) = {
	let n = 0z;
	let ctx = context {
		out = out,
		stack = &stack {
			cur = &import,
			...
		},
		...
	};
	n += syn(&ctx, "use", synkind::KEYWORD)?;
	n += space(&ctx)?;
	if (import.mode & ast::import_mode::ALIAS != 0) {
		n += syn(&ctx, import.alias, synkind::IMPORT_ALIAS)?;
		n += space(&ctx)?;
		n += syn(&ctx, "=", synkind::OPERATOR)?;
		n += space(&ctx)?;
	};
	n += _ident(&ctx, syn, import.ident, synkind::IDENT)?;
	if (import.mode & ast::import_mode::MEMBERS != 0) {
		n += syn(&ctx, "::", synkind::IDENT)?;
		n += syn(&ctx, "{", synkind::PUNCTUATION)?;
		for (let i = 0z; i < len(import.objects); i += 1) {
			match (import.objects[i].0) {
			case let s: str =>
				n += syn(&ctx, s, synkind::IMPORT_ALIAS)?;
				n += space(&ctx)?;
				n += syn(&ctx, "=", synkind::OPERATOR)?;
				n += space(&ctx)?;
			case void => void;
			};
			n += syn(&ctx, import.objects[i].1,
				synkind::SECONDARY)?;
			if (i + 1 < len(import.objects)) {
				n += syn(&ctx, ",", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
			};
		};
		n += syn(&ctx, "}", synkind::PUNCTUATION)?;
	} else if (import.mode & ast::import_mode::WILDCARD != 0) {
		n += syn(&ctx, "::", synkind::IDENT)?;
		n += syn(&ctx, "*", synkind::IDENT)?;
	};
	n += syn(&ctx, ";", synkind::PUNCTUATION)?;
	return n;
};

@test fn import() void = {
	let tests: [_](ast::import, str) = [
		(ast::import {
			ident = ["foo", "bar", "baz"],
			...
		}, "use foo::bar::baz;"),
		(ast::import {
			mode = ast::import_mode::ALIAS,
			ident = ["foo"],
			alias = "bar",
			...
		}, "use bar = foo;"),
		(ast::import {
			mode = ast::import_mode::MEMBERS,
			ident = ["foo"],
			objects = [(void, "bar"), (void, "baz")],
			...
		},  "use foo::{bar, baz};"),
		(ast::import {
			mode = ast::import_mode::WILDCARD,
			ident = ["foo", "bar"],
			...
		},  "use foo::bar::*;"),
		(ast::import {
			mode = ast::import_mode::MEMBERS | ast::import_mode::ALIAS,
			ident = ["foo"],
			alias = "quux",
			objects = [(void, "bar"), (void, "baz")],
			...
		},  "use quux = foo::{bar, baz};"),
		(ast::import {
			mode = ast::import_mode::MEMBERS,
			ident = ["foo"],
			objects = [("alias", "bar"), (void, "baz")],
			...
		},  "use foo::{alias = bar, baz};"),
		(ast::import {
			mode = ast::import_mode::MEMBERS | ast::import_mode::ALIAS,
			ident = ["foo"],
			alias = "quux",
			objects = [("alias1", "bar"), ("alias2", "baz")],
			...
		},  "use quux = foo::{alias1 = bar, alias2 = baz};"),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let buf = memio::dynamic();
		import(&buf, &syn_nowrap, tests[i].0)!;
		let s = memio::string(&buf)!;
		assert(s == tests[i].1);
		free(s);
	};
};
