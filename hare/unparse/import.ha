// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use io;
use hare::ast;
use memio;

// Unparses a [[hare::ast::import]].
export fn import(out: io::handle, import: ast::import) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "use ")?;
	if (import.mode & ast::import_mode::ALIAS != 0) {
		n += fmt::fprint(out, import.alias, "= ")?;
	};
	n += ident(out, import.ident)?;
	if (import.mode & ast::import_mode::MEMBERS != 0) {
		n += fmt::fprint(out, "::{")?;
		for (let i = 0z; i < len(import.objects); i += 1) {
			let tup = match (import.objects[i].0) {
			case void =>
				yield ("", "");
			case let s: str =>
				yield (s, " = ");
			};
			n += fmt::fprintf(out, "{}{}{}{}", tup.0, tup.1,
				import.objects[i].1,
				if (i + 1 < len(import.objects)) ", " else "")?;
		};
		n += fmt::fprint(out, "}")?;
	} else if (import.mode & ast::import_mode::WILDCARD != 0) {
		n += fmt::fprint(out, "::*")?;
	};
	n += fmt::fprint(out, ";")?;
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
		import(&buf, tests[i].0) as size;
		let s = memio::string(&buf)!;
		assert(s == tests[i].1);
		free(s);
	};
};
