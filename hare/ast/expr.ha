use hare::lex;

// foo
export type access_identifier = ident;

// foo[0]
export type access_index = struct {
	object: *expr,
	index: *expr,
};

// foo.bar
export type access_field = struct {
	object: *expr,
	field: str,
};

// foo.1
export type access_tuple = struct {
	object: *expr,
	value: *expr,
};

export type access_expr =
	(access_identifier | access_index | access_field | access_tuple);

// alloc(foo)
export type alloc_expr = struct {
	expr: *expr,
	capacity: nullable *expr,
};

// append(foo, bar, (more), ...baz)
export type append_expr = struct {
	expr: *expr,
	variadic: nullable *expr,
	values: []*expr,
};

// assert(foo), assert(foo, "error"), abort(), abort("error")
export type assert_expr = struct {
	cond: nullable *expr,
	message: nullable *expr,
	is_static: bool,
};

// foo = bar
export type assign_expr = struct {
	op: binarithm_op,
	object: *expr,
	value: *expr,
	indirect: bool,
};

// TODO: Rehome this with the checked AST?
export type binarithm_op = enum {
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

// foo * bar
export type binarithm_expr = struct {
	op: binarithm_op,
	lvalue: *expr,
	rvalue: *expr,
};

// let foo: int = bar
export type binding_expr = struct {
	name: str,
	_type: nullable *_type,
	is_static: bool,
	init: *expr,
};

// break :label
export type break_expr = label;

// foo(bar)
export type call_expr = struct {
	lvalue: *expr,
	variadic: bool,
	args: []*expr,
};

// TODO: Should this be rehomed with the checked AST?
export type cast_kind = enum {
	CAST,
	ASSERTION,
	TEST,
};

// foo: int
export type cast_expr = struct {
	kind: cast_kind,
	value: *expr,
	_type: *_type,
};

// [foo, bar, ...]
export type array_constant = struct {
	expand: bool,
	values: []*expr,
};

export type struct_value = struct {
	name: str,
	_type: nullable *_type,
	init: *expr,
};

// struct { foo: int = bar, struct { baz = quux }, ... }
export type struct_constant = struct {
	autofill: bool,
	alias: ident, // [] for anonymous
	fields: [](struct_value | *struct_constant),
};

// (foo, bar, ...)
export type tuple_constant = []*expr;

// A constant
export type constant_expr = (void | lex::literal | array_constant |
	struct_constant | tuple_constant);

// continue :label
export type continue_expr = label;

// defer foo
export type defer_expr = *expr;

// delete(foo)
export type delete_expr = *expr;

// :label for (let foo = 0; foo < bar; baz) quux
export type for_expr = struct {
	label: label,
	bindings: nullable *expr,
	cond: *expr,
	afterthought: nullable *expr,
	body: *expr,
};

// free(foo)
export type free_expr = *expr;

// if (foo) bar else baz
export type if_expr = struct {
	cond: *expr,
	true_branch: nullable *expr,
	false_branch: nullable *expr,
};

// :label. The ":" character is not included.
export type label = str;

// len(foo)
export type len_expr = *expr;

// { foo; bar; ... }
export type list_expr = []*expr;

export type match_case = struct {
	name: str,
	_type: *_type,
	value: *expr,
};

// match (foo) { int => bar, ... }
export type match_expr = struct {
	value: *expr,
	cases: []match_case,
	default: nullable *expr,
};

// offset(foo.bar)
export type offset_expr = void; // TODO

// foo?
export type propagate_expr = *expr;

// return foo
export type return_expr = *expr;

// size(int)
export type size_expr = *_type;

// foo[bar..baz]
export type slice_expr = struct {
	object: *expr,
	start: nullable *expr,
	end: nullable *expr,
};

export type switch_case = struct {
	options: []*expr, // [] for *
	value: *expr,
};

// switch (foo) { bar => baz, ... }
export type switch_expr = struct {
	value: *expr,
	cases: []switch_case,
};

// A unary operator
// TODO: Should this be rehomed with the checked AST?
export type unarithm_op = enum {
	ADDR,	// &
	BNOT,	// ~
	DEREF,	// *
	LNOT,	// !
	MINUS,	// -
	PLUS,	// +
};

// Unary arithmetic
export type unarithm_expr = struct {
	op: unarithm_op,
	operand: *expr,
};

// An expression
export type expr = (access_expr | alloc_expr | append_expr | assert_expr |
	assign_expr | binarithm_expr | []binding_expr | break_expr | call_expr |
	cast_expr | constant_expr | continue_expr | defer_expr | delete_expr |
	for_expr | free_expr | if_expr | list_expr | match_expr | len_expr |
	size_expr | offset_expr | propagate_expr | return_expr | slice_expr |
	switch_expr | unarithm_expr);

export fn expr_free(e: (expr | nullable *expr)) void = match (e) {
	e: nullable *expr => match (e) {
		null => void,
		e: *expr => {
			expr_free(*e);
			free(e);
		},
	},
	e: expr => match (e) {
		a: access_expr => match (a) {
			i: access_identifier => ident_free(i),
			i: access_index => {
				expr_free(i.object);
				expr_free(i.index);
			},
			f: access_field => {
				expr_free(f.object);
				free(f.field);
			},
			t: access_tuple => {
				expr_free(t.object);
				expr_free(t.value);
			},
		},
		a: alloc_expr => {
			expr_free(a.expr);
			expr_free(a.capacity);
		},
		a: append_expr => {
			expr_free(a.expr);
			match (a.variadic) {
				null => void,
				v: *expr => expr_free(v),
			};
			for (let i = 0z; i < len(a.values); i += 1) {
				expr_free(a.values[i]);
			};
			free(a.values);
		},
		a: assert_expr => {
			expr_free(a.cond);
			expr_free(a.message);
		},
		a: assign_expr => {
			expr_free(a.object);
			expr_free(a.value);
		},
		b: binarithm_expr => {
			expr_free(b.lvalue);
			expr_free(b.rvalue);
		},
		b: []binding_expr => {
			for (let i = 0z; i < len(b); i += 1) {
				free(b[i].name);
				type_free(b[i]._type);
				expr_free(b[i].init);
			};
			free(b);
		},
		b: break_expr => free(b),
		c: call_expr => {
			expr_free(c.lvalue);
			for (let i = 0z; i < len(c.args); i += 1) {
				expr_free(c.args[i]);
			};
			free(c.args);
		},
		c: cast_expr => {
			expr_free(c.value);
			expr_free(c._type);
		},
		c: constant_expr => match(c) {
			(void | lex::literal) => void,
			a: array_constant => {
				for (let i = 0z; i < len(a.values); i += 1) {
					expr_free(a.values[i]);
				};
				free(a.values);
			},
			s: struct_constant => {
				ident_free(s.alias);
				for (let i = 0z; i < len(s.fields); i += 1) {
					match (s.fields[i]) {
						v: struct_value => {
							free(v.name);
							type_free(v._type);
							expr_free(v.init);
						},
						c: *struct_constant =>
							expr_free(c: *expr),
					};
				};
				free(s.fields);
			},
			t: tuple_constant => {
				for (let i = 0z; i < len(t); i += 1) {
					expr_free(t[i]);
				};
				free(t);
			},
		},
		c: continue_expr => free(c),
		d: defer_expr => expr_free(d: *expr),
		d: delete_expr => expr_free(d: *expr),
		f: for_expr => {
			free(f.label);
			expr_free(f.bindings);
			expr_free(f.cond);
			expr_free(f.afterthought);
			expr_free(f.body);
		},
		f: free_expr => expr_free(f: *expr),
		i: if_expr => {
			expr_free(i.cond);
			expr_free(i.true_branch);
			expr_free(i.false_branch);
		},
		l: len_expr => expr_free(l: *expr),
		l: list_expr => {
			for (let i = 0z; i < len(l); i += 1) {
				expr_free(l[i]);
			};
			free(l);
		},
		m: match_expr => {
			expr_free(m.value);
			for (let i = 0z; i < len(m.cases); i += 1) {
				free(m.cases[i].name);
				type_free(m.cases[i]._type);
				expr_free(m.cases[i].value);
			};
			free(m.cases);
		},
		o: offset_expr => abort(), // TODO
		p: propagate_expr => expr_free(p: *expr),
		r: return_expr => expr_free(r: *expr),
		s: size_expr => type_free(s: *_type),
		s: slice_expr => {
			expr_free(s.object);
			expr_free(s.start);
			expr_free(s.end);
		},
		s: switch_expr => {
			expr_free(s.value);
			for (let i = 0z; i < len(s.cases); i += 1) {
				let opts = s.cases[i].options;
				for (let j = 0z; j < len(opts); j += 1) {
					expr_free(opts[i]);
				};
				free(opts);
				expr_free(s.cases[i].value);
			};
			free(s.cases);
		},
		u: unarithm_expr => expr_free(u.operand),
	},
};
