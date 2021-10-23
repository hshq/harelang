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
export type access_expr =
	(access_identifier | access_index | access_field | access_tuple);

// An allocation expression.
//
// 	alloc(foo)
export type alloc_expr = struct {
	init: *expr,
	capacity: nullable *expr,
};

// An append expression.
//
// 	append(foo, bar, (more), baz...)
export type append_expr = struct {
	object: *expr,
	variadic: nullable *expr,
	values: []*expr,
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
	indirect: bool,
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
export type binding = struct {
	name: str,
	_type: nullable *_type,
	init: *expr,
};

// A variable binding expression.
//
// 	let foo: int = bar, ...
export type binding_expr = struct {
	is_static: bool,
	is_const: bool,
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

// An array constant.
//
// 	[foo, bar, ...]
export type array_constant = struct {
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

// A struct constant.
//
// 	struct { foo: int = bar, struct { baz = quux }, ... }
export type struct_constant = struct {
	autofill: bool,
	alias: ident, // [] for anonymous
	fields: [](struct_value | *struct_constant),
};

// A tuple constant.
//
// 	(foo, bar, ...)
export type tuple_constant = []*expr;

// The value "null".
export type _null = void;

// A scalar value.
export type value = (void | bool | _null | ...lex::value);

// A constant expression.
export type constant_expr = (value | array_constant | struct_constant | tuple_constant);

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

// A for loop. The label is set to empty string if absent.
//
// 	:label for (let foo = 0; foo < bar; baz) quux
export type for_expr = struct {
	bindings: nullable *expr,
	cond: *expr,
	afterthought: nullable *expr,
	body: *expr,
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
// 	insert(foo[0], bar, (more), baz...)
export type insert_expr = struct {
	object: *expr,
	variadic: nullable *expr,
	values: []*expr,
	is_static: bool,
};

// :label. The ":" character is not included.
export type label = str;

// A length expression.
//
// 	len(foo)
export type len_expr = *expr;

// A match case.
//
// 	name: type => expr
export type match_case = struct {
	name: str,
	_type: *_type,
	exprs: []*expr,
};

// A match expression.
//
// 	match (foo) { _: int => bar, ... }
export type match_expr = struct {
	value: *expr,
	cases: []match_case,
	default: []*expr,
};

// An offset expression.
//
// 	offset(foo.bar)
export type offset_expr = *expr;

// An error propagation expression.
//
// 	foo?
export type propagate_expr = struct {
	is_abort: bool,
	expr: *expr,
};

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
// 	value => expr
export type switch_case = struct {
	options: []*expr, // [] for default case
	exprs: []*expr,
};

// A switch expression.
//
// 	switch (foo) { bar => baz, ... }
export type switch_expr = struct {
	value: *expr,
	cases: []switch_case,
};

// A type expression
export type type_expr = *_type;

// A unary operator
export type unarithm_op = enum {
	// TODO: Should this be rehomed with the checked AST?
	ADDR,	// &
	BNOT,	// ~
	DEREF,	// *
	LNOT,	// !
	MINUS,	// -
	PLUS,	// +
};

// A unary arithmetic expression.
//
// 	!example
export type unarithm_expr = struct {
	op: unarithm_op,
	operand: *expr,
};

// A yield expression.
//
// 	yield foo
export type yield_expr = struct {
	label: str,
	value: nullable *expr,
};

// A Hare expression.
export type expr = struct {
	start: lex::location,
	end: lex::location,
	expr: (access_expr | alloc_expr | append_expr | assert_expr |
		assign_expr | binarithm_expr | binding_expr | break_expr |
		call_expr | cast_expr | constant_expr | continue_expr |
		defer_expr | delete_expr | for_expr | free_expr | if_expr |
		insert_expr | compound_expr | match_expr | len_expr |
		size_expr | offset_expr | propagate_expr | return_expr |
		slice_expr | switch_expr | type_expr | unarithm_expr |
		yield_expr),
};

// Frees resources associated with a Hare [[expr]]ession.
export fn expr_free(e: (expr | nullable *expr)) void = match (e) {
case e: nullable *expr =>
	match (e) {
	case null => void;
	case e: *expr =>
		expr_free(*e);
		free(e);
	};
case e: expr =>
	match (e.expr) {
	case a: access_expr =>
		match (a) {
		case i: access_identifier =>
			ident_free(i);
		case i: access_index =>
			expr_free(i.object);
			expr_free(i.index);
		case f: access_field =>
			expr_free(f.object);
			free(f.field);
		case t: access_tuple =>
			expr_free(t.object);
			expr_free(t.value);
		};
	case a: alloc_expr =>
		expr_free(a.init);
		expr_free(a.capacity);
	case a: append_expr =>
		expr_free(a.object);
		match (a.variadic) {
		case null => void;
		case v: *expr =>
			expr_free(v);
		};
		for (let i = 0z; i < len(a.values); i += 1) {
			expr_free(a.values[i]);
		};
		free(a.values);
	case a: assert_expr =>
		expr_free(a.cond);
		expr_free(a.message);
	case a: assign_expr =>
		expr_free(a.object);
		expr_free(a.value);
	case b: binarithm_expr =>
		expr_free(b.lvalue);
		expr_free(b.rvalue);
	case b: binding_expr =>
		for (let i = 0z; i < len(b.bindings); i += 1) {
			free(b.bindings[i].name);
			type_free(b.bindings[i]._type);
			expr_free(b.bindings[i].init);
		};
		free(b.bindings);
	case b: break_expr =>
		free(b);
	case c: call_expr =>
		expr_free(c.lvalue);
		for (let i = 0z; i < len(c.args); i += 1) {
			expr_free(c.args[i]);
		};
		free(c.args);
	case c: cast_expr =>
		expr_free(c.value);
		type_free(c._type);
	case c: compound_expr =>
		for (let i = 0z; i < len(c.exprs); i += 1) {
			expr_free(c.exprs[i]);
		};
		free(c.exprs);
		free(c.label);
	case c: constant_expr =>
		match (c) {
		case (void | _null | ...lex::value) => void;
		case a: array_constant =>
			for (let i = 0z; i < len(a.values); i += 1) {
				expr_free(a.values[i]);
			};
			free(a.values);
		case s: struct_constant =>
			struct_constant_free(s);
		case t: tuple_constant =>
			for (let i = 0z; i < len(t); i += 1) {
				expr_free(t[i]);
			};
			free(t);
		};
	case c: continue_expr =>
		free(c);
	case d: defer_expr =>
		expr_free(d: *expr);
	case d: delete_expr =>
		expr_free(d.object);
	case f: for_expr =>
		expr_free(f.bindings);
		expr_free(f.cond);
		expr_free(f.afterthought);
		expr_free(f.body);
	case f: free_expr =>
		expr_free(f: *expr);
	case i: if_expr =>
		expr_free(i.cond);
		expr_free(i.tbranch);
		expr_free(i.fbranch);
	case e: insert_expr =>
		expr_free(e.object);
		match (e.variadic) {
		case null => void;
		case v: *expr =>
			expr_free(v);
		};
		for (let i = 0z; i < len(e.values); i += 1) {
			expr_free(e.values[i]);
		};
		free(e.values);
	case l: len_expr =>
		expr_free(l: *expr);
	case m: match_expr =>
		expr_free(m.value);
		for (let i = 0z; i < len(m.cases); i += 1) {
			free(m.cases[i].name);
			type_free(m.cases[i]._type);
			const exprs = m.cases[i].exprs;
			for (let i = 0z; i < len(exprs); i += 1) {
				expr_free(exprs[i]);
			};
			free(exprs);
		};
		free(m.cases);
		for (let i = 0z; i < len(m.default); i += 1) {
			expr_free(m.default[i]);
		};
		free(m.default);
	case o: offset_expr =>
		expr_free(o: *expr);
	case p: propagate_expr =>
		expr_free(p.expr);
	case r: return_expr =>
		expr_free(r: *expr);
	case s: size_expr =>
		type_free(s: *_type);
	case s: slice_expr =>
		expr_free(s.object);
		expr_free(s.start);
		expr_free(s.end);
	case s: switch_expr =>
		expr_free(s.value);
		for (let i = 0z; i < len(s.cases); i += 1) {
			let opts = s.cases[i].options;
			for (let j = 0z; j < len(opts); j += 1) {
				expr_free(opts[j]);
			};
			free(opts);

			let exprs = s.cases[i].exprs;
			for (let j = 0z; j < len(exprs); j += 1) {
				expr_free(exprs[j]);
			};
			free(exprs);
		};
		free(s.cases);
	case t: type_expr =>
		type_free(t);
	case u: unarithm_expr =>
		expr_free(u.operand);
	case y: yield_expr =>
		free(y.label);
		expr_free(y.value);
	};
};

fn struct_constant_free(s: struct_constant) void = {
	ident_free(s.alias);
	for (let i = 0z; i < len(s.fields); i += 1) {
		match (s.fields[i]) {
		case v: struct_value =>
			free(v.name);
			type_free(v._type);
			expr_free(v.init);
		case c: *struct_constant =>
			struct_constant_free(*c);
			free(c);
		};
	};
	free(s.fields);
};
