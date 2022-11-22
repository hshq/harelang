// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

@test fn struct_union() void = {
	roundtrip("export type foo = struct {
	@offset(void) x: int,
	y: int,
};

export type bar = union {
	x: int,
	// docs docs docs
	y: int,
};

export type baz = struct {
	embedded,
	struct {
		x: int,
		y: int,
	},
};
");
};

@test fn array_slice() void = {
	roundtrip("export type foo = []int;

export type bar = [*]int;

export type baz = [_]int;

export type bat = [void]int;
");
};

@test fn enum_type() void = {
	roundtrip("export type foo = enum {
	X = void,
	// foo
	// bar
	Y = void,
	Z, // foo
	Q, // bar
};

export type bar = enum uint {
	X = void,
	Y = void,
	Z,
	Q,
};

export type baz = enum rune {
	X = void,
	Y = void,
	Z,
	Q,
};
");
};

@test fn tuple() void = {
	roundtrip("export type foo = (int, str);

export type bar = (a, b::c, d);

export type baz = (bat, foo::bar::baz, long_type_name, yet_another_very_long_type_name,
	this_spans_multiple_lines, for_readability);
");
};

@test fn tagged_union() void = {
	roundtrip("export type foo = (size | void);

export type bar = (a | b::c | ...d);

export type baz = (bat | foo::bar::baz | long_type_name | yet_another_very_long_type_name |
	this_spans_multiple_lines | for_readability);
");
};

@test fn enum_comments() void = {
	roundtrip("type foo = enum {
	A, // comment
	B,
	C,
};
");
};
