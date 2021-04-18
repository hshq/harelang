@test fn assignment() void = {
	roundtrip("export fn main() void = {
	x = y;
	*x = *y + 10;
	*x = *foo();
	x += 10;
	x -= 10;
	x *= 10;
	x /= 10;
	x %= 10;
	x &= 10;
	x |= 10;
	x ^= 10;
	x >>= 10;
	x <<= 10;
};
");
};

@test fn binarithm() void = {
	roundtrip("export fn main() void = *void + void * void / void;\n");
};

@test fn binding() void = {
	roundtrip("export fn main() void = {
	let x: int = 1337, y = 7331;
	const z: int = 42, q: int = 24;
	static let p: int = 62893, o = 39826;
	static const w: int = 62893, t = 39826;
};
");
};

@test fn builtin() void = {
	roundtrip("export fn main() void = {
	alloc(1234);
	alloc(4321, 1234);
};
");
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
	// XXX: nested-expression should probably be tested here, but it
	// presents a problem for round tripping because it does not end up in
	// the AST. We would need unparse to be able to tell that a given AST
	// does not match the precedence requirements, and thus infer that
	// parenthesis are needed to unparse it correctly.
	roundtrip("export fn main() void = {
	2 + -4 + void + true + \"hello\" + '?';
	[1, 2, 3, 4];
	[1, 2, 3, 4...];
	(1, 2, 3);
};
");
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

@test fn defer_expr() void = {
	roundtrip("export fn main() void = defer foo();\n");
};

@test fn for_expr() void = {
	roundtrip("export fn main() void = {
	for (true) {
		x;
	};
	:label for (true) {
		x;
	};
	for (let x = 0; x < 10) {
		x;
	};
	for (x < 10; x) {
		x;
	};
	for (let x = 10; x < 10; x) {
		x;
	};
};
");
};

@test fn if_expr() void = {
	roundtrip("export fn main() void = {
	if (x == y) {
		z;
	};
	if (y == x) z;
	if (z == q) r else p;
	if (a == b) c else if (d == e) f else g;
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

@test fn switch_expr() void = {
	roundtrip("export fn main() void = {
	switch (x) {
		1234, 4321 => y,
		1337 => {
			z;
		},
		* => q,
	};
};
");
};

@test fn unarithm() void = {
	roundtrip("export fn main() void = +void;\n"
		"export fn main() void = -void;\n"
		"export fn main() void = *void;\n"
		"export fn main() void = ~void;\n"
		"export fn main() void = !void;\n"
		"export fn main() void = &x;\n");
};
