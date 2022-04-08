// License: MPL-2.0
// (c) 2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use fmt;
use io;
use os;
use strings;

def PERFTEST_ON: bool = false;
type matchres = enum { MATCH, NOMATCH, ERROR };

fn run_find_case(
	expr: str,
	string: str,
	expected: matchres,
	start: int,
	end: int
) void = {
	const re = match (compile(expr)) {
	case let re: regex => yield re;
	case let e: error =>
		if (expected == matchres::MATCH) {
			fmt::println(e)!;
			fmt::fatal("Expected expression /{}/ to match, but it errored",
				expr, string);
		};
		if (expected == matchres::NOMATCH) {
			fmt::println(e)!;
			fmt::fatal("Expected expression /{}/ to not match, but it errored",
				expr, string);
		};
		return;
	};

	match (find(re, string)) {
	case void =>
		if (expected == matchres::MATCH) {
			fmt::fatal("Expected expression /{}/ to match string \"{}\", but it did not",
				expr, string);
		};
		if (expected == matchres::ERROR) {
			fmt::fatal("Expression /{}/ failed to match, but should have errored",
				expr, string);
		};

	case let m: []matchgroup =>
		if (expected == matchres::NOMATCH) {
			fmt::fatal("Expected expression /{}/ to not match string \"{}\", but it did",
				expr, string);
		};
		if (expected == matchres::ERROR) {
			fmt::fatal("Expression /{}/ matched, but should have errored",
				expr, string);
		};
		if (start: size != m[0].start) {
			fmt::fatal("Expected start of main match group to be {} but it was {}",
				start, m[0].start);
		};
		if (end: size != m[0].end) {
			fmt::fatal("Expected end of main match group to be {} but it was {}",
				end, m[0].end);
		};

	case let e: error =>
		if (expected == matchres::MATCH) {
			fmt::fatal("Expected expression /{}/ to match, but it errored",
				expr, string);
		};
		if (expected == matchres::NOMATCH) {
			fmt::fatal("Expected expression /{}/ to not match, but it errored",
				expr, string);
		};
	};
};

fn run_findall_case(
	expr: str,
	string: str,
	expected: matchres,
	count: int
) void = {
	const re = match (compile(expr)) {
	case let re: regex => yield re;
	case let e: error =>
		if (expected == matchres::MATCH) {
			fmt::println(e)!;
			fmt::fatal("Expected expression /{}/ to match, but it errored",
				expr, string);
		};
		if (expected == matchres::NOMATCH) {
			fmt::println(e)!;
			fmt::fatal("Expected expression /{}/ to not match, but it errored",
				expr, string);
		};
		return;
	};

	match (findall(re, string)) {
	case void =>
		if (expected == matchres::MATCH) {
			fmt::fatal("Expected expression /{}/ to match string \"{}\", but it did not",
				expr, string);
		};
		if (expected == matchres::ERROR) {
			fmt::fatal("Expression /{}/ failed to match, but should have errored",
				expr, string);
		};

	case let groupsets: [][]matchgroup =>
		if (expected == matchres::NOMATCH) {
			fmt::fatal("Expected expression /{}/ to not match string \"{}\", but it did",
				expr, string);
		};
		if (expected == matchres::ERROR) {
			fmt::fatal("Expression /{}/ matched, but should have errored",
				expr, string);
		};
		if (count: size != len(groupsets)) {
			fmt::fatal("Expected to find {} matches but found {}",
				count, len(groupsets));
		};

	case let e: error =>
		if (expected == matchres::MATCH) {
			fmt::fatal("Expected expression /{}/ to match, but it errored",
				expr, string);
		};
		if (expected == matchres::NOMATCH) {
			fmt::fatal("Expected expression /{}/ to not match, but it errored",
				expr, string);
		};
	};
};

@test fn find() void = {
	const cases = [
		// literals
		(`^$`, "", matchres::MATCH, 0, 0),
		(``, "", matchres::MATCH, 0, -1),
		(`abcd`, "abcd", matchres::MATCH, 0, -1),
		(`abc`, "abcd", matchres::MATCH, 0, 3),
		(`bcd`, "abcd", matchres::MATCH, 1, 4),
		(`^abc$`, "abc", matchres::MATCH, 0, -1),
		(`^abc$`, "axc", matchres::NOMATCH, 0, -1),
		// .
		(`^.$`, "x", matchres::MATCH, 0, 1),
		(`^.$`, "y", matchres::MATCH, 0, 1),
		(`^.$`, "", matchres::NOMATCH, 0, 1),
		// +
		(`^a+$`, "a", matchres::MATCH, 0, 1),
		(`^a+$`, "aaa", matchres::MATCH, 0, 3),
		(`^a+$`, "", matchres::NOMATCH, 0, 0),
		(`^(abc)+$`, "abc", matchres::MATCH, 0, 3),
		(`^(abc)+$`, "abcabc", matchres::MATCH, 0, 6),
		(`^(abc)+$`, "", matchres::NOMATCH, 0, 0),
		// *
		(`^a*$`, "", matchres::MATCH, 0, 0),
		(`^a*$`, "aaaa", matchres::MATCH, 0, 4),
		(`^a*$`, "b", matchres::NOMATCH, 0, 0),
		(`^(abc)*$`, "", matchres::MATCH, 0, 0),
		(`^(abc)*$`, "abc", matchres::MATCH, 0, 3),
		(`^(abc)*$`, "abcabc", matchres::MATCH, 0, 6),
		(`^(abc)*$`, "bbb", matchres::NOMATCH, 0, 3),
		// ?
		(`^a?$`, "", matchres::MATCH, 0, 0),
		(`^a?$`, "a", matchres::MATCH, 0, 1),
		(`^a?$`, "b", matchres::NOMATCH, 0, 0),
		(`^(abc)?$`, "", matchres::MATCH, 0, 0),
		(`^(abc)?$`, "abc", matchres::MATCH, 0, 3),
		(`^(abc)?$`, "bbb", matchres::NOMATCH, 0, 0),
		// ^ and $
		(`^a*`, "aaaa", matchres::MATCH, 0, 4),
		(`a*$`, "aaaa", matchres::MATCH, 0, 4),
		(`^a*$`, "aaaa", matchres::MATCH, 0, 4),
		(`a*`, "aaaa", matchres::MATCH, 0, 4),
		(`b*`, "aaaabbbb", matchres::MATCH, 4, 8),
		(`^b*`, "aaaabbbb", matchres::MATCH, 0, 0),
		(`b*$`, "aaaabbbb", matchres::MATCH, 4, 8),
		// (a|b)
		(`^(cafe|b)x$`, "cafex", matchres::MATCH, 0, 5),
		(`^(cafe|b)x$`, "bx", matchres::MATCH, 0, 2),
		(`^(cafe|b)x$`, "XXXx", matchres::NOMATCH, 0, 0),
		(`^(cafe|b)x$`, "bx", matchres::MATCH, 0, 2),
		(
			`^(Privat|Jagd)(haftpflicht|schaden)versicherungs(police|betrag)$`,
			"Jagdhaftpflichtversicherungsbetrag",
			matchres::MATCH, 0, -1
		),
		(
			`^(Privat|Jagd)(haftpflicht|schaden)versicherungs(police|betrag)$`,
			"Jagdhaftpflichtversicherungsbetrug",
			matchres::NOMATCH, 0, -1
		),
		(
			`^(Privat|Jagd)(haftpflicht|schaden)versicherungs(police|betrag)$`,
			"Jagdversicherungspolice",
			matchres::NOMATCH, 0, -1
		),
		(`)`, "", matchres::ERROR, 0, 0),
		// [abc]
		(`^test[abc]$`, "testa", matchres::MATCH, 0, -1),
		(`^test[abc]$`, "testb", matchres::MATCH, 0, -1),
		(`^test[abc]$`, "testc", matchres::MATCH, 0, -1),
		(`^test[abc]$`, "testd", matchres::NOMATCH, 0, -1),
		(`^test[abc]*$`, "test", matchres::MATCH, 0, -1),
		(`^test[abc]*$`, "testa", matchres::MATCH, 0, -1),
		(`^test[abc]*$`, "testaaa", matchres::MATCH, 0, -1),
		(`^test[abc]*$`, "testabc", matchres::MATCH, 0, -1),
		(`^test[abc]?$`, "test", matchres::MATCH, 0, -1),
		(`^test[abc]?$`, "testa", matchres::MATCH, 0, -1),
		(`^test[abc]+$`, "testa", matchres::MATCH, 0, -1),
		(`^test[abc]+$`, "test", matchres::NOMATCH, 0, -1),
		(`^test[]abc]$`, "test]", matchres::MATCH, 0, -1),
		(`^test[[abc]$`, "test[", matchres::MATCH, 0, -1),
		(`^test[^abc]$`, "testd", matchres::MATCH, 0, -1),
		(`^test[^abc]$`, "test!", matchres::MATCH, 0, -1),
		(`^test[^abc]$`, "testa", matchres::NOMATCH, 0, -1),
		(`^test[^abc]$`, "testb", matchres::NOMATCH, 0, -1),
		(`^test[^abc]$`, "testc", matchres::NOMATCH, 0, -1),
		(`^test[^]abc]$`, "test]", matchres::NOMATCH, 0, -1),
		(`^test[^abc[]$`, "test[", matchres::NOMATCH, 0, -1),
		(`^test[^abc]*$`, "testd", matchres::MATCH, 0, -1),
		(`^test[^abc]*$`, "testqqqqq", matchres::MATCH, 0, -1),
		(`^test[^abc]*$`, "test", matchres::MATCH, 0, -1),
		(`^test[^abc]*$`, "testc", matchres::NOMATCH, 0, -1),
		(`^test[^abc]?$`, "test", matchres::MATCH, 0, -1),
		(`^test[^abc]?$`, "testd", matchres::MATCH, 0, -1),
		(`^test[^abc]?$`, "testc", matchres::NOMATCH, 0, -1),
		(`^test[^abc]+$`, "testd", matchres::MATCH, 0, -1),
		(`^test[^abc]+$`, "testddd", matchres::MATCH, 0, -1),
		(`^test[^abc]+$`, "testc", matchres::NOMATCH, 0, -1),
		(`^test[^abc]+$`, "testcccc", matchres::NOMATCH, 0, -1),
		(`^test[a-c]$`, "testa", matchres::MATCH, 0, -1),
		(`^test[a-c]$`, "testb", matchres::MATCH, 0, -1),
		(`^test[a-c]$`, "testc", matchres::MATCH, 0, -1),
		(`^test[a-c]$`, "testd", matchres::NOMATCH, 0, -1),
		(`^test[a-c]$`, "test!", matchres::NOMATCH, 0, -1),
		(`^test[a-c]$`, "test-", matchres::NOMATCH, 0, -1),
		(`^test[-a-c]$`, "test-", matchres::MATCH, 0, -1),
		(`^test[a-c-]$`, "test-", matchres::MATCH, 0, -1),
		(`^test[a-c]*$`, "test", matchres::MATCH, 0, -1),
		(`^test[a-c]*$`, "testa", matchres::MATCH, 0, -1),
		(`^test[a-c]*$`, "testabb", matchres::MATCH, 0, -1),
		(`^test[a-c]*$`, "testddd", matchres::NOMATCH, 0, -1),
		(`^test[a-c]?$`, "test", matchres::MATCH, 0, -1),
		(`^test[a-c]?$`, "testb", matchres::MATCH, 0, -1),
		(`^test[a-c]?$`, "testd", matchres::NOMATCH, 0, -1),
		(`^test[a-c]+$`, "test", matchres::NOMATCH, 0, -1),
		(`^test[a-c]+$`, "testbcbc", matchres::MATCH, 0, -1),
		(`^test[a-c]+$`, "testd", matchres::NOMATCH, 0, -1),
		(`^test[^a-c]$`, "testa", matchres::NOMATCH, 0, -1),
		(`^test[^a-c]$`, "testb", matchres::NOMATCH, 0, -1),
		(`^test[^a-c]$`, "testc", matchres::NOMATCH, 0, -1),
		(`^test[^a-c]$`, "testd", matchres::MATCH, 0, -1),
		(`^test[^a-c]$`, "test!", matchres::MATCH, 0, -1),
		(`^test[^a-c]$`, "test-", matchres::MATCH, 0, -1),
		(`^test[^-a-c]$`, "test-", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]$`, "test-", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]*$`, "test", matchres::MATCH, 0, -1),
		(`^test[^a-c-]*$`, "test--", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]*$`, "testq", matchres::MATCH, 0, -1),
		(`^test[^a-c-]?$`, "test", matchres::MATCH, 0, -1),
		(`^test[^a-c-]?$`, "testq", matchres::MATCH, 0, -1),
		(`^test[^a-c-]?$`, "test-", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]+$`, "test", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]+$`, "testb", matchres::NOMATCH, 0, -1),
		(`^test[^a-c-]+$`, "testddd", matchres::MATCH, 0, -1),
		(`([a-z][a-z0-9]*,)+`, "a5,b7,c9,", matchres::MATCH, 0, -1),
		// [:alpha:] etc.
		(`^test[[:alnum:]]+$`, "testaA1", matchres::MATCH, 0, -1),
		(`^test[[:alnum:]]+$`, "testa_1", matchres::NOMATCH, 0, -1),
		(`^test[[:alpha:]]+$`, "testa", matchres::MATCH, 0, -1),
		(`^test[[:alpha:]]+$`, "testa1", matchres::NOMATCH, 0, -1),
		(`^test[[:blank:]]+$`, "testa", matchres::NOMATCH, 0, -1),
		(`^test[[:blank:]]+$`, "test ", matchres::MATCH, 0, -1),
		(`^test[^[:blank:]]+$`, "testx", matchres::MATCH, 0, -1),
		(`^test[[:blank:]]+$`, "test ", matchres::MATCH, 0, -1),
		(`^test[^[:cntrl:]]+$`, "testa", matchres::MATCH, 0, -1),
		(`^test[[:digit:]]$`, "test1", matchres::MATCH, 0, -1),
		(`^test[[:digit:]]$`, "testa", matchres::NOMATCH, 0, -1),
		(`^test[[:graph:]]+$`, "test\t", matchres::NOMATCH, 0, -1),
		(`^test[[:lower:]]+$`, "testa", matchres::MATCH, 0, -1),
		(`^test[[:lower:]]+$`, "testA", matchres::NOMATCH, 0, -1),
		(`^test[[:print:]]+$`, "test\t", matchres::NOMATCH, 0, -1),
		(`^test[[:punct:]]+$`, "testA", matchres::NOMATCH, 0, -1),
		(`^test[[:punct:]]+$`, "test!", matchres::MATCH, 0, -1),
		(`^test[[:space:]]+$`, "test ", matchres::MATCH, 0, -1),
		(`^test[[:upper:]]+$`, "testa", matchres::NOMATCH, 0, -1),
		(`^test[[:upper:]]+$`, "testA", matchres::MATCH, 0, -1),
		(`^test[[:word:]]+$`, "test!2", matchres::NOMATCH, 0, -1),
		(`^test[[:word:]]+$`, "test_2", matchres::MATCH, 0, -1),
		(`^test[[:xdigit:]]+$`, "testCAFE", matchres::MATCH, 0, -1),
		// [:alpha:] etc. plus extra characters
		(`^test[[:digit:]][[:alpha:]]$`, "test1a", matchres::MATCH, 0, -1),
		(`^test[[:digit:]][[:alpha:]]$`, "testa1", matchres::NOMATCH, 0, -1),
		(`^test[[:alnum:]!]+$`, "testa!1", matchres::MATCH, 0, -1),
		(`^test[@[:alnum:]!]+$`, "testa!@1", matchres::MATCH, 0, -1),
		// Escaped characters such as \+
		(`^a\+b$`, "a+b", matchres::MATCH, 0, -1),
		(`^a\?b$`, "a?b", matchres::MATCH, 0, -1),
		(`^a\*b$`, "a*b", matchres::MATCH, 0, -1),
		(`^a\^b$`, "a^b", matchres::MATCH, 0, -1),
		(`^a\$b$`, "a$b", matchres::MATCH, 0, -1),
		(`^a\[b$`, "a[b", matchres::MATCH, 0, -1),
		(`^a\]b$`, "a]b", matchres::MATCH, 0, -1),
		(`^a\(b$`, "a(b", matchres::MATCH, 0, -1),
		(`^a\)b$`, "a)b", matchres::MATCH, 0, -1),
		(`^a\|b$`, "a|b", matchres::MATCH, 0, -1),
		(`^a\.b$`, "a.b", matchres::MATCH, 0, -1),
		(`^a\\b$`, "a\\b", matchres::MATCH, 0, -1),
		// {m,n}
		(`^x(abc){1,2}$`, "xabc", matchres::MATCH, 0, -1),
		(`^x(abc){1,2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){1,2}$`, "xabcabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){,2}$`, "xabc", matchres::MATCH, 0, -1),
		(`^x(abc){,2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){,2}$`, "xabcabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){1,}$`, "xabc", matchres::MATCH, 0, -1),
		(`^x(abc){1,}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){3,}$`, "xabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){3,}$`, "xabcabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){2,2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){2,2}$`, "xabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){2,2}$`, "xabcabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){-1,2}$`, "xabcabcabc", matchres::ERROR, 0, -1),
		(`^x(abc){x,2}$`, "xabcabcabc", matchres::ERROR, 0, -1),
		(`^x(abc){0,-2}$`, "xabcabcabc", matchres::ERROR, 0, -1),
		// various
		(
			`^.(1024)?(face)*(1024)*ca*(f+e?cafe)(babe)+$`,
			"X1024facefacecaaaaafffcafebabebabe",
			matchres::MATCH, 0, -1,
		),
		(
			`.(1024)?(face)*(1024)*ca*(f+e?cafe)(babe)+`,
			"X1024facefacecaaaaafffcafebabebabe",
			matchres::MATCH, 0, -1,
		),
		(
			`^.(1024)?(face)*(1024)*ca*(f+e?cafe)(babe)+$`,
			"1024facefacecaaaaafffcafebabebabe",
			matchres::NOMATCH, 0, 0,
		),
		(
			`.(1024)?(face)*(1024)*ca*(f+e?cafe)(babe)+`,
			"1024facefacecaaaaafffcafebabebabe",
			matchres::MATCH, 3, -1,
		),
		(
			`^([a-zA-Z]{1,2}[[:digit:]]{1,2})[[:space:]]*([[:digit:]][a-zA-Z]{2})$`,
			"M15 4QN",
			matchres::MATCH, 0, -1
		),
		// tests from perl
		(`abc`, "abc", matchres::MATCH, 0, -1),
		(`abc`, "xbc", matchres::NOMATCH, 0, 0),
		(`abc`, "axc", matchres::NOMATCH, 0, 0),
		(`abc`, "abx", matchres::NOMATCH, 0, 0),
		(`abc`, "xabcy", matchres::MATCH, 1, 4),
		(`abc`, "ababc", matchres::MATCH, 2, -1),
		(`ab*c`, "abc", matchres::MATCH, 0, -1),
		(`ab*bc`, "abc", matchres::MATCH, 0, -1),
		(`ab*bc`, "abbc", matchres::MATCH, 0, -1),
		(`ab*bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab{0,}bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab+bc`, "abbc", matchres::MATCH, 0, -1),
		(`ab+bc`, "abc", matchres::NOMATCH, 0, 0),
		(`ab+bc`, "abq", matchres::NOMATCH, 0, 0),
		(`ab{1,}bc`, "abq", matchres::NOMATCH, 0, 0),
		(`ab+bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab{1,}bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab{1,3}bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab{3,4}bc`, "abbbbc", matchres::MATCH, 0, -1),
		(`ab{4,5}bc`, "abbbbc", matchres::NOMATCH, 0, 0),
		(`ab?bc`, "abbc", matchres::MATCH, 0, -1),
		(`ab?bc`, "abc", matchres::MATCH, 0, -1),
		(`ab{0,1}bc`, "abc", matchres::MATCH, 0, -1),
		(`ab?bc`, "abbbbc", matchres::NOMATCH, 0, 0),
		(`ab?c`, "abc", matchres::MATCH, 0, -1),
		(`ab{0,1}c`, "abc", matchres::MATCH, 0, -1),
		(`^abc$`, "abc", matchres::MATCH, 0, -1),
		(`^abc$`, "abcc", matchres::NOMATCH, 0, 0),
		(`^abc`, "abcc", matchres::MATCH, 0, 3),
		(`^abc$`, "aabc", matchres::NOMATCH, 0, 0),
		(`abc$`, "aabc", matchres::MATCH, 1, -1),
		(`^`, "abc", matchres::MATCH, 0, 0),
		(`$`, "abc", matchres::MATCH, 3, 3),
		(`a.c`, "abc", matchres::MATCH, 0, -1),
		(`a.c`, "axc", matchres::MATCH, 0, -1),
		(`a.*c`, "axyzc", matchres::MATCH, 0, -1),
		(`a.*c`, "axyzd", matchres::NOMATCH, 0, 0),
		(`a[bc]d`, "abc", matchres::NOMATCH, 0, 0),
		(`a[bc]d`, "abd", matchres::MATCH, 0, -1),
		(`a[b-d]e`, "abd", matchres::NOMATCH, 0, 0),
		(`a[b-d]e`, "ace", matchres::MATCH, 0, -1),
		(`a[b-d]`, "aac", matchres::MATCH, 1, -1),
		(`a[-b]`, "a-", matchres::MATCH, 0, -1),
		(`a[b-]`, "a-", matchres::MATCH, 0, -1),
		(`a[b-a]`, "-", matchres::ERROR, 0, 0),
		(`a[]b`, "-", matchres::ERROR, 0, 0),
		(`a[`, "-", matchres::ERROR, 0, 0),
		(`a]`, "a]", matchres::MATCH, 0, -1),
		(`a[]]b`, "a]b", matchres::MATCH, 0, -1),
		(`a[^bc]d`, "aed", matchres::MATCH, 0, -1),
		(`a[^bc]d`, "abd", matchres::NOMATCH, 0, 0),
		(`a[^-b]c`, "adc", matchres::MATCH, 0, -1),
		(`a[^-b]c`, "a-c", matchres::NOMATCH, 0, 0),
		(`a[^]b]c`, "a]c", matchres::NOMATCH, 0, 0),
		(`a[^]b]c`, "adc", matchres::MATCH, 0, -1),
		(`()ef`, "def", matchres::MATCH, 1, -1),
		(`*a`, "-", matchres::ERROR, 0, 0),
		(`(*)b`, "-", matchres::ERROR, 0, 0),
		(`$b`, "b", matchres::ERROR, 0, 0),
		(`a\`, "-", matchres::ERROR, 0, 0),
		(`a\(b`, "a(b", matchres::MATCH, 0, -1),
		(`a\(*b`, "ab", matchres::MATCH, 0, -1),
		(`a\(*b`, "a((b", matchres::MATCH, 0, -1),
		(`a\\b`, `a\b`, matchres::MATCH, 0, -1),
		(`abc)`, "-", matchres::ERROR, 0, 0),
		(`(abc`, "-", matchres::ERROR, 0, 0),
		(`(a)b(c)`, "abc", matchres::MATCH, 0, -1),
		(`a+b+c`, "aabbabc", matchres::MATCH, 4, -1),
		(`a{1,}b{1,}c`, "aabbabc", matchres::MATCH, 4, -1),
		(`a**`, "-", matchres::ERROR, 0, 0),
		(`)(`, "-", matchres::ERROR, 0, 0),
		(`[^ab]*`, "cde", matchres::MATCH, 0, -1),
		(`abc`, "", matchres::NOMATCH, 0, 0),
		(`a*`, "", matchres::MATCH, 0, -1),
		(`([abc])*d`, "abbbcd", matchres::MATCH, 0, -1),
		(`([abc])*bcd`, "abcd", matchres::MATCH, 0, -1),
		(`abcd*efg`, "abcdefg", matchres::MATCH, 0, -1),
		(`ab*`, "xabyabbbz", matchres::MATCH, 1, 3),
		(`ab*`, "xayabbbz", matchres::MATCH, 1, 2),
		(`(ab|cd)e`, "abcde", matchres::MATCH, 2, -1),
		(`[abhgefdc]ij`, "hij", matchres::MATCH, 0, -1),
		(`^(ab|cd)e`, "abcde", matchres::NOMATCH, 0, 0),
		(`(abc|)ef`, "abcdef", matchres::MATCH, 4, -1),
		(`(a|b)c*d`, "abcd", matchres::MATCH, 1, -1),
		(`(ab|ab*)bc`, "abc", matchres::MATCH, 0, -1),
		(`a([bc]*)c*`, "abc", matchres::MATCH, 0, -1),
		(`a([bc]*)(c*d)`, "abcd", matchres::MATCH, 0, -1),
		(`a([bc]+)(c*d)`, "abcd", matchres::MATCH, 0, -1),
		(`a([bc]*)(c+d)`, "abcd", matchres::MATCH, 0, -1),
		(`a[bcd]*dcdcde`, "adcdcde", matchres::MATCH, 0, -1),
		(`a[bcd]+dcdcde`, "adcdcde", matchres::NOMATCH, 0, 0),
		(`(ab|a)b*c`, "abc", matchres::MATCH, 0, -1),
		(`[a-zA-Z_][a-zA-Z0-9_]*`, "alpha", matchres::MATCH, 0, -1),
		(`^a(bc+|b[eh])g|.h$`, "abh", matchres::MATCH, 0, -1),
		(`multiple words of text`, "uh-uh", matchres::NOMATCH, 0, 0),
		(`multiple words`, "multiple words, yeah", matchres::MATCH, 0, 14),
		(`(.*)c(.*)`, "abcde", matchres::MATCH, 0, -1),
		(`\((.*), (.*)\)`, "(a, b)", matchres::MATCH, 0, -1),
		(`[k]`, "ab", matchres::NOMATCH, 0, 0),
		(`a[-]?c`, "ac", matchres::MATCH, 0, -1),
		(`.*d`, "abc\nabd", matchres::MATCH, 0, -1),
		(`(`, "", matchres::ERROR, 0, 0),
		(`(x?)?`, "x", matchres::MATCH, 0, -1),
		(`^*`, "", matchres::ERROR, 0, 0),
		// Submatch handling
		(`(a|ab)(c|bcd)(d*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(a|ab)(bcd|c)(d*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(ab|a)(c|bcd)(d*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(ab|a)(bcd|c)(d*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(a*)(b|abc)(c*)`, "abc", matchres::MATCH, 0, -1), // POSIX: (0,3)(0,1)(1,2)(2,3)
		(`(a*)(abc|b)(c*)`, "abc", matchres::MATCH, 0, -1), // POSIX: (0,3)(0,1)(1,2)(2,3)
		(`(a*)(b|abc)(c*)`, "abc", matchres::MATCH, 0, -1), // POSIX: (0,3)(0,1)(1,2)(2,3)
		(`(a*)(abc|b)(c*)`, "abc", matchres::MATCH, 0, -1), // POSIX: (0,3)(0,1)(1,2)(2,3)
		(`(a|ab)(c|bcd)(d|.*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(a|ab)(bcd|c)(d|.*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(ab|a)(c|bcd)(d|.*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		(`(ab|a)(bcd|c)(d|.*)`, "abcd", matchres::MATCH, 0, -1), // POSIX: (0,4)(0,2)(2,3)(3,4)
		// TODO: whole-expression alternation
		// (`ab|cd`, "abc", matchres::MATCH, 0, -1),
		// (`ab|cd`, "abcd", matchres::MATCH, 0, -1),
		// TODO: multiple alternation
		// (`a|b|c|d|e`, "e", matchres::MATCH, 0, -1),
		// (`(a|b|c|d|e)f`, "ef", matchres::MATCH, 0, -1),
		// TODO: nested capture groups
		// (`((a))`, "abc", matchres::MATCH, 0, -1),
		// (`((a)(b)c)(d)`, "abcd", matchres::MATCH, 0, -1),
		// (`(bc+d$|ef*g.|h?i(j|k))`, "effgz", matchres::MATCH, 0, -1),
		// (`(bc+d$|ef*g.|h?i(j|k))`, "ij", matchres::MATCH, 0, -1),
		// (`(bc+d$|ef*g.|h?i(j|k))`, "effg", matchres::NOMATCH, 0, 0),
		// (`(bc+d$|ef*g.|h?i(j|k))`, "bcdd", matchres::NOMATCH, 0, 0),
		// (`(bc+d$|ef*g.|h?i(j|k))`, "reffgz", matchres::MATCH, 0, -1),
		// (`((((((((((a))))))))))`, "a", matchres::MATCH, 0, -1),
		// (`(((((((((a)))))))))`, "a", matchres::MATCH, 0, -1),
		// (`(([a-z]+):)?([a-z]+)$`, "smil", matchres::MATCH, 0, -1),
		// (`^((a)c)?(ab)$`, "ab", matchres::MATCH, 0, -1),
		// TODO: multiple simultaneous capture groups
		// (`(a+|b)*`, "ab", matchres::MATCH, 0, -1),
		// (`(a+|b){0,}`, "ab", matchres::MATCH, 0, -1),
		// (`(a+|b)+`, "ab", matchres::MATCH, 0, -1),
		// (`(a+|b){1,}`, "ab", matchres::MATCH, 0, -1),
		// (`(a+|b)?`, "ab", matchres::MATCH, 0, -1),
		// (`(a+|b){0,1}`, "ab", matchres::MATCH, 0, -1),
		// NOTE: character sequences not currently supported
		// (`\0`, "\0", matchres::MATCH, 0, -1),
		// (`[\0a]`, "\0", matchres::MATCH, 0, -1),
		// (`[a\0]`, "\0", matchres::MATCH, 0, -1),
		// (`[^a\0]`, "\0", matchres::NOMATCH, 0, 0),
		// NOTE: octal sequences not currently supported
		// (`[\1]`, "\1", matchres::MATCH, 0, -1),
		// (`\09`, "\0(separate-me)9", matchres::MATCH, 0, -1),
		// (`\141`, "a", matchres::MATCH, 0, -1),
		// (`[\41]`, "!", matchres::MATCH, 0, -1),
		// NOTE: hex sequences not currently supported
		// (`\xff`, "\377", matchres::MATCH, 0, -1),
		// NOTE: non-greedy matching not currently supported
		// (`a.+?c`, "abcabc", matchres::MATCH, 0, -1),
		// (`.*?\S *:`, "xx:", matchres::MATCH, 0, -1),
		// (`a[ ]*?\ (\d+).*`, "a   10", matchres::MATCH, 0, -1),
		// (`a[ ]*?\ (\d+).*`, "a    10", matchres::MATCH, 0, -1),
		// (`"(\\"|[^"])*?"`, `"\""`, matchres::MATCH, 0, -1),
		// (`^.*?$`, "one\ntwo\nthree\n", matchres::NOMATCH, 0, 0),
		// (`a[^>]*?b`, "a>b", matchres::NOMATCH, 0, 0),
		// (`^a*?$`, "foo", matchres::NOMATCH, 0, 0),
		// (`^([ab]*?)(?=(b)?)c`, "abc", matchres::MATCH, 0, -1),
		// (`^([ab]*?)(?!(b))c`, "abc", matchres::MATCH, 0, -1),
		// (`^([ab]*?)(?<!(a))c`, "abc", matchres::MATCH, 0, -1),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const expr = cases[i].0;
		const string = cases[i].1;
		const should_match = cases[i].2;
		const start = cases[i].3;
		const end = if (cases[i].4 == -1) {
			yield len(string): int;
		} else {
			yield cases[i].4;
		};
		run_find_case(expr, string, should_match, start, end);
	};

	if (PERFTEST_ON) {
		const f = os::open("compress/zlib/data+test.ha")!;
		const buf: [2000000]u8 = [0...];
		io::read(f, buf)!;
		const test_data = strings::fromutf8(buf);

		const perf_cases = [
			(
				`^a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*aaaaaaaaaaaaaaaa$`,
				"aaaaaaaaaaaaaaaa",
				matchres::MATCH,
				0, -1
			),
			(`.*.*.*rand_out`, test_data, matchres::MATCH, 0, 1211255),
			(`0x`, test_data, matchres::MATCH, 86, 88),
		];

		for (let i = 0z; i < len(perf_cases); i += 1) {
			const expr = perf_cases[i].0;
			const string = perf_cases[i].1;
			const should_match = perf_cases[i].2;
			const start = perf_cases[i].3;
			const end = if (perf_cases[i].4 == -1) {
				yield len(string): int;
			} else {
				yield perf_cases[i].4;
			};
			run_find_case(expr, string, should_match, start, end);
		};
	};
};

@test fn findall() void = {
	const cases = [
		(`ab.`, "hello abc and abz test abq thanks", matchres::MATCH, 3),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const expr = cases[i].0;
		const string = cases[i].1;
		const should_match = cases[i].2;
		const count = cases[i].3;
		run_findall_case(expr, string, should_match, count);
	};

	if (PERFTEST_ON) {
		const f = os::open("compress/zlib/data+test.ha")!;
		const buf: [2000000]u8 = [0...];
		io::read(f, buf)!;
		const test_data = strings::fromutf8(buf);

		const perf_cases = [
			(`0x`, test_data, matchres::MATCH, 199053),
		];

		for (let i = 0z; i < len(perf_cases); i += 1) {
			const expr = perf_cases[i].0;
			const string = perf_cases[i].1;
			const should_match = perf_cases[i].2;
			const count = perf_cases[i].3;
			run_findall_case(expr, string, should_match, count);
		};
	};
};
