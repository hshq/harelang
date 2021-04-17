@test fn binarithm() void = {
	roundtrip("export fn main() void = void + void * void / void;\n");
};

@test fn call() void = {
	roundtrip("export fn main() void = test();\n"
		"export fn main() void = test(void, void, void);\n"
		"export fn main() void = test(void, void, void...);\n"
		"export fn main() void = test()()(void);\n");
};

@test fn cast() void = {
	roundtrip("export fn main() void = void: int;\n"
		"export fn main() void = void as int;\n"
		"export fn main() void = void is int;\n"
		"export fn main() void = void: int: uint: u16: u8;\n"
		"export fn main() void = void: int as uint: u16 is u8;\n");
};

@test fn constant() void = {
	roundtrip("export fn main() void = 2 + -4 + void + true + \"hello\" + '?';\n");
};

@test fn control() void = {
	roundtrip("export fn main() void = {
	break;
	break :foo;
	continue;
	continue :foo;
	return;
	return 2 + 2;
};
");
};

@test fn list() void = {
	roundtrip("export fn main() void = {
	2 + 2;
	call();
};
");
};

@test fn postfix() void = {
	roundtrip("export fn main() void = x.y;\n"
		"export fn main() void = x.y.z.q;\n"
		"export fn main() void = x().y;\n"
		"export fn main() void = x.42;\n"
		"export fn main() void = x().y.0.q;\n"
		"export fn main() void = x?;\n"
		"export fn main() void = x()?.y;\n"
		"export fn main() void = x[10];\n"
		"export fn main() void = x[10 + 10][20];\n");
};

@test fn slice() void = {
	roundtrip("export fn main() void = x[..];\n"
		"export fn main() void = x[123..];\n"
		"export fn main() void = x[123..321];\n"
		"export fn main() void = x[..321];\n");
};

@test fn unarithm() void = {
	roundtrip("export fn main() void = +void;\n"
		"export fn main() void = -void;\n"
		"export fn main() void = *void;\n"
		"export fn main() void = ~void;\n"
		"export fn main() void = !void;\n"
		"export fn main() void = &x;\n");
};
