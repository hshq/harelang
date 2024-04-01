// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::ast::{variadism};
use hare::lex;
use io;
use memio;
use strings;

// Returns a builtin type as a string.
export fn builtin_type(b: ast::builtin_type) str = switch (b) {
case ast::builtin_type::FCONST, ast::builtin_type::ICONST,
	ast::builtin_type::RCONST =>
	abort("ICONST, FCONST, and RCONST have no lexical representation");
case ast::builtin_type::BOOL =>
	yield "bool";
case ast::builtin_type::DONE =>
	yield "done";
case ast::builtin_type::F32 =>
	yield "f32";
case ast::builtin_type::F64 =>
	yield "f64";
case ast::builtin_type::I16 =>
	yield "i16";
case ast::builtin_type::I32 =>
	yield "i32";
case ast::builtin_type::I64 =>
	yield "i64";
case ast::builtin_type::I8 =>
	yield "i8";
case ast::builtin_type::INT =>
	yield "int";
case ast::builtin_type::NEVER =>
	yield "never";
case ast::builtin_type::NULL =>
	yield "null";
case ast::builtin_type::OPAQUE =>
	yield "opaque";
case ast::builtin_type::RUNE =>
	yield "rune";
case ast::builtin_type::SIZE =>
	yield "size";
case ast::builtin_type::STR =>
	yield "str";
case ast::builtin_type::U16 =>
	yield "u16";
case ast::builtin_type::U32 =>
	yield "u32";
case ast::builtin_type::U64 =>
	yield "u64";
case ast::builtin_type::U8 =>
	yield "u8";
case ast::builtin_type::UINT =>
	yield "uint";
case ast::builtin_type::UINTPTR =>
	yield "uintptr";
case ast::builtin_type::VALIST =>
	yield "valist";
case ast::builtin_type::VOID =>
	yield "void";
};

fn prototype(
	ctx: *context,
	syn: *synfunc,
	t: *ast::func_type,
) (size | io::error) = {
	let n = 0z;
	n += syn(ctx, "(", synkind::PUNCTUATION)?;

	for (let i = 0z; i < len(t.params); i += 1) {
		const param = &t.params[i];
		if (param.name != "") {
			n += syn(ctx, param.name, synkind::SECONDARY)?;
			n += syn(ctx, ":", synkind::PUNCTUATION)?;
			n += space(ctx)?;
		};
		n += __type(ctx, syn, param._type)?;
		match (param.default_value) {
		case void =>
			yield;
		case let e: ast::expr =>
			n += space(ctx)?;
			n += syn(ctx, "=", synkind::PUNCTUATION)?;
			n += space(ctx)?;
			n += _expr(ctx, syn, &e)?;
		};
		if (i + 1 < len(t.params) || t.variadism == variadism::C) {
			n += syn(ctx, ",", synkind::PUNCTUATION)?;
			n += space(ctx)?;
		};
	};
	if (t.variadism != variadism::NONE) {
		n += syn(ctx, "...", synkind::OPERATOR)?;
	};

	n += syn(ctx, ")", synkind::PUNCTUATION)?;
	n += space(ctx)?;
	n += __type(ctx, syn, t.result)?;
	return n;
};

fn struct_union_type(
	ctx: *context,
	syn: *synfunc,
	t: *ast::_type,
) (size | io::error) = {
	let z = 0z;
	let membs = match (t.repr) {
	case let st: ast::struct_type =>
		z += syn(ctx, "struct", synkind::TYPE)?;
		z += space(ctx)?;
		if (st.packed) {
			z += syn(ctx, "@packed", synkind::ATTRIBUTE)?;
			z += space(ctx)?;
		};
		z += syn(ctx, "{", synkind::PUNCTUATION)?;
		yield st.members: []ast::struct_member;
	case let ut: ast::union_type =>
		z += syn(ctx, "union", synkind::TYPE)?;
		z += space(ctx)?;
		z += syn(ctx, "{", synkind::PUNCTUATION)?;
		yield ut: []ast::struct_member;
	case => abort(); // unreachable
	};

	ctx.indent += 1z;
	for (let memb .. membs) {
		z += fmt::fprintln(ctx.out)?;
		ctx.linelen = 0;
		if (memb.docs != "") {
			z += comment(ctx, syn, memb.docs)?;
		};
		for (let i = 0z; i < ctx.indent; i += 1) {
			z += fmt::fprint(ctx.out, "\t")?;
			ctx.linelen += 8;
		};

		match (memb._offset) {
		case null => void;
		case let ex: *ast::expr =>
			z += syn(ctx, "@offset(", synkind::ATTRIBUTE)?;
			z += _expr(ctx, syn, ex)?;
			z += syn(ctx, ")", synkind::ATTRIBUTE)?;
			z += space(ctx)?;
		};

		match (memb.member) {
		case let se: ast::struct_embedded =>
			z += __type(ctx, syn, se)?;
		case let sa: ast::struct_alias =>
			z += _ident(ctx, syn, sa, synkind::IDENT)?;
		case let sf: ast::struct_field =>
			z += syn(ctx, sf.name, synkind::SECONDARY)?;
			z += syn(ctx, ":", synkind::PUNCTUATION)?;
			z += space(ctx)?;
			z += __type(ctx, syn, sf._type)?;
		};

		z += syn(ctx, ",", synkind::PUNCTUATION)?;
	};

	ctx.indent -= 1;
	z += newline(ctx)?;
	z += syn(ctx, "}", synkind::PUNCTUATION)?;
	return z;
};

fn multiline_comment(s: str) bool =
	strings::byteindex(s, '\n') as size != len(s) - 1;

// Unparses a [[hare::ast::_type]].
export fn _type(
	out: io::handle,
	syn: *synfunc,
	t: *ast::_type,
) (size | io::error) = {
	let ctx = context {
		out = out,
		...
	};
	return __type(&ctx, syn, t);
};

fn __type(ctx: *context, syn: *synfunc, t: *ast::_type) (size | io::error) = {
	ctx.stack = &stack {
		cur = t,
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

	let n = 0z;
	if (t.flags & ast::type_flag::CONST != 0) {
		n += syn(ctx, "const", synkind::TYPE)?;
		n += space(ctx)?;
	};
	if (t.flags & ast::type_flag::ERROR != 0) {
		n += syn(ctx, "!", synkind::TYPE)?;
	};
	match (t.repr) {
	case let a: ast::alias_type =>
		if (a.unwrap) {
			n += syn(ctx, "...", synkind::TYPE)?;
		};
		n += _ident(ctx, syn, a.ident, synkind::TYPE)?;
	case let b: ast::builtin_type =>
		n += syn(ctx, builtin_type(b), synkind::TYPE)?;
	case let e: ast::enum_type =>
		n += syn(ctx, "enum", synkind::TYPE)?;
		n += space(ctx)?;
		if (e.storage != ast::builtin_type::INT) {
			n += syn(ctx, builtin_type(e.storage), synkind::TYPE)?;
			n += space(ctx)?;
		};
		n += syn(ctx, "{", synkind::PUNCTUATION)?;
		ctx.indent += 1;
		n += fmt::fprintln(ctx.out)?;
		ctx.linelen = 0;
		for (let value .. e.values) {
			let wrotedocs = false;
			if (value.docs != "") {
				// Check if comment should go above or next to
				// field
				if (multiline_comment(value.docs)) {
					n += comment(ctx, syn, value.docs)?;
					wrotedocs = true;
				};
			};
			for (let i = 0z; i < ctx.indent; i += 1) {
				n += fmt::fprint(ctx.out, "\t")?;
				ctx.linelen += 8;
			};
			n += syn(ctx, value.name, synkind::SECONDARY)?;
			match (value.value) {
			case null => void;
			case let e: *ast::expr =>
				n += space(ctx)?;
				n += syn(ctx, "=", synkind::OPERATOR)?;
				n += space(ctx)?;
				n += _expr(ctx, syn, e)?;
			};
			n += syn(ctx, ",", synkind::PUNCTUATION)?;
			if (value.docs != "" && !wrotedocs) {
				n += space(ctx)?;
				const oldindent = ctx.indent;
				ctx.indent = 0;
				n += comment(ctx, syn, value.docs)?;
				ctx.indent = oldindent;
			} else {
				n += fmt::fprintln(ctx.out)?;
				ctx.linelen = 0;
			};
		};
		ctx.indent -= 1;
		for (let i = 0z; i < ctx.indent; i += 1) {
			n += fmt::fprint(ctx.out, "\t")?;
			ctx.linelen += 8;
		};
		n += syn(ctx, "}", synkind::PUNCTUATION)?;
	case let f: ast::func_type =>
		n += syn(ctx, "fn", synkind::TYPE)?;
		n += prototype(ctx, syn, &f)?;
	case let l: ast::list_type =>
		n += syn(ctx, "[", synkind::TYPE)?;
		match (l.length) {
		case ast::len_slice => void;
		case ast::len_unbounded =>
			n += syn(ctx, "*", synkind::TYPE)?;
		case ast::len_contextual =>
			n += syn(ctx, "_", synkind::TYPE)?;
		case let e: *ast::expr =>
			n += _expr(ctx, syn, e)?;
		};
		n += syn(ctx, "]", synkind::TYPE)?;
		n += __type(ctx, syn, l.members)?;
	case let p: ast::pointer_type =>
		if (p.flags & ast::pointer_flag::NULLABLE != 0) {
			n += syn(ctx, "nullable", synkind::TYPE)?;
			n += space(ctx)?;
		};
		n += syn(ctx, "*", synkind::TYPE)?;
		n += __type(ctx, syn, p.referent)?;
	case ast::struct_type =>
		n += struct_union_type(ctx, syn, t)?;
	case ast::union_type =>
		n += struct_union_type(ctx, syn, t)?;
	case let t: ast::tagged_type =>
		n += syn(ctx, "(", synkind::TYPE)?;
		for (let i = 0z; i < len(t); i += 1) {
			n += __type(ctx, syn, t[i])?;
			if (i + 1 == len(t)) break;
			n += space(ctx)?;
			n += syn(ctx, "|", synkind::TYPE)?;
			n += space(ctx)?;
		};
		n += syn(ctx, ")", synkind::TYPE)?;
	case let t: ast::tuple_type =>
		n += syn(ctx, "(", synkind::TYPE)?;
		for (let i = 0z; i < len(t); i += 1) {
			n += __type(ctx, syn, t[i])?;
			if (i + 1 == len(t)) break;
			n += syn(ctx, ",", synkind::TYPE)?;
			n += space(ctx)?;
		};
		n += syn(ctx, ")", synkind::TYPE)?;
	};
	return n;
};

fn type_test(t: *ast::_type, expected: str) void = {
	let buf = memio::dynamic();
	_type(&buf, &syn_nowrap, t)!;
	let s = memio::string(&buf)!;
	defer free(s);
	if (s != expected) {
		fmt::errorfln("=== wanted\n{}", expected)!;
		fmt::errorfln("=== got\n{}", s)!;
		abort();
	};
};

@test fn _type() void = {
	let loc = lex::location {
		path = "<test>",
		line = 0,
		col = 0,
	};
	let t = ast::_type {
		start = loc,
		end = loc,
		flags = ast::type_flag::CONST,
		repr = ast::alias_type {
			unwrap = false,
			ident = ["foo", "bar"],
		},
	};
	let type_int = ast::_type {
		start = loc,
		end = loc,
		flags = 0,
		repr = ast::builtin_type::INT,
	};
	let expr_void = ast::expr {
		start = lex::location { ... },
		end = lex::location { ... },
		expr = void,
	};

	type_test(&t, "const foo::bar");
	t.flags = 0;
	t.repr = ast::alias_type {
		unwrap = true,
		ident = ["baz"],
	};
	type_test(&t, "...baz");

	t.flags = ast::type_flag::ERROR;
	t.repr = ast::builtin_type::INT;
	type_test(&t, "!int");

	t.flags = ast::type_flag::CONST | ast::type_flag::ERROR;
	t.repr = ast::enum_type {
		storage = ast::builtin_type::U32,
		values = [
			ast::enum_field {
				name = "FOO",
				value = null,
				loc = loc,
				docs = "",
			},
			ast::enum_field {
				name = "BAR",
				value = &expr_void,
				loc = loc,
				docs = "",
			},
		],
	};
	type_test(&t, "const !enum u32 {\n\tFOO,\n\tBAR = void,\n}");

	t.flags = 0;

	t.repr = ast::func_type {
		result = &type_int,
		variadism = variadism::NONE,
		params = [],
	};
	type_test(&t, "fn() int");
	t.repr = ast::func_type {
		result = &type_int,
		variadism = variadism::C,
		params = [
			ast::func_param {
				loc = loc,
				name = "",
				_type = &type_int,
				default_value = void,
			},
		],
	};
	type_test(&t, "fn(int, ...) int");
	t.repr = ast::func_type {
		result = &type_int,
		variadism = variadism::HARE,
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
	};
	type_test(&t, "fn(foo: int, bar: int...) int");

	t.repr = ast::list_type {
		length = ast::len_slice,
		members = &type_int,
	};
	type_test(&t, "[]int");
	t.repr = ast::list_type {
		length = ast::len_unbounded,
		members = &type_int,
	};
	type_test(&t, "[*]int");
	t.repr = ast::list_type {
		length = ast::len_contextual,
		members = &type_int,
	};
	type_test(&t, "[_]int");
	t.repr = ast::list_type {
		length = &expr_void,
		members = &type_int,
	};
	type_test(&t, "[void]int");

	t.repr = ast::pointer_type {
		referent = &type_int,
		flags = 0,
	};
	type_test(&t, "*int");
	t.repr = ast::pointer_type {
		referent = &type_int,
		flags = ast::pointer_flag::NULLABLE,
	};
	type_test(&t, "nullable *int");

	t.repr = [&type_int, &type_int]: ast::tagged_type;
	type_test(&t, "(int | int)");

	t.repr = [&type_int, &type_int]: ast::tuple_type;
	type_test(&t, "(int, int)");
};
