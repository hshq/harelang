// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use memio;
use strings;
use types;

fn parse_type(in: str) ast::_type = {
	let buf = memio::fixed(strings::toutf8(in));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lex = lex::init(&sc, "<test>");
	return parse::_type(&lex)!;
};

@test fn store() void = {
	let st = store(x86_64, null, null);
	defer store_free(st);

	let atype = parse_type("int");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.repr as builtin == builtin::INT);
	assert(htype.sz == x86_64._int && htype._align == x86_64._int);

	let type2 = lookup(st, &atype)!;
	assert(htype == type2, "types should be singletons");

	let atype = parse_type("*int");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == x86_64._pointer && htype._align == x86_64._pointer);
	let htype = htype.repr as pointer;
	assert(htype.referent.repr as builtin == builtin::INT);
};

fn resolve(
	rstate: nullable *opaque,
	store: *typestore,
	expr: const *ast::expr,
) (size | deferred | error) = {
	let expr = expr.expr as ast::literal_expr;
	let n = expr as ast::number_literal;
	let ival = n.value as i64;
	assert(ival >= 0);
	return ival: size;
};

@test fn structs() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	// Basic struct
	let atype = parse_type("struct { x: int, y: int }");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 8);
	assert(htype._align == 4);
	let stype = htype.repr as _struct;
	assert(stype.kind == struct_union::STRUCT);
	assert(len(stype.fields) == 2);

	let x = stype.fields[0];
	assert(x.name == "x");
	assert(x.offs == 0);
	assert(x._type.repr as builtin == builtin::INT);

	let y = stype.fields[1];
	assert(y.name == "y");
	assert(y.offs == 4);
	assert(y._type.repr as builtin == builtin::INT);

	// Basic union
	let atype = parse_type("union { x: int, y: int }");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 4);
	assert(htype._align == 4);
	let stype = htype.repr as _struct;
	assert(stype.kind == struct_union::UNION);
	assert(len(stype.fields) == 2);

	let x = stype.fields[0];
	assert(x.name == "x");
	assert(x.offs == 0);
	assert(x._type.repr as builtin == builtin::INT);

	let y = stype.fields[1];
	assert(y.name == "y");
	assert(y.offs == 0);
	assert(y._type.repr as builtin == builtin::INT);

	// Padding
	let atype = parse_type("struct { w: u8, x: u32, y: u8, z: u64 }");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 24);
	assert(htype._align == 8);
	let stype = htype.repr as _struct;
	assert(stype.kind == struct_union::STRUCT);

	let w = stype.fields[0];
	assert(w.offs == 0);
	let x = stype.fields[1];
	assert(x.offs == 4);
	let y = stype.fields[2];
	assert(y.offs == 8);
	let z = stype.fields[3];
	assert(z.offs == 16);

	let atype = parse_type("struct { x: u8, y: size, z: u8 }");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 24);

	// Sort order
	let atype = parse_type("struct { z: u8, y: u8, x: u8, q: u8 }");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	let stype = htype.repr as _struct;
	assert(stype.fields[0].name == "q");
	assert(stype.fields[1].name == "x");
	assert(stype.fields[2].name == "y");
	assert(stype.fields[3].name == "z");

	// Embedded struct
	let atype = parse_type("struct {
		x: int,
		y: int,
		struct {
			z: int,
			q: int,
		},
		p: int,
	}");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 20);
	assert(htype._align == 4);
	let stype = htype.repr as _struct;
	assert(stype.fields[0].name == "p");
	assert(stype.fields[0].offs == 16);
	assert(stype.fields[1].name == "q");
	assert(stype.fields[1].offs == 12);
	assert(stype.fields[2].name == "x");
	assert(stype.fields[2].offs == 0);
	assert(stype.fields[3].name == "y");
	assert(stype.fields[3].offs == 4);
	assert(stype.fields[4].name == "z");
	assert(stype.fields[4].offs == 8);

	// Embedded union
	let atype = parse_type("struct {
		x: int,
		y: int,
		union {
			z: int,
			q: int,
		},
		p: int,
	}");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 16);
	assert(htype._align == 4);
	let stype = htype.repr as _struct;
	assert(stype.fields[0].name == "p");
	assert(stype.fields[0].offs == 12);
	assert(stype.fields[1].name == "q");
	assert(stype.fields[1].offs == 8);
	assert(stype.fields[2].name == "x");
	assert(stype.fields[2].offs == 0);
	assert(stype.fields[3].name == "y");
	assert(stype.fields[3].offs == 4);
	assert(stype.fields[4].name == "z");
	assert(stype.fields[4].offs == 8);

	// Embedded (struct) alias
	// TODO

	// Embedded (union) alias
	// TODO

	// Explicit offsets
	let atype = parse_type("struct {
		@offset(8)  x: int,
		@offset(16) y: int,
		@offset(32) z: int,
	}");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 36);
	assert(htype._align == 4);
	let stype = htype.repr as _struct;
	assert(stype.fields[0].name == "x");
	assert(stype.fields[0].offs == 8);
	assert(stype.fields[1].name == "y");
	assert(stype.fields[1].offs == 16);
	assert(stype.fields[2].name == "z");
	assert(stype.fields[2].offs == 32);
};

@test fn tuples() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	// Basic case
	let atype = parse_type("(int, int)");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 8);
	assert(htype._align == 4);
	let tup = htype.repr as tuple;
	assert(len(tup) == 2);

	assert(tup[0].offs == 0);
	assert(tup[0]._type.repr as builtin == builtin::INT);
	assert(tup[1].offs == 4);
	assert(tup[1]._type.repr as builtin == builtin::INT);

	// Padding
	let atype = parse_type("(i8, i32, i8, i64)");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 24);
	assert(htype._align == 8);

	let tup = htype.repr as tuple;
	assert(tup[0].offs == 0);
	assert(tup[1].offs == 4);
	assert(tup[2].offs == 8);
	assert(tup[3].offs == 16);
};

@test fn lists() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	// Slice
	let atype = parse_type("[]int");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 24);
	assert(htype._align == 8);
	let slice = htype.repr as slice;
	assert(slice.repr as builtin == builtin::INT);

	// Normal array
	let atype = parse_type("[5]i32");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 4 * 5);
	assert(htype._align == 4);
	let arr = htype.repr as array;
	assert(arr.member.repr as builtin == builtin::I32);
	assert(arr.length == 5);

	// Unbounded array
	let atype = parse_type("[*]i32");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == SIZE_UNDEFINED);
	assert(htype._align == 4);
	let arr = htype.repr as array;
	assert(arr.member.repr as builtin == builtin::I32);
	assert(arr.length == SIZE_UNDEFINED);

	// Contextual array (equivalent to unbounded at this compilation stage)
	let atype = parse_type("[_]i32");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == SIZE_UNDEFINED);
	assert(htype._align == 4);
	let arr = htype.repr as array;
	assert(arr.member.repr as builtin == builtin::I32);
	assert(arr.length == SIZE_UNDEFINED);
};

@test fn funcs() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	let atype = parse_type("fn() never");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == SIZE_UNDEFINED);
	assert(htype._align == SIZE_UNDEFINED);
	let f = htype.repr as func;
	assert(f.result.repr as builtin == builtin::NEVER);
	assert(f.variadism  == variadism::NONE);
	assert(len(f.params) == 0);

	let atype = parse_type("fn(foo: int, bar: str...) int");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == SIZE_UNDEFINED);
	assert(htype._align == SIZE_UNDEFINED);
	let f = htype.repr as func;
	assert(f.result.repr as builtin == builtin::INT);
	assert(f.variadism  == variadism::HARE);
	assert(len(f.params) == 2);
	assert(f.params[0].repr as builtin == builtin::INT);
	assert(f.params[1].repr as builtin == builtin::STR);
};

@test fn tagged() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	let atype = parse_type("(int | int | void)");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == st.arch._int * 2);
	assert(htype._align == st.arch._int);
	let t = htype.repr as tagged;
	assert(len(t) == 2);
	assert(t[0].repr as builtin == builtin::INT);
	assert(t[1].repr as builtin == builtin::VOID);

	let atype = parse_type("(int | (int | str | void))");
	defer ast::type_finish(&atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 32);
	assert(htype._align == 8);
	let t = htype.repr as tagged;
	assert(len(t) == 3);
	assert(t[0].repr as builtin == builtin::INT);
	assert(t[1].repr as builtin == builtin::VOID);
	assert(t[2].repr as builtin == builtin::STR);
};

@test fn alias() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	const of = lookup_builtin(st, ast::builtin_type::U64);
	const al = newalias(st, ["myalias"], of);
	assert(al.sz == 8);
	assert(al._align == 8);
	assert(al.flags == 0);
	assert((al.repr as alias).secondary == of);

	const atype = parse_type("myalias");
	defer ast::type_finish(&atype);
	const htype = lookup(st, &atype)!;
	assert(htype == al);
};

@test fn forwardref() void = {
	let st = store(x86_64, &resolve, null);
	defer store_free(st);

	const atype = parse_type("myalias");
	defer ast::type_finish(&atype);
	const htype = lookup(st, &atype)!;
	assert((htype.repr as alias).secondary == null);

	const of = lookup_builtin(st, ast::builtin_type::U64);
	const al = newalias(st, ["myalias"], of);
	assert(htype.sz == 8);
	assert(htype._align == 8);
	assert(htype.flags == 0);
	assert((htype.repr as alias).secondary == of);
};

@test fn builtins() void = {
	const builtins = [
		(&builtin_bool, "bool"),
		(&builtin_done, "done"),
		(&builtin_f32, "f32"),
		(&builtin_f64, "f64"),
		(&builtin_i8, "i8"),
		(&builtin_i16, "i16"),
		(&builtin_i32, "i32"),
		(&builtin_i64, "i64"),
		(&builtin_opaque, "opaque"),
		(&builtin_rune, "rune"),
		(&builtin_u8, "u8"),
		(&builtin_u16, "u16"),
		(&builtin_u32, "u32"),
		(&builtin_u64, "u64"),
		(&builtin_void, "void"),
	];
	for (let i = 0z; i < len(builtins); i += 1) {
		const expected = hash(builtins[i].0);
		const actual = builtins[i].0.id;
		if (expected != actual) {
			fmt::errorfln("expected type {} to have ID {}, but got {}",
				builtins[i].1, expected, actual)!;
			abort();
		};
	};
};
