use fnmatch;

@test fn glob() void = {
	const cases: [_]str = [
		"/u??/*in/a*",
		"/?sr/[sb]in/*[[:digit:]]*",
		"/*.?a",
		"./*.[[:alpha:]]a",
		"[[:punct:]]*",
		"/",
		"//",
		".",
		"..",
	];
	const flags = [fnmatch::flags::PATHNAME];
	for (let i = 0z; i < len(cases); i += 1) {
		let gen = glob(cases[i]);
		defer globfree(&gen);
		for (true) match (next(&gen)) {
		case void =>
			break;
		case let s: str =>
			assert(fnmatch::fnmatch(cases[i], s, flags...));
		};
	};
};

@test fn split_pattern() void = {
	const cases: [_](str, size, size) = [
		("foo/bar/baz", 8, 11),
		("/foo/bar/baz", 9, 12),
		("/foobarbaz", 1, 10),
		("foo/bar/baz/", 12, 12),
		("foobarbaz/", 10, 10),
		("foobarbaz", 0, 9),
		("foo/b?r/baz", 4, 8),
		("foob*rbaz/", 0, 10),
		("foo[bar]baz", 0, 11),
		("fo[o/ba[r/baz", 10, 13),
		("fo]o/bar/b[az", 9, 13),
		("foo/ba]r/b]az", 9, 13),
		("foo/ba[r/b]az", 9, 13),
		("fo[o/bar/b]az", 9, 13),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const ends = split_pattern(cases[i].0);
		assert(ends.0 == cases[i].1);
		assert(ends.1 == cases[i].2);
	};
};
