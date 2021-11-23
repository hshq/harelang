use fmt;
use io;
use hare::ast;
use hare::lex;
use strio;

// Returns a builtin type as a string.
export fn builtin_type(b: ast::builtin_type) str = switch (b) {
case ast::builtin_type::FCONST, ast::builtin_type::ICONST =>
	abort("ICONST and FCONST have no lexical representation");
case ast::builtin_type::BOOL =>
	yield "bool";
case ast::builtin_type::CHAR =>
	yield "char";
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
case ast::builtin_type::NULL =>
	yield "null";
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
case ast::builtin_type::VOID =>
	yield "void";
};

// Unparses a prototype.
export fn prototype(
	out: io::handle,
	indent: size,
	t: ast::func_type,
) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "(")?;
	for (let i = 0z; i < len(t.params); i += 1) {
		let param = t.params[i];
		n += fmt::fprintf(out, "{}: ",
			if (len(param.name) == 0) "_" else param.name)?;
		n += _type(out, indent, *param._type)?;
		if (i + 1 == len(t.params)
				&& t.variadism == ast::variadism::HARE) {
			n += fmt::fprintf(out, "...")?;
		};
		if (i + 1 < len(t.params)) {
			n += fmt::fprint(out, ", ")?;
		};
	};
	if (t.variadism == ast::variadism::C) {
		n += fmt::fprint(out, ", ...")?;
	};
	n += fmt::fprint(out, ") ")?;
	n += _type(out, indent, *t.result)?;
	return n;
};

// Unparses a struct or union type.
fn struct_union_type(
	out: io::handle,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let z = 0z;
	let membs = match (t.repr) {
	case st: ast::struct_type =>
		z += fmt::fprint(out, "struct {")?;
		yield st: []ast::struct_member;
	case ut: ast::union_type =>
		z += fmt::fprint(out, "union {")?;
		yield ut: []ast::struct_member;
	};

	indent += 1z;
	for (let i = 0z; i < len(membs); i += 1) {
		z += newline(out, indent)?;

		match (membs[i]._offset) {
		case null => void;
		case ex: *ast::expr =>
			z += fmt::fprint(out, "@offset(")?;
			z += expr(out, indent, *ex)?;
			z += fmt::fprint(out, ") ")?;
		};

		match (membs[i].member) {
		case se: ast::struct_embedded =>
			z += _type(out, indent, *se)?;
		case sa: ast::struct_alias =>
			z += ident(out, sa)?;
		case sf: ast::struct_field =>
			z += fmt::fprintf(out, "{}: ", sf.name)?;
			z += _type(out, indent, *sf._type)?;
		};

		z += fmt::fprint(out, ",")?;
	};

	indent -= 1;
	z += newline(out, indent)?;
	z += fmt::fprint(out, "}")?;
	return z;
};

// Unparses an [[ast::_type]].
export fn _type(
	out: io::handle,
	indent: size,
	t: ast::_type,
) (size | io::error) = {
	let n = 0z;
	if (t.flags & ast::type_flags::CONST != 0
			&& !(t.repr is ast::func_type)) {
		n += fmt::fprint(out, "const ")?;
	};
	if (t.flags & ast::type_flags::ERROR != 0) {
		n += fmt::fprint(out, "!")?;
	};
	match (t.repr) {
	case a: ast::alias_type =>
		if (a.unwrap) {
			n += fmt::fprint(out, "...")?;
		};
		n += ident(out, a.ident)?;
	case b: ast::builtin_type =>
		n += fmt::fprint(out, builtin_type(b))?;
	case e: ast::enum_type =>
		if (e.storage != ast::builtin_type::INT) {
			n += fmt::fprint(out, "enum",
				builtin_type(e.storage), "{")?;
		} else {
			n += fmt::fprint(out, "enum {")?;
		};
		indent += 1;
		for (let i = 0z; i < len(e.values); i += 1) {
			n += newline(out, indent)?;
			let value = e.values[i];
			n += fmt::fprint(out, value.name)?;
			match (value.value) {
			case null => void;
			case e: *ast::expr =>
				n += fmt::fprint(out, " = ")?;
				n += expr(out, indent, *e)?;
			};
			n += fmt::fprint(out, ",")?;
		};
		indent -= 1;
		n += newline(out, indent)?;
		n += fmt::fprint(out, "}")?;
	case f: ast::func_type =>
		if (f.attrs & ast::func_attrs::NORETURN != 0) {
			n += fmt::fprint(out, "@noreturn ")?;
		};
		n += fmt::fprint(out, "fn")?;
		n += prototype(out, indent, f)?;
	case l: ast::list_type =>
		n += fmt::fprint(out, "[")?;
		match (l.length) {
		case ast::len_slice => void;
		case ast::len_unbounded =>
			n += fmt::fprint(out, "*")?;
		case ast::len_contextual =>
			n += fmt::fprint(out, "_")?;
		case e: *ast::expr =>
			n += expr(out, indent, *e)?;
		};
		n += fmt::fprint(out, "]")?;
		n += _type(out, indent, *l.members)?;
	case p: ast::pointer_type =>
		if (p.flags & ast::pointer_flags::NULLABLE != 0) {
			n += fmt::fprint(out, "nullable ")?;
		};
		n += fmt::fprint(out, "*")?;
		n += _type(out, indent, *p.referent)?;
	case ast::struct_type =>
		n += struct_union_type(out, indent, t)?;
	case ast::union_type =>
		n += struct_union_type(out, indent, t)?;
	case t: ast::tagged_type =>
		n += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += _type(out, indent, *t[i])?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, " | ")?;
			};
		};
		n += fmt::fprint(out, ")")?;
	case t: ast::tuple_type =>
		n += fmt::fprint(out, "(")?;
		for (let i = 0z; i < len(t); i += 1) {
			n += _type(out, indent, *t[i])?;
			if (i + 1 < len(t)) {
				n += fmt::fprint(out, ", ")?;
			};
		};
		n += fmt::fprint(out, ")")?;
	};
	return n;
};

fn type_test(t: ast::_type, expected: str) bool = {
	let buf = strio::dynamic();
	_type(buf, 0, t) as size;
	let s = strio::finish(buf);
	defer free(s);
	return s == expected;
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
		flags = ast::type_flags::CONST,
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

	assert(type_test(t, "const foo::bar"));
	t.flags = 0;
	t.repr = ast::alias_type {
		unwrap = true,
		ident = ["baz"],
	};
	assert(type_test(t, "...baz"));

	t.flags = ast::type_flags::ERROR;
	t.repr = ast::builtin_type::INT;
	assert(type_test(t, "!int"));

	t.flags = ast::type_flags::CONST | ast::type_flags::ERROR;
	t.repr = ast::enum_type {
		storage = ast::builtin_type::U32,
		values = [
			ast::enum_field {
				name = "FOO",
				value = null,
			},
			ast::enum_field {
				name = "BAR",
				value = &expr_void,
			},
		],
	};
	assert(type_test(t, "const !enum u32 {\n\tFOO,\n\tBAR = void,\n}"));

	t.flags = 0;

	t.repr = ast::func_type {
		result = &type_int,
		attrs = 0,
		variadism = ast::variadism::NONE,
		params = [],
	};
	assert(type_test(t, "fn() int"));
	t.repr = ast::func_type {
		result = &type_int,
		attrs = ast::func_attrs::NORETURN,
		variadism = ast::variadism::C,
		params = [
			ast::func_param {
				loc = loc,
				name = "",
				_type = &type_int,
			},
		],
	};
	assert(type_test(t, "@noreturn fn(_: int, ...) int"));
	t.repr = ast::func_type {
		result = &type_int,
		attrs = 0,
		variadism = ast::variadism::HARE,
		params = [
			ast::func_param {
				loc = loc,
				name = "foo",
				_type = &type_int,
			},
			ast::func_param {
				loc = loc,
				name = "bar",
				_type = &type_int,
			},
		],
	};
	assert(type_test(t, "fn(foo: int, bar: int...) int"));

	t.flags = ast::type_flags::CONST;
	assert(type_test(t, "fn(foo: int, bar: int...) int"));

	t.flags = 0;
	t.repr = ast::list_type {
		length = ast::len_slice,
		members = &type_int,
	};
	assert(type_test(t, "[]int"));
	t.repr = ast::list_type {
		length = ast::len_unbounded,
		members = &type_int,
	};
	assert(type_test(t, "[*]int"));
	t.repr = ast::list_type {
		length = ast::len_contextual,
		members = &type_int,
	};
	assert(type_test(t, "[_]int"));
	t.repr = ast::list_type {
		length = &expr_void,
		members = &type_int,
	};
	assert(type_test(t, "[void]int"));

	t.repr = ast::pointer_type {
		referent = &type_int,
		flags = 0,
	};
	assert(type_test(t, "*int"));
	t.repr = ast::pointer_type {
		referent = &type_int,
		flags = ast::pointer_flags::NULLABLE,
	};
	assert(type_test(t, "nullable *int"));

	t.repr = [&type_int, &type_int]: ast::tagged_type;
	assert(type_test(t, "(int | int)"));

	t.repr = [&type_int, &type_int]: ast::tuple_type;
	assert(type_test(t, "(int, int)"));
};
