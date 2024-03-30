// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::lex;

// An identifier access expression.
//
// 	foo
export type access_identifier = ident;

// An index access expression.
//
// 	foo[0]
export type access_index = struct {
	object: *expr,
	index: *expr,
};

// A struct field access expression.
//
// 	foo.bar
export type access_field = struct {
	object: *expr,
	field: str,
};

// A tuple field access expression.
//
// 	foo.1
export type access_tuple = struct {
	object: *expr,
	value: *expr,
};

// An access expression.
export type access_expr = (access_identifier | access_index | access_field
	| access_tuple);

// An align expression.
//
// 	align(int)
export type align_expr = *_type;

// The form of an allocation expression.
//
// 	alloc(foo)    // OBJECT
// 	alloc(foo...) // COPY
export type alloc_form = enum {
	OBJECT,
	COPY,
};

// An allocation expression.
//
// 	alloc(foo)
// 	alloc(foo...)
// 	alloc(foo, bar)
export type alloc_expr = struct {
	init: *expr,
	form: alloc_form,
	capacity: nullable *expr,
};

// An append expression.
//
// 	append(foo, bar);
// 	append(foo, bar...);
// 	append(foo, [0...], bar);
export type append_expr = struct {
	object: *expr,
	value: *expr,
	length: nullable *expr,
	variadic: bool,
	is_static: bool,
};

// An assertion expression.
//
// 	assert(foo)
// 	assert(foo, "error")
// 	abort()
// 	abort("error")
export type assert_expr = struct {
	cond: nullable *expr,
	message: nullable *expr,
	is_static: bool,
};

// An assignment expression.
//
// 	foo = bar
export type assign_expr = struct {
	op: (binarithm_op | void),
	object: *expr,
	value: *expr,
};

// A binary arithmetic operator
export type binarithm_op = enum {
	// TODO: Rehome this with the checked AST?

	BAND,	// &
	BOR,	// |
	DIV,	// /
	GT,	// >
	GTEQ,	// >=
	LAND,	// &&
	LEQUAL,	// ==
	LESS,	// <
	LESSEQ,	// <=
	LOR,	// ||
	LSHIFT,	// <<
	LXOR,	// ^^
	MINUS,	// -
	MODULO,	// %
	NEQUAL,	// !=
	PLUS,	// +
	RSHIFT,	// >>
	TIMES,	// *
	BXOR,	// ^
};

// A binary arithmetic expression.
//
// 	foo * bar
export type binarithm_expr = struct {
	op: binarithm_op,
	lvalue: *expr,
	rvalue: *expr,
};

// A single variable biding.
//
// 	foo: int = bar
// 	(foo, foo2): int = bar
export type binding = struct {
	name: (str | binding_unpack),
	_type: nullable *_type,
	init: *expr,
};

// Tuple unpacking binding.
//
// 	(foo, _, bar)
export type binding_unpack = [](str | void);

// The kind of binding expression being used.
export type binding_kind = enum {
	CONST,
	DEF,
	LET,
};

// A variable binding expression.
//
// 	let foo: int = bar, ...
export type binding_expr = struct {
	is_static: bool,
	kind: binding_kind,
	bindings: []binding,
};

// A break expression. The label is set to empty string if absent.
//
// 	break :label
export type break_expr = label;

// A function call expression.
//
// 	foo(bar)
export type call_expr = struct {
	lvalue: *expr,
	variadic: bool,
	args: []*expr,
};

// The kind of cast expression being used.
export type cast_kind = enum {
	// TODO: Should this be rehomed with the checked AST?

	CAST,
	ASSERTION,
	TEST,
};

// A cast expression.
//
// 	foo: int
// 	foo as int
// 	foo is int
export type cast_expr = struct {
	kind: cast_kind,
	value: *expr,
	_type: *_type,
};

// A compound expression.
//
// 	{
// 		foo;
// 		bar;
// 		// ...
// 	}
export type compound_expr = struct {
	exprs: []*expr,
	label: label,
};

// An array literal.
//
// 	[foo, bar, ...]
export type array_literal = struct {
	expand: bool,
	values: []*expr,
};

// A single struct field and value.
//
// 	foo: int = 10
export type struct_value = struct {
	name: str,
	_type: nullable *_type,
	init: *expr,
};

// A struct literal.
//
// 	struct { foo: int = bar, struct { baz = quux }, ... }
export type struct_literal = struct {
	autofill: bool,
	alias: ident, // [] for anonymous
	fields: [](struct_value | *struct_literal),
};

// A tuple literal.
//
// 	(foo, bar, ...)
export type tuple_literal = []*expr;

// The value "null".
export type _null = void;

// A scalar value.
export type value = (bool | done | _null | str | rune | void);

// An integer or float literal.
export type number_literal = struct {
	suff: lex::ltok,
	value: (i64 | u64 | f64),
	sign: bool, // true if negative, false otherwise
};

// A literal expression.
export type literal_expr = (value | array_literal | number_literal |
	struct_literal | tuple_literal);

// A continue expression. The label is set to empty string if absent.
//
// 	continue :label
export type continue_expr = label;

// A deferred expression.
//
// 	defer foo
export type defer_expr = *expr;

// A delete expression.
//
// 	delete(foo[10])
// 	delete(foo[4..42])
export type delete_expr = struct {
	object: *expr,
	is_static: bool,
};

// The kind of for expression being used.
export type for_kind = enum {
	ACCUMULATOR,
	EACH_VALUE,
	EACH_POINTER,
	ITERATOR,
};

// A for loop.
//
// 	for (let foo = 0; foo < bar; baz) quux
// 	for (let line => next_line()) quux
// 	for (let number .. [1, 2, 3]) quux
// 	for (let ptr &.. [1, 2, 3]) quux
export type for_expr = struct {
	kind: for_kind,
	bindings: nullable *expr,
	cond: nullable *expr,
	afterthought: nullable *expr,
	body: *expr,
	label: label,
};

// A free expression.
//
// 	free(foo)
export type free_expr = *expr;

// An if or if..else expression.
//
// 	if (foo) bar else baz
export type if_expr = struct {
	cond: *expr,
	tbranch: *expr,
	fbranch: nullable *expr,
};

// An insert expression.
//
// 	insert(foo[0], bar);
// 	insert(foo[0], bar...);
// 	insert(foo[0], [0...], bar);
export type insert_expr = append_expr;

// :label. The ":" character is not included.
export type label = str;

// A length expression.
//
// 	len(foo)
export type len_expr = *expr;

// A match case.
//
//	case type => exprs
//	case let name: type => exprs
export type match_case = struct {
	name: str,
	_type: nullable *_type, // null for default case
	exprs: []*expr,
};

// A match expression.
//
// 	match (foo) { case int => bar; ... }
export type match_expr = struct {
	value: *expr,
	cases: []match_case,
	label: label,
};

// An offset expression.
//
// 	offset(foo.bar)
export type offset_expr = *expr;

// An error propagation expression.
//
// 	foo?
export type propagate_expr = *expr;

// An error assertion expression.
//
// 	foo!
export type error_assert_expr = *expr;

// A return statement.
//
// 	return foo
export type return_expr = nullable *expr;

// A size expression.
//
// 	size(int)
export type size_expr = *_type;

// A slicing expression.
//
// 	foo[bar..baz]
export type slice_expr = struct {
	object: *expr,
	start: nullable *expr,
	end: nullable *expr,
};

// A switch case.
//
// 	case value => exprs
export type switch_case = struct {
	options: []*expr, // [] for default case
	exprs: []*expr,
};

// A switch expression.
//
// 	switch (foo) { case bar => baz; ... }
export type switch_expr = struct {
	value: *expr,
	cases: []switch_case,
	label: label,
};

// A unary operator
export type unarithm_op = enum {
	// TODO: Should this be rehomed with the checked AST?

	ADDR,	// &
	BNOT,	// ~
	DEREF,	// *
	LNOT,	// !
	MINUS,	// -
};

// A unary arithmetic expression.
//
// 	!example
export type unarithm_expr = struct {
	op: unarithm_op,
	operand: *expr,
};

// A vastart expression.
//
// 	vastart()
export type vastart_expr = void;

// A vaarg expression.
//
// 	vaarg(ap)
export type vaarg_expr = *expr;

// A vaend expression.
//
// 	vaend(ap)
export type vaend_expr = *expr;

// A C-style variadic expression.
export type variadic_expr = (vastart_expr | vaarg_expr | vaend_expr);

// A yield expression.
//
// 	yield foo
export type yield_expr = struct {
	label: label,
	value: nullable *expr,
};

// A Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	expr: (access_expr | align_expr | alloc_expr | append_expr |
		assert_expr | assign_expr | binarithm_expr | binding_expr |
		break_expr | call_expr | cast_expr | literal_expr |
		continue_expr | defer_expr | delete_expr | for_expr |
		free_expr | error_assert_expr | if_expr | insert_expr |
		compound_expr | match_expr | len_expr | size_expr |
		offset_expr | propagate_expr | return_expr | slice_expr |
		switch_expr | unarithm_expr | variadic_expr | yield_expr),
};

// Frees resources associated with a Hare [[expr]]ession.
export fn expr_finish(e: nullable *expr) void = match (e) {
case null => void;
case let e: *expr =>
	match (e.expr) {
	case let a: access_expr =>
		match (a) {
		case let i: access_identifier =>
			ident_free(i);
		case let i: access_index =>
			expr_finish(i.object);
			free(i.object);
			expr_finish(i.index);
			free(i.index);
		case let f: access_field =>
			expr_finish(f.object);
			free(f.object);
			free(f.field);
		case let t: access_tuple =>
			expr_finish(t.object);
			free(t.object);
			expr_finish(t.value);
			free(t.value);
		};
	case let a: align_expr =>
		type_finish(a);
		free(a);
	case let a: alloc_expr =>
		expr_finish(a.init);
		free(a.init);
		expr_finish(a.capacity);
		free(a.capacity);
	case let a: append_expr =>
		expr_finish(a.object);
		free(a.object);
		expr_finish(a.value);
		free(a.value);
		expr_finish(a.length);
		free(a.length);
	case let a: assert_expr =>
		expr_finish(a.cond);
		free(a.cond);
		expr_finish(a.message);
		free(a.message);
	case let a: assign_expr =>
		expr_finish(a.object);
		free(a.object);
		expr_finish(a.value);
		free(a.value);
	case let b: binarithm_expr =>
		expr_finish(b.lvalue);
		free(b.lvalue);
		expr_finish(b.rvalue);
		free(b.rvalue);
	case let b: binding_expr =>
		for (let i = 0z; i < len(b.bindings); i += 1) {
			match (b.bindings[i].name) {
			case let s: str =>
				free(s);
			case let u: binding_unpack =>
				for (let i = 0z; i < len(u); i += 1) {
					match (u[i]) {
					case let s: str =>
						free(s);
					case => void;
					};
				};
				free(u);
			};
			type_finish(b.bindings[i]._type);
			free(b.bindings[i]._type);
			expr_finish(b.bindings[i].init);
			free(b.bindings[i].init);
		};
		free(b.bindings);
	case let b: break_expr =>
		free(b);
	case let c: call_expr =>
		expr_finish(c.lvalue);
		free(c.lvalue);
		for (let i = 0z; i < len(c.args); i += 1) {
			expr_finish(c.args[i]);
			free(c.args[i]);
		};
		free(c.args);
	case let c: cast_expr =>
		expr_finish(c.value);
		free(c.value);
		type_finish(c._type);
		free(c._type);
	case let c: compound_expr =>
		for (let i = 0z; i < len(c.exprs); i += 1) {
			expr_finish(c.exprs[i]);
			free(c.exprs[i]);
		};
		free(c.exprs);
		free(c.label);
	case let c: literal_expr =>
		match (c) {
		case let a: array_literal =>
			for (let i = 0z; i < len(a.values); i += 1) {
				expr_finish(a.values[i]);
				free(a.values[i]);
			};
			free(a.values);
		case let s: struct_literal =>
			struct_literal_finish(&s);
		case let t: tuple_literal =>
			for (let i = 0z; i < len(t); i += 1) {
				expr_finish(t[i]);
				free(t[i]);
			};
			free(t);
		case (value | number_literal) => void;
		};
	case let c: continue_expr =>
		free(c);
	case let d: defer_expr =>
		expr_finish(d);
		free(d);
	case let d: delete_expr =>
		expr_finish(d.object);
		free(d.object);
	case let e: error_assert_expr =>
		expr_finish(e);
		free(e);
	case let f: for_expr =>
		expr_finish(f.bindings);
		free(f.bindings);
		expr_finish(f.cond);
		free(f.cond);
		expr_finish(f.afterthought);
		free(f.afterthought);
		expr_finish(f.body);
		free(f.body);
	case let f: free_expr =>
		expr_finish(f);
		free(f);
	case let i: if_expr =>
		expr_finish(i.cond);
		free(i.cond);
		expr_finish(i.tbranch);
		free(i.tbranch);
		expr_finish(i.fbranch);
		free(i.fbranch);
	case let e: insert_expr =>
		expr_finish(e.object);
		free(e.object);
		expr_finish(e.value);
		free(e.value);
		expr_finish(e.length);
		free(e.length);
	case let l: len_expr =>
		expr_finish(l);
		free(l);
	case let m: match_expr =>
		free(m.label);
		expr_finish(m.value);
		free(m.value);
		for (let i = 0z; i < len(m.cases); i += 1) {
			free(m.cases[i].name);
			type_finish(m.cases[i]._type);
			free(m.cases[i]._type);
			const exprs = m.cases[i].exprs;
			for (let i = 0z; i < len(exprs); i += 1) {
				expr_finish(exprs[i]);
				free(exprs[i]);
			};
			free(exprs);
		};
		free(m.cases);
	case let o: offset_expr =>
		expr_finish(o);
		free(o);
	case let p: propagate_expr =>
		expr_finish(p);
		free(p);
	case let r: return_expr =>
		expr_finish(r);
		free(r);
	case let s: size_expr =>
		type_finish(s);
		free(s);
	case let s: slice_expr =>
		expr_finish(s.object);
		free(s.object);
		expr_finish(s.start);
		free(s.start);
		expr_finish(s.end);
		free(s.end);
	case let s: switch_expr =>
		free(s.label);
		expr_finish(s.value);
		free(s.value);
		for (let i = 0z; i < len(s.cases); i += 1) {
			let opts = s.cases[i].options;
			for (let j = 0z; j < len(opts); j += 1) {
				expr_finish(opts[j]);
				free(opts[j]);
			};
			free(opts);

			let exprs = s.cases[i].exprs;
			for (let j = 0z; j < len(exprs); j += 1) {
				expr_finish(exprs[j]);
				free(exprs[j]);
			};
			free(exprs);
		};
		free(s.cases);
	case let u: unarithm_expr =>
		expr_finish(u.operand);
		free(u.operand);
	case let v: variadic_expr =>
		match (v) {
		case vastart_expr => void;
		case let v: vaarg_expr =>
			expr_finish(v);
			free(v);
		case let v: vaend_expr =>
			expr_finish(v);
			free(v);
		};
	case let y: yield_expr =>
		free(y.label);
		expr_finish(y.value);
		free(y.value);
	};
};

fn struct_literal_finish(s: *struct_literal) void = {
	ident_free(s.alias);
	for (let i = 0z; i < len(s.fields); i += 1) {
		match (s.fields[i]) {
		case let v: struct_value =>
			free(v.name);
			type_finish(v._type);
			free(v._type);
			expr_finish(v.init);
			free(v.init);
		case let c: *struct_literal =>
			struct_literal_finish(c);
			free(c);
		};
	};
	free(s.fields);
};
