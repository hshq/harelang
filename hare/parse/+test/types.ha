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
