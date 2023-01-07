// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use hare::ast;
use sort;
use strings;

type summary = struct {
	constants: []ast::decl,
	errors: []ast::decl,
	types: []ast::decl,
	globals: []ast::decl,
	funcs: []ast::decl,
};

// Sorts declarations by removing unexported declarations, moving undocumented
// declarations to the end, sorting by identifier, and ensuring that only one
// member is present in each declaration (so that "let x: int = 10, y: int = 20"
// becomes two declarations: "let x: int = 10; let y: int = 20;").
fn sort_decls(decls: []ast::decl) summary = {
	let sorted = summary { ... };

	for (let i = 0z; i < len(decls); i += 1) {
		let decl = decls[i];
		if (!decl.exported) {
			continue;
		};

		match (decl.decl) {
		case let f: ast::decl_func =>
			append(sorted.funcs, decl);
		case let t: []ast::decl_type =>
			for (let j = 0z; j < len(t); j += 1) {
				let bucket = &sorted.types;
				if (t[j]._type.flags & ast::type_flags::ERROR == ast::type_flags::ERROR) {
					bucket = &sorted.errors;
				};
				append(bucket, ast::decl {
					exported = true,
					start = decl.start,
					end = decl.end,
					decl = alloc([t[j]]),
					docs = decl.docs,
				});
			};
		case let c: []ast::decl_const =>
			for (let j = 0z; j < len(c); j += 1) {
				append(sorted.constants, ast::decl {
					exported = true,
					start = decl.start,
					end = decl.end,
					decl = alloc([c[j]]),
					docs = decl.docs,
				});
			};
		case let g: []ast::decl_global =>
			for (let j = 0z; j < len(g); j += 1) {
				append(sorted.globals, ast::decl {
					exported = true,
					start = decl.start,
					end = decl.end,
					decl = alloc([g[j]]),
					docs = decl.docs,
				});
			};
		};
	};

	sort::sort(sorted.constants, size(ast::decl), &decl_cmp);
	sort::sort(sorted.errors, size(ast::decl), &decl_cmp);
	sort::sort(sorted.types, size(ast::decl), &decl_cmp);
	sort::sort(sorted.globals, size(ast::decl), &decl_cmp);
	sort::sort(sorted.funcs, size(ast::decl), &decl_cmp);
	return sorted;
};

fn decl_cmp(a: const *void, b: const *void) int = {
	const a = *(a: const *ast::decl);
	const b = *(b: const *ast::decl);
	if (a.docs == "" && b.docs != "") {
		return 1;
	} else if (a.docs != "" && b.docs == "") {
		return -1;
	};
	const id_a = decl_ident(a), id_b = decl_ident(b);
	return strings::compare(id_a[len(id_a) - 1], id_b[len(id_b) - 1]);
};

fn decl_ident(decl: ast::decl) ast::ident = {
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
	};
};
