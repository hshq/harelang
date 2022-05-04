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
		defer finish(&gen);
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

@test fn pattern_parse() void = {
	const cases: [_](str, bool, str, str, str) = [
		("foo/bar/baz", true, "foo/bar/", "baz", ""),
		("foo/b\\ar/baz", true, "foo/b\\ar/", "baz", ""),
		("foo/b\\ar/baz", false, "foo/bar/", "baz", ""),
		("/foo/bar/baz", true, "/foo/bar/", "baz", ""),
		("/foo\\/bar/baz", true, "/foo\\/bar/", "baz", ""),
		("/foo\\/bar/baz", false, "/foo/bar/", "baz", ""),
		("/foo/bar\\/baz", true, "/foo/bar\\/", "baz", ""),
		("/foo/bar\\/baz", false, "/foo/bar/", "baz", ""),
		("/foobarbaz", true, "/", "foobarbaz", ""),
		("foo/bar/baz/", true, "foo/bar/baz/", "", ""),
		("foobarbaz/", true, "foobarbaz/", "", ""),
		("foobarbaz", true, "", "foobarbaz", ""),
		("foo/b?r/baz", true, "foo/", "b?r/", "baz"),
		("foo/b?r\\/baz", true, "foo/", "b?r\\/", "baz"),
		("foo/b?r\\/baz", false, "foo/", "b?r/", "baz"),
		("foob*rbaz/", true, "", "foob*rbaz/", ""),
		("foo[bar]baz", true, "", "foo[bar]baz", ""),
		("foo/b[ar]/baz/", true, "foo/", "b[ar]/", "baz/"),
		("foo/b[a\\r]/baz/", false, "foo/", "b[a\\r]/", "baz/"),
		("foo/b[a\\r]/baz/", true, "foo/", "b[a\\r]/", "baz/"),
		("foo/b[ar]/baz\\/", true, "foo/", "b[ar]/", "baz\\/"),
		("foo/b[ar]/baz\\/", false, "foo/", "b[ar]/", "baz\\/"),
		("foo/b\\[ar]/baz\\/", true, "foo/", "b\\[ar]/", "baz\\/"),
		("foo/b\\[ar]/baz\\/", false, "foo/b[ar]/baz/", "", ""),
		("fo[o/ba[r/baz", true, "fo[o/ba[r/", "baz", ""),
		("fo]o/bar/b[az", false, "fo]o/bar/", "b[az", ""),
		("foo/ba]r/b]az", true, "foo/ba]r/", "b]az", ""),
		("foo/ba[r/b]az", false, "foo/ba[r/", "b]az", ""),
		("fo[o/bar/b]az", true, "fo[o/bar/", "b]az", ""),
	];
	let p = pattern_init();
	defer pattern_free(&p);
	for (let i = 0z; i < len(cases); i += 1) {
		pattern_parse(&p, cases[i].0, cases[i].1);
		const dir = pattern_dir(&p);
		const pat = pattern_pat(&p);
		const rem = pattern_rem(&p);
		assert(strings::compare(dir, cases[i].2) == 0);
		assert(strings::compare(pat, cases[i].3) == 0);
		assert(strings::compare(rem, cases[i].4) == 0);
	};
};
