// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fnmatch;
use strings;

@test fn glob() void = {
	const cases: [_](str, flag) = [
		("/u??/*in/a*", flag::NONE),
		("/u*r/l?[bc]*/[bg]*", flag::NOSORT),
		("/?sr/[sb]in/*[[:digit:]]*", flag::MARK),
		("/h??\\e/*/.*", flag::NOSORT | flag::MARK),
		("/\\h??e/*/.*", flag::NOSORT | flag::NOESCAPE),
		("/r*/*", flag::NOSORT),
		("/*.?a", flag::NOCHECK),
		("./*.[[:alpha:]]a", flag::NONE),
		("./\\a[bd]c", flag::NOESCAPE),
		("./\\a[be]c", flag::NONE),
		("[[:punct:]]*", flag::NONE),
		("/", flag::NONE),
		("//", flag::NONE),
		(".", flag::NONE),
		("..", flag::NONE),
		("\\*", flag::NONE),
	];
	for (let c .. cases) {
		let gen = glob(c.0, c.1);
		defer finish(&gen);
		for (true) match (next(&gen)) {
		case done =>
			break;
		case failure =>
			continue;
		case let s: str =>
			let bs = fnmatch::flag::PATHNAME;
			if (c.1 & flag::NOESCAPE != 0) {
				bs |= fnmatch::flag::NOESCAPE;
			};
			assert(fnmatch::fnmatch(c.0, s, bs)
				|| c.1 & flag::MARK != 0
				&& fnmatch::fnmatch(
					c.0,
					strings::rtrim(s, '/'),
					bs
				)
			);
		};
	};
};

@test fn pattern_parse() void = {
	const cases: [_](str, bool, str, str, str) = [
		("foo/bar/baz", true, "foo/bar/baz", "", ""),
		("foo/b\\ar/baz", true, "foo/b\\ar/baz", "", ""),
		("foo/b\\ar/baz", false, "foo/bar/baz", "", ""),
		("/foo/bar/baz", true, "/foo/bar/baz", "", ""),
		("/foo\\/bar/baz", true, "/foo\\/bar/baz", "", ""),
		("/foo\\/bar/baz", false, "/foo/bar/baz", "", ""),
		("/foo/bar\\/baz", true, "/foo/bar\\/baz", "", ""),
		("/foo/bar\\/baz", false, "/foo/bar/baz", "", ""),
		("/foobarbaz", true, "/foobarbaz", "", ""),
		("foo/bar/baz/", true, "foo/bar/baz/", "", ""),
		("foobarbaz/", true, "foobarbaz/", "", ""),
		("foobarbaz", true, "foobarbaz", "", ""),
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
		("fo[o/ba[r/baz", true, "fo[o/ba[r/baz", "", ""),
		("fo]o/bar/b[az", false, "fo]o/bar/b[az", "", ""),
		("foo/ba]r/b]az", true, "foo/ba]r/b]az", "", ""),
		("foo/ba[r/b]az", false, "foo/ba[r/", "b]az", ""),
		("fo[o/bar/b]az", true, "fo[o/bar/", "b]az", ""),
	];
	let p = pattern_init();
	defer pattern_free(&p);
	for (let c .. cases) {
		pattern_parse(&p, c.0, c.1);
		const dir = pattern_dir(&p);
		const pat = pattern_pat(&p);
		const rem = pattern_rem(&p);
		assert(dir == c.2);
		assert(pat == c.3);
		assert(rem == c.4);
	};
};
