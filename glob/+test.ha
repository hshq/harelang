use fnmatch;
use strings;

@test fn glob() void = {
	const cases: [_](str, flags) = [
		("/u??/*in/a*", flags::NONE),
		("/u*r/l?[bc]*/[bg]*", flags::NOSORT),
		("/?sr/[sb]in/*[[:digit:]]*", flags::MARK),
		("/h??\\e/*/.*", flags::NOSORT | flags::MARK),
		("/\\h??e/*/.*", flags::NOSORT | flags::NOESCAPE),
		("/r*/*", flags::NOSORT),
		("/*.?a", flags::NOCHECK),
		("./*.[[:alpha:]]a", flags::NONE),
		("./\\a[bd]c", flags::NOESCAPE),
		("./\\a[be]c", flags::NONE),
		("[[:punct:]]*", flags::NONE),
		("/", flags::NONE),
		("//", flags::NONE),
		(".", flags::NONE),
		("..", flags::NONE),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		let gen = glob(cases[i].0, cases[i].1);
		defer globfree(&gen);
		for (true) match (next(&gen)) {
		case void =>
			break;
		case failure =>
			continue;
		case let s: str =>
			let bs = fnmatch::flags::PATHNAME;
			if (cases[i].1 & flags::NOESCAPE != 0) {
				bs |= fnmatch::flags::NOESCAPE;
			};
			assert(fnmatch::fnmatch(cases[i].0, s, bs)
				|| cases[i].1 & flags::MARK != 0
				&& fnmatch::fnmatch(
					cases[i].0,
					strings::rtrim(s, '/'),
					bs
				)
			);
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
