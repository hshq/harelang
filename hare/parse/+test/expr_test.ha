// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@test fn assignment() void = {
	roundtrip("export fn main() void = {
	x = y;
	*x = *y + 10;
	*x = *foo();
	*y() = bar();
	x[y] = z;
	x[y][z] = foo();
	x.y = z;
	x.y.z = foo();
	x[y].z = foo();
	x.y[z] = foo();
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
	x &&= true;
	x ||= true;
	x ^^= true;
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
	const (foo, bar): (int, bool) = (42, true);
	const (foo, _, bar): (int, uint, bool) = (42, 12u, true);
	def X: int = 1337, y = 7331;
	static let p: int = 62893, o = 39826;
	static const w: int = 62893, t = 39826;
};
");
};

@test fn builtin() void = {
	roundtrip(`export fn main() void = {
	align(u32);
	alloc(1234);
	alloc(1234...);
	alloc(4321, 1234);
	append(x, 10);
	append(x, [10]...);
	append(x, [10...], 20);
	static append(x, 10);
	abort();
	abort("surprize");
	static abort();
	static abort("surprize");
	assert(x == 12);
	assert(x == 12, "number mismatch");
	static assert(x == 12);
	static assert(x == 12, "number mismatch");
	delete(x[10]);
	delete(x[10..20]);
	delete(x[..]);
	delete(x.y.z[..]);
	static delete(x[10]);
	free(x);
	insert(x[0], foo);
	insert(x[0], foo...);
	insert(x[0], foo, bar);
	static insert(x[0], foo);
	len([1, 2, 3, 4]);
	offset(foo.bar);
	size(u32);
	vastart();
	vaarg(va);
	vaend(va);
};
`);
};

@test fn call() void = {
	roundtrip("export fn main() void = test();\n\n"
		"export fn main() void = test(void, void, void);\n\n"
		"export fn main() void = test(void, void, void...);\n\n"
		"export fn main() void = test()()(void);\n");
	roundtrip_reparse("export fn main() void = test(void,);\n");
};

@test fn cast() void = {
	roundtrip("export fn main() void = void: int;\n\n"
		"export fn main() void = void as int;\n\n"
		"export fn main() void = void is int;\n\n"
		"export fn main() void = void as null;\n\n"
		"export fn main() void = void is null;\n\n"
		"export fn main() void = void: int: uint: u16: u8;\n\n"
		"export fn main() void = void: int as uint: u16 is u8;\n\n"
		"export fn main() void = void: int as null: u16 is null;\n\n"
		"export fn main() void = {\n\tyield void;\n}: int;\n");
};

@test fn compound() void = {
	roundtrip("export fn main() void = :label {\n"
		"\tvoid;\n"
		"};\n");
};

@test fn constant() void = {
	roundtrip(`export fn main() void = {
	2 + (-4 + void) * true / ("hello" << '?');
	[1, 2, 3, 4];
	[1, 2, 3, 4...];
	(1, 2, 3);
	struct {
		x: int = 10,
		y: int = 20,
	};
	coords {
		x: int = 10,
		y: int = 20,
		...
	};
	coords {
		x = 10,
		y = 20,
	};
	struct {
		x: int = 10,
		struct {
			y: int = 20,
		},
	};
	struct {
		x: int = 10,
		coords {
			y: int = 20,
		},
	};
	struct {
		x: int = 10,
		namespace::coords {
			y: int = 20,
		},
	};
	coords {
		...
	};
	13.37;
	13.37f32;
	13.37f64;
	6.022e23;
	1.616255e-35;
	1337z;
	1337u;
	1337i8;
	1337u8;
	1337i16;
	1337u16;
	1337i32;
	1337u32;
	1337i64;
	1337u64;
	"backslashes\\and \"double quotes\"";
	'\'';
	'\\';
};
`);
	roundtrip_reparse(`export fn main() void = {
	struct { x: int = 10, y: int = 20 };
	coords { x: int = 10, y: int = 20 };
	"string " "concatenation";
};
`);
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
	roundtrip("export fn main() void = {
	defer foo();
};
");
};

@test fn for_expr() void = {
	roundtrip("fn next() (int | done) = 4;

export fn main() void = {
	for (true) {
		x;
	};
	for :label (true) {
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
	for (let x => next()) {
		x;
	};
	for (let x .. [1, 2, 3]) {
		x;
	};
	for (let x &.. [1, 2, 3]) {
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
	roundtrip("export fn main() void = x.y;\n\n"
		"export fn main() void = x.y.z.q;\n\n"
		"export fn main() void = x().y;\n\n"
		"export fn main() void = x.42;\n\n"
		"export fn main() void = x().y.0.q;\n\n"
		"export fn main() void = x?;\n\n"
		"export fn main() void = x!;\n\n"
		"export fn main() void = x()?.y;\n\n"
		"export fn main() void = x[10];\n\n"
		"export fn main() void = x[10 + 10][20];\n");
};

@test fn slice() void = {
	roundtrip("export fn main() void = x[..];\n\n"
		"export fn main() void = x[123..];\n\n"
		"export fn main() void = x[123..321];\n\n"
		"export fn main() void = x[..321];\n");
};

@test fn switch_expr() void = {
	roundtrip("export fn main() void = {
	switch (x) {
	case 1234, 4321 =>
		return y;
	case 1337 =>
		let x = 0;
	case => void;
	case => abort();
	case =>
		defer x;
	};
	switch :label (x) {
	case => void;
	};
};
");
};

@test fn match_expr() void = {
	roundtrip("export fn main() void = {
	match (x) {
	case let i: size =>
		return y;
	case foo =>
		return bar;
	case *int =>
		return bar;
	case foo::bar =>
		return baz;
	case null => void;
	case => abort();
	};
	match :label (x) {
	case let s: matchdata =>
		return y;
	case str =>
		let x = 0;
	case =>
		defer x;
	};
};
");
};

@test fn unarithm() void = {
	roundtrip("export fn main() void = -void;\n\n"
		"export fn main() void = *void;\n\n"
		"export fn main() void = ~void;\n\n"
		"export fn main() void = !void;\n\n"
		"export fn main() void = &void;\n\n"
		"export fn main() void = &switch (0) {\n"
		"case => void;\n"
		"};\n\n"
		"export fn main() void = &match (0) {\n"
		"case => void;\n"
		"};\n");
};

@test fn yield_expr() void = {
	roundtrip("export fn main() void = yield;\n\n"
		"export fn main() void = yield void;\n\n"
		"export fn main() void = yield :foo;\n\n"
		"export fn main() void = yield :foo, void;\n");
};

@test fn parenthesis() void = {
	roundtrip(
		"export fn main() void = -((2 + 2) * 2);\n\n"
		"export fn main() void = &(1: uint);\n\n"
		"export fn main() void = **x;\n\n"
		"export fn main() void = *alloc(2);\n\n"
		"export fn main() void = &(&x);\n\n"
		"export fn main() void = &*&*&x;\n\n"
		"export fn main() void = x: int: uint: u8;\n\n"
		"export fn main() void = &array[idx];\n\n"
		"export fn main() void = &array[idx..];\n\n"
		"export fn main() void = (array: *[*]u8)[idx];\n\n"
		"export fn main() void = (s: *object).field;\n\n"
		"export fn main() void = (s: *object).0;\n\n"
		"export fn main() void = &offset(header.x);\n\n"
		"export fn main() void = *((a + b): uintptr);\n\n"
		"export fn main() void = *value();\n\n"
		"export fn main() void = (ptr: function)();\n\n"
		"export fn main() void = func()?.field;\n\n"
		"export fn main() void = (x: thing)?;\n\n"
		"export fn main() void = (x: thing)!;\n\n"
		"export fn main() void = (hey: *[*]u8)[1..2];\n\n"
		"export fn main() void = (hey: *[*]u8)[0];\n\n"
		"export fn main() void = &{\n"
		"\t" "yield 12;\n"
		"};\n\n"
		"export fn main() void = ({\n"
		"\t" "yield err;\n"
		"})!;\n\n"
		"export fn main() void = &(if (true) 1 else 2);\n\n"
		"export fn main() void = (a + b): uintptr: size;\n");
};
