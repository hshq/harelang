// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use hare::ast;
use sort;
use strings;

// Sorts declarations by:
// - removing unexported declarations,
// - setting the "exported" field of all remaining declarations to false, so the
//   "export" keyword isn't unparsed,
// - moving undocumented declarations to the end,
// - sorting by identifier,
// - removing the initializer from globals and the body from functions,
// - ensuring that only one member is present in each declaration:
//   "let x: int, y: int;" becomes two declarations: "let x: int; let y: int;".
export fn sort_decls(decls: []ast::decl) summary = {
	let sorted = summary { ... };

	for (let decl .. decls) {
		if (!decl.exported) {
			continue;
		};

		match (decl.decl) {
		case let f: ast::decl_func =>
			append(sorted.funcs, ast::decl {
				exported = false,
				start = decl.start,
				end = decl.end,
				decl = ast::decl_func {
					symbol = f.symbol,
					ident = f.ident,
					prototype = f.prototype,
					body = null,
					attrs = f.attrs,
				},
				docs = decl.docs,
			});
		case let types: []ast::decl_type =>
			for (let t .. types) {
				let bucket = &sorted.types;
				if (t._type.flags & ast::type_flag::ERROR == ast::type_flag::ERROR) {
					bucket = &sorted.errors;
				};
				append(bucket, ast::decl {
					exported = false,
					start = decl.start,
					end = decl.end,
					decl = alloc([t]),
					docs = decl.docs,
				});
			};
		case let consts: []ast::decl_const =>
			for (let c .. consts) {
				append(sorted.constants, ast::decl {
					exported = false,
					start = decl.start,
					end = decl.end,
					decl = alloc([c]),
					docs = decl.docs,
				});
			};
		case let globals: []ast::decl_global =>
			for (let g .. globals) {
				append(sorted.globals, ast::decl {
					exported = false,
					start = decl.start,
					end = decl.end,
					decl = alloc([ast::decl_global {
						is_const = g.is_const,
						is_threadlocal = g.is_threadlocal,
						symbol = g.symbol,
						ident = g.ident,
						_type = g._type,
						init = null,
					}]),
					docs = decl.docs,
				});
			};
		case ast::assert_expr => void;
		};
	};

	sort::sort(sorted.constants, size(ast::decl), &decl_cmp);
	sort::sort(sorted.errors, size(ast::decl), &decl_cmp);
	sort::sort(sorted.types, size(ast::decl), &decl_cmp);
	sort::sort(sorted.globals, size(ast::decl), &decl_cmp);
	sort::sort(sorted.funcs, size(ast::decl), &decl_cmp);
	return sorted;
};

fn decl_cmp(a: const *opaque, b: const *opaque) int = {
	const a = a: const *ast::decl;
	const b = b: const *ast::decl;
	if (a.docs == "" && b.docs != "") {
		return 1;
	} else if (a.docs != "" && b.docs == "") {
		return -1;
	};
	const id_a = decl_ident(a), id_b = decl_ident(b);
	return strings::compare(id_a[len(id_a) - 1], id_b[len(id_b) - 1]);
};

fn decl_ident(decl: *ast::decl) ast::ident = {
	match (decl.decl) {
	case let f: ast::decl_func =>
		return f.ident;
	case let t: []ast::decl_type =>
		assert(len(t) == 1);
		return t[0].ident;
	case let c: []ast::decl_const =>
		assert(len(c) == 1);
		return c[0].ident;
	case let g: []ast::decl_global =>
		assert(len(g) == 1);
		return g[0].ident;
	case ast::assert_expr => abort();
	};
};
