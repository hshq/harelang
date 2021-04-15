@test fn binarithm() void = {
	roundtrip("export fn main() void = void + void * void / void;\n");
};

@test fn constant() void = {
	roundtrip("export fn main() void = 2 + -4 + void + true + \"hello\" + '?';\n");
};

@test fn cast() void = {
	roundtrip("export fn main() void = void: int;\n"
		"export fn main() void = void as int;\n"
		"export fn main() void = void is int;\n"
		"export fn main() void = void: int: uint: u16: u8;\n"
		"export fn main() void = void: int as uint: u16 is u8;\n");
};

@test fn unarithm() void = {
	// TODO: object selectors/addr operator
	roundtrip("export fn main() void = +void;\n"
		"export fn main() void = -void;\n"
		"export fn main() void = *void;\n"
		"export fn main() void = ~void;\n"
		"export fn main() void = !void;\n");
};
