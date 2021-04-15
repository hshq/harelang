@test fn struct_union() void = {
	roundtrip("export type foo = struct {
	@offset(void) x: int,
	y: int,
};
export type bar = union {
	x: int,
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
