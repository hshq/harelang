// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::lex;
use io;
use memio;
use strings;

// Unparses a [[hare::ast::decl]].
export fn decl(
	out: io::handle,
	syn: *synfunc,
	d: *ast::decl,
) (size | io::error) = {
	let n = 0z;
	let ctx = context {
		out = out,
		stack = &stack {
			cur = d,
			...
		},
		...
	};
	if (len(d.docs) > 0) {
		n += comment(&ctx, syn, d.docs)?;
	};
	if (d.exported) {
		n += syn(&ctx, "export", synkind::KEYWORD)?;
		n += space(&ctx)?;
	};
	match (d.decl) {
	case let c: []ast::decl_const =>
		n += syn(&ctx, "def", synkind::KEYWORD)?;
		n += space(&ctx)?;
		for (let i = 0z; i < len(c); i += 1) {
			n += _ident(&ctx, syn, c[i].ident, synkind::CONSTANT)?;
			match (c[i]._type) {
			case null => void;
			case let ty: *ast::_type =>
				n += syn(&ctx, ":", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
				n += __type(&ctx, syn, ty)?;
			};
			n += space(&ctx)?;
			n += syn(&ctx, "=", synkind::OPERATOR)?;
			n += space(&ctx)?;
			n += _expr(&ctx, syn, c[i].init)?;
			if (i + 1 < len(c)) {
				n += syn(&ctx, ",", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
			};
		};
	case let g: []ast::decl_global =>
		n += syn(&ctx,
			if (g[0].is_const) "const" else "let",
			synkind::KEYWORD)?;
		n += space(&ctx)?;
		for (let i = 0z; i < len(g); i += 1) {
			if (len(g[i].symbol) != 0) {
				n += syn(&ctx, "@symbol(", synkind::ATTRIBUTE)?;
				n += literal(&ctx, syn, g[i].symbol)?;
				n += syn(&ctx, ")", synkind::ATTRIBUTE)?;
				n += space(&ctx)?;
			} else if (g[i].is_threadlocal) {
				n += syn(&ctx, "@threadlocal",
					synkind::ATTRIBUTE)?;
				n += space(&ctx)?;
			};
			n += _ident(&ctx, syn, g[i].ident, synkind::GLOBAL)?;
			match (g[i]._type) {
			case null => void;
			case let ty: *ast::_type =>
				n += syn(&ctx, ":", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
				n += __type(&ctx, syn, ty)?;
			};
			match (g[i].init) {
			case null => void;
			case let ex: *ast::expr =>
				n += space(&ctx)?;
				n += syn(&ctx, "=", synkind::OPERATOR)?;
				n += space(&ctx)?;
				n += _expr(&ctx, syn, ex)?;
			};
			if (i + 1 < len(g)) {
				n += syn(&ctx, ",", synkind::OPERATOR)?;
				n += space(&ctx)?;
			};
		};
	case let t: []ast::decl_type =>
		n += syn(&ctx, "type", synkind::KEYWORD)?;
		n += space(&ctx)?;
		for (let i = 0z; i < len(t); i += 1) {
			n += _ident(&ctx, syn, t[i].ident, synkind::TYPEDEF)?;
			n += space(&ctx)?;
			n += syn(&ctx, "=", synkind::OPERATOR)?;
			n += space(&ctx)?;
			n += __type(&ctx, syn, t[i]._type)?;
			if (i + 1 < len(t)) {
				n += syn(&ctx, ",", synkind::PUNCTUATION)?;
				n += space(&ctx)?;
			};
		};
	case let f: ast::decl_func =>
		ctx.stack = &stack {
			cur = f.prototype,
			up = ctx.stack,
			...
		};
		defer {
			let stack = &(ctx.stack as *stack);
			match (stack.extra) {
			case let p: *opaque =>
				free(p);
			case null => void;
			};
			ctx.stack = stack.up;
		};

		switch (f.attrs) {
		case ast::fndecl_attr::NONE => void;
		case ast::fndecl_attr::FINI =>
			n += syn(&ctx, "@fini", synkind::ATTRIBUTE)?;
			n += space(&ctx)?;
		case ast::fndecl_attr::INIT =>
			n += syn(&ctx, "@init", synkind::ATTRIBUTE)?;
			n += space(&ctx)?;
		case ast::fndecl_attr::TEST =>
			n += syn(&ctx, "@test", synkind::ATTRIBUTE)?;
			n += space(&ctx)?;
		};
		let p = f.prototype.repr as ast::func_type;
		if (len(f.symbol) != 0) {
			n += syn(&ctx, "@symbol(", synkind::ATTRIBUTE)?;
			n += literal(&ctx, syn, f.symbol)?;
			n += syn(&ctx, ")", synkind::ATTRIBUTE)?;
			n += space(&ctx)?;
		};
		n += syn(&ctx, "fn", synkind::KEYWORD)?;
		n += space(&ctx)?;
		n += _ident(&ctx, syn, f.ident, synkind::FUNCTION)?;
		const fntype = f.prototype.repr as ast::func_type;
		n += prototype(&ctx, syn, &fntype)?;
		match (f.body) {
		case null => void;
		case let e: *ast::expr =>
			n += space(&ctx)?;
			n += syn(&ctx, "=", synkind::OPERATOR)?;
			n += space(&ctx)?;
			n += _expr(&ctx, syn, e)?;
		};
	case let e: ast::assert_expr =>
		n += assert_expr(&ctx, syn, &e)?;
	};
	n += syn(&ctx, ";", synkind::PUNCTUATION)?;
	return n;
};

fn comment(ctx: *context, syn: *synfunc, s: str) (size | io::error) = {
	let n = 0z;
	let s = strings::trimsuffix(s, "\n");
	let s = strings::tokenize(s, "\n");

	for (let line => strings::next_token(&s)) {
		for (let i = 0z; i < ctx.indent; i += 1) {
			n += syn(ctx, "\t", synkind::COMMENT)?;
			ctx.linelen += 8;
		};
		n += syn(ctx, "//", synkind::COMMENT)?;
		n += syn(ctx, line, synkind::COMMENT)?;
		n += syn(ctx, "\n", synkind::COMMENT)?;
		ctx.linelen = 0;
	};
	return n;
};

fn decl_test(d: *ast::decl, expected: str) bool = {
	let buf = memio::dynamic();
	decl(&buf, &syn_nowrap, d)!;
	let s = memio::string(&buf)!;
	defer free(s);
	fmt::println(s)!;
	return s == expected;
};

@test fn decl() void = {
	let loc = lex::location {
		path = "<test>",
		line = 0,
		col = 0,
	};
	let type_int = ast::_type {
		start = loc,
		end = loc,
		flags = 0,
		repr = ast::builtin_type::INT,
	};
	let type_fn = ast::_type {
		start = loc,
		end = loc,
		flags = 0,
		repr = ast::func_type {
			result = &type_int,
			variadism = ast::variadism::HARE,
			params = [
				ast::func_param {
					loc = loc,
					name = "foo",
					_type = &type_int,
					default_value = void,
				},
				ast::func_param {
					loc = loc,
					name = "bar",
					_type = &type_int,
					default_value = void,
				},
			],
		},
	};
	let expr_void = ast::expr {
		start = lex::location { ... },
		end = lex::location { ... },
		expr = void,
	};

	let d = ast::decl {
		exported = false,
		start = loc,
		end = loc,
		decl = [
			ast::decl_global {
				is_const = false,
				is_threadlocal = false,
				symbol = "",
				ident = ["foo", "bar"],
				_type = &type_int,
				init = alloc(expr_void),
			},
			ast::decl_global {
				is_const = false,
				is_threadlocal = true,
				symbol = "",
				ident = ["boo"],
				_type = &type_int,
				init = alloc(expr_void),
			},
			ast::decl_global {
				is_const = false,
				is_threadlocal = false,
				symbol = "foobar",
				ident = ["baz"],
				_type = &type_int,
				init = alloc(expr_void),
			},
		],
		...
	};
	assert(decl_test(&d, "let foo::bar: int = void, @threadlocal boo: int = void, @symbol(\"foobar\") baz: int = void;"));

	d.exported = true;
	d.decl = [
		ast::decl_const {
			ident = ["foo"],
			_type = &type_int,
			init = alloc(expr_void),
		},
	];
	assert(decl_test(&d, "export def foo: int = void;"));

	d.exported = false;
	d.decl = [
		ast::decl_type {
			ident = ["foo"],
			_type = &type_int,
		},
		ast::decl_type {
			ident = ["bar"],
			_type = &type_int,
		},
	];
	assert(decl_test(&d, "type foo = int, bar = int;"));

	d.decl = ast::decl_func {
		symbol = "foo",
		ident = ["foo"],
		prototype = &type_fn,
		body = null,
		attrs = ast::fndecl_attr::FINI,
	};
	assert(decl_test(&d, "@fini @symbol(\"foo\") fn foo(foo: int, bar: int...) int;"));

	type_fn.repr = ast::func_type {
		result = &type_int,
		variadism = ast::variadism::NONE,
		params = [
			ast::func_param {
				loc = loc,
				name = "",
				_type = &type_int,
				default_value = ast::expr {
					expr = ast::number_literal {
						value = 4u64,
						sign = false,
						suff = lex::ltok::LIT_ICONST,
					},
					...
				},
			},
		],
	};
	d.decl = ast::decl_func {
		symbol = "",
		ident = ["foo"],
		prototype = &type_fn,
		body = &expr_void,
		attrs = 0,
	};
	assert(decl_test(&d, "fn foo(int = 4) int = void;"));
};
