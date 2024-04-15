// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use strings;
use types;

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
			fmt::errorln(e)!;
			fmt::errorfln("Expected expression /{}/ to match string \"{}\", but it errored",
				expr, string)!;
			abort();
		};
		if (expected == matchres::NOMATCH) {
			fmt::errorln(e)!;
			fmt::errorfln("Expected expression /{}/ to not match string \"{}\", but it errored",
				expr, string)!;
			abort();
		};
		return;
	};

	if (expected == matchres::ERROR) {
		fmt::errorfln("Expected expression /{}/ to have error caught during compilation, but it did not",
			expr)!;
		abort();
	};
	defer finish(&re);

	const result = find(&re, string);
	defer result_free(result);
	if (len(result) == 0) {
		if (expected == matchres::MATCH) {
			fmt::errorfln("Expected expression /{}/ to match string \"{}\", but it did not",
				expr, string)!;
			abort();
		};
		return;
	} else if (expected == matchres::NOMATCH) {
		fmt::errorfln("Expected expression /{}/ to not match string \"{}\", but it did",
			expr, string)!;
		abort();
	};

	if (start: size != result[0].start) {
		fmt::errorfln("Expected start of main capture to be {} but it was {}",
			start, result[0].start)!;
		abort();
	};
	if (end: size != result[0].end) {
		fmt::errorfln("Expected end of main capture to be {} but it was {}",
			end, result[0].end)!;
		abort();
	};
};

fn run_submatch_case(
	expr: str,
	string: str,
	expected: matchres,
	targets: []str
) void = {
	const re = compile(expr)!;
	defer finish(&re);

	const result = find(&re, string);
	defer result_free(result);
	assert(len(result) == len(targets), "Invalid number of captures");
	for (let i = 0z; i < len(targets); i += 1) {
		assert(targets[i] == result[i].content, "Invalid capture");
	};
};

fn run_findall_case(
	expr: str,
	string: str,
	expected: matchres,
	targets: []str
) void = {
	const re = match (compile(expr)) {
	case let re: regex => yield re;
	case let e: error =>
		if (expected != matchres::ERROR) {
			fmt::errorln(e)!;
			fmt::errorfln("Expected expression /{}/ to compile, but it errored",
				expr)!;
			abort();
		};
		return;
	};
	defer finish(&re);

	if (expected == matchres::ERROR) {
		fmt::errorfln("Expected expression /{}/ to have error caught during compilation, but it did not",
			expr)!;
		abort();
	};

	const results = findall(&re, string);
	if (len(results) == 0 && expected == matchres::MATCH) {
		fmt::errorfln("Expected expression /{}/ to match string \"{}\", but it did not",
			expr, string)!;
		abort();
	};
	defer result_freeall(results);

	if (expected == matchres::NOMATCH) {
		fmt::errorfln("Expected expression /{}/ to not match string \"{}\", but it did",
			expr, string)!;
		abort();
	};
	if (len(targets) != len(results)) {
		fmt::errorfln("Expected expression /{}/ to find {} results but found {}",
			expr, len(targets), len(results))!;
		abort();
	};
	for (let i = 0z; i < len(results); i += 1) {
		if (results[i][0].content != targets[i]) {
			fmt::errorfln("Expected submatch of expression /{}/ to be {} but it was {}",
				expr, targets[i], results[i][0].content)!;
			abort();
		};
	};
};

fn run_replace_case(
	expr: str,
	string: str,
	target: str,
	n: size,
	expected: (str | void),
) void = {
	const re = match (compile(expr)) {
	case let re: regex => yield re;
	case let e: error =>
		fmt::errorln(e)!;
		fmt::errorfln("Expected expression /{}/ to compile, but it errored",
			expr)!;
		abort();
	};
	defer finish(&re);

	match (replacen(&re, string, target, n)) {
	case let e: error =>
		if (expected is str) {
			fmt::errorln(e)!;
			fmt::errorfln("expr=/{}/ string=\"{}\" target=\"{}\" n={} expected=\"{}\"",
				expr, string, target, n, expected as str)!;
			abort();
		};
	case let s: str =>
		defer free(s);
		if (expected is void) {
			fmt::errorln("Expected replace to fail, but it did not")!;
			fmt::errorfln("expr=/{}/ string=\"{}\" target=\"{}\" n={} return=\"{}\"",
				expr, string, target, n, s)!;
			abort();
		};
		if (expected as str != s) {
			fmt::errorfln("expr=/{}/ string=\"{}\" target=\"{}\" n={} expected=\"{}\" return=\"{}\"",
				expr, string, target, n, expected as str, s)!;
			abort();
		};
	};
};

fn run_rawreplace_case(
	expr: str,
	string: str,
	target: str,
	n: size,
	expected: str,
) void = {
	const re = match (compile(expr)) {
	case let re: regex => yield re;
	case let e: error =>
		fmt::errorln(e)!;
		fmt::errorfln("Expected expression /{}/ to compile, but it errored",
			expr)!;
		abort();
	};
	defer finish(&re);

	const s = rawreplacen(&re, string, target, n);
	defer free(s);
	if (expected != s) {
		fmt::errorfln("expr=/{}/ string=\"{}\" target=\"{}\" n={} expected=\"{}\" return=\"{}\"",
			expr, string, target, n, expected, s)!;
		abort();
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
		(`^test[[:xdigit:]]+$`, "testCAFE", matchres::MATCH, 0, -1),
		// range expressions
		(`[a-z]+`, "onlylatinletters", matchres::MATCH, 0, -1),
		(`[x-z]+`, "xyz", matchres::MATCH, 0, -1),
		(`[x-z]+`, "wxyz", matchres::MATCH, 1, 4),
		(`[a-e]+`, "-abcdefg", matchres::MATCH, 1, 6),
		(`[a-z]`, "-1234567890@#$%^&*(!)-+=", matchres::NOMATCH, 0, -1),
		(`[0-9]+`, "9246", matchres::MATCH, 0, -1),
		// # Cyrillic
		(`[а-я]+`, "кирилица", matchres::MATCH, 0, -1),
		(`[а-д]`, "е", matchres::NOMATCH, 0, -1),
		(`[я-ф]`, "-", matchres::ERROR, 0, -1),
		(`[А-Я]+`, "АБВГд", matchres::MATCH, 0, 4),
		// because Macedonian uses cyrrilics, the broad range does
		// not include special symbols
		(`[а-ш]+`, "ѓљњќ", matchres::NOMATCH, 0, -1),
		// # Polish Alphabet
		(`[a-ż]+`, "polskialfabet", matchres::MATCH, 0, -1),
		(`[a-ż]+`, "źśółęćą", matchres::MATCH, 0, -1),
		// because Polish alphabet uses Latin with special characters,
		// other characters can be accepted
		(`[a-ż]+`, "englishspeak", matchres::MATCH, 0, -1),
		(`[a-ż]+`, "{|}~", matchres::MATCH, 0, -1),
		// # Thai Alphabet
		(`[ก-ฮ]+`, "ศอผจข", matchres::MATCH, 0, -1),
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
		(`^x(abc)\{,2\}$`, "xabc{,2}", matchres::MATCH, 0, -1),
		(`^x(abc)\{,2\}$`, "xabcabc{,2}", matchres::NOMATCH, 0, -1),
		(`^[\\]+$`, "\\", matchres::MATCH, 0, -1),
		(`^[\]]+$`, "]", matchres::MATCH, 0, -1),
		(`^[A-Za-z\[\]]+$`, "foo[bar]baz", matchres::MATCH, 0, -1),
		// {m,n}
		(`^x(abc){2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){3}$`, "xabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){1,2}$`, "xabc", matchres::MATCH, 0, -1),
		(`^x(abc){1,2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){1,2}$`, "xabcabcabc", matchres::NOMATCH, 0, -1),
		(`^x(abc){,2}$`, "xabc", matchres::MATCH, 0, -1),
		(`^x(abc){,2}$`, "xabcabc", matchres::MATCH, 0, -1),
		(`^x(abc){,2}`, "xabcabcabc", matchres::MATCH, 0, 7),
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
		(`^[^-a]`, "-bcd", matchres::NOMATCH, 0, 0),
		(`^[-a]`, "-bcd", matchres::MATCH, 0, 1),
		(`[^ac-]`, "bde", matchres::MATCH, 0, 1),
		(`[-ac]`, "foo-de", matchres::MATCH, 3, 4),
		(`[-ac]`, "def", matchres::NOMATCH, 0, 0),
		(`foo[-ac]bar`, "foo-bar", matchres::MATCH, 0, 7),
		(`[ac-]$`, "bde-", matchres::MATCH, 3, 4),
		(`^[A-Za-z_-]+$`, "foo", matchres::MATCH, 0, 3),
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
		// whole-expression alternation
		(`ab|cd`, "cd", matchres::MATCH, 0, 2),
		(`ab|cd`, "abc", matchres::MATCH, 0, 2),
		(`ab|cd`, "abcd", matchres::MATCH, 0, 2),
		// multiple alternation
		(`a|b|c|d|e`, "e", matchres::MATCH, 0, -1),
		(`(a|b|c|d|e)f`, "ef", matchres::MATCH, 0, -1),
		// TODO: nested capture groups
		(`((a))`, "abc", matchres::ERROR, 0, -1),
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

	for (let (expr, string, should_match, start, end) .. cases) {
		if (end == -1) {
			// workaround to get the length in codepoints
			let runes = strings::torunes(string);
			defer free(runes);
			end = len(runes): int;
		};
		run_find_case(expr, string, should_match, start, end);
	};

	const submatch_cases = [
		// literals
		(`aaa ([^ ]*) (...)`, "aaa bbb ccc", matchres::MATCH,
			["aaa bbb ccc", "bbb", "ccc"]: []str),
	];

	for (let (expr, string, should_match, targets) .. submatch_cases) {
		run_submatch_case(expr, string, should_match, targets);
	};
};

@test fn findall() void = {
	const cases = [
		(`ab.`, "hello abc and abあ test abq thanks", matchres::MATCH,
			["abc", "abあ", "abq"]: []str),
		(`a`, "aa", matchres::MATCH,
			["a", "a"]: []str),
		(`fo{2,}`, "fo foo fooofoof oofoo", matchres::MATCH,
			["foo", "fooo", "foo", "foo"]: []str),
		(``, "abc", matchres::MATCH,
			["", "", "", ""]: []str),
		(`a*`, "aaa", matchres::MATCH,
			["aaa", ""]: []str),
	];

	for (let (expr, string, should_match, targets) .. cases) {
		run_findall_case(expr, string, should_match, targets);
	};
};

@test fn replace() void = {
	const cases: [_](str, str, str, size, (str | void)) = [
		(`ab.`, "hello abc and abあ test abq thanks", `xyz`,
			types::SIZE_MAX, "hello xyz and xyz test xyz thanks"),
		(`([Hh])ello`, "Hello world and hello Hare.", `\1owdy`,
			types::SIZE_MAX, "Howdy world and howdy Hare."),
		(`fo{2,}`, "fo foo fooofoof oofoo", `\0bar`,
			types::SIZE_MAX, "fo foobar fooobarfoobarf oofoobar"),
		(`(1)(2)(3)(4)(5)(6)(7)(8)(9)(10)`, "12345678910", `\10`,
			types::SIZE_MAX, "10"),
		(`...?`, "abcdefgh", `\7\0\8`,
			types::SIZE_MAX, "abcdefgh"),
		(`...?`, "abcdefgh", `\7\0\`, types::SIZE_MAX, void),
		(`ab.`, "hello abc and abあ test abq thanks", `xyz`,
			2, "hello xyz and xyz test abq thanks"),
		(`.`, "blablabla", `x`, 0, "blablabla"),
		(`([[:digit:]])([[:digit:]])`, "1234", `\2`, 1, "234"),
	];

	for (let (expr, string, target, n, expected) .. cases) {
		run_replace_case(expr, string, target, n, expected);
	};
};

@test fn rawreplace() void = {
	const cases = [
		(`ab.`, "hello abc and abあ test abq thanks", "xyz",
			types::SIZE_MAX, "hello xyz and xyz test xyz thanks"),
		(`([Hh])ello`, "Hello world and hello Hare.", `\howdy\`,
			types::SIZE_MAX, `\howdy\ world and \howdy\ Hare.`),
		(`fo{2,}`, "fo foo fooofoof oofoo", `\0bar`,
			types::SIZE_MAX, `fo \0bar \0bar\0barf oo\0bar`),
		(`\\\\`, `\\\\\\\\`, `\00\1`,
			types::SIZE_MAX, `\00\1\00\1\00\1\00\1`),
		(`ab.`, "hello abc and abあ test abq thanks", `xyz`,
			2, "hello xyz and xyz test abq thanks"),
		(`.`, "blablabla", `x`, 0, "blablabla"),
	];

	for (let (expr, string, target, n, expected) .. cases) {
		run_rawreplace_case(expr, string, target, n, expected);
	};
};
