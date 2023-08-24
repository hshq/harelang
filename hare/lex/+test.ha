// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Sudipto Mallick <smlckz@disroot.org>
use fmt;
use io;
use io::{mode};
use memio;
use strings;

@test fn unget() void = {
	let buf = memio::fixed(strings::toutf8("z"));
	let lexer = init(&buf, "<test>");
	unget(&lexer, ('x', location { path = "<test>", line = 1, col = 2 }));
	unget(&lexer, ('y', location { path = "<test>", line = 1, col = 3 }));
	let r = next(&lexer) as (rune, location);
	assert(r.0 == 'y');
	assert(r.1.path == "<test>" && r.1.line == 1 && r.1.col == 3);
	r = next(&lexer) as (rune, location);
	assert(r.0 == 'x');
	assert(r.1.path == "<test>" && r.1.line == 1 && r.1.col == 2);
	r = next(&lexer) as (rune, location);
	assert(r.0 == 'z');
	assert(r.1.path == "<test>" && r.1.line == 1 && r.1.col == 1);
	assert(next(&lexer) is io::EOF);
	unget(&lexer, io::EOF);
	assert(next(&lexer) is io::EOF);
};

@test fn unlex() void = {
	let lexer = init(io::empty, "<test>");
	unlex(&lexer, (ltok::IF, void, location {
		path = "<test>",
		line = 1234,
		col = 1234,
	}));
	let t = lex(&lexer) as token;
	assert(t.0 == ltok::IF);
	assert(t.1 is void);
	assert(t.2.path == "<test>");
	assert(t.2.line == 1234 && t.2.col == 1234);
};

fn vassert(expected: value, actual: value) void = {
	match (expected) {
	case let expected: str =>
		assert(actual as str == expected);
	case let expected: rune =>
		assert(actual as rune == expected);
	case let expected: u64 =>
		assert(actual as u64 == expected);
	case let expected: f64 =>
		assert(actual as f64 == expected);
	case void =>
		assert(actual is void);
	};
};

fn lextest(in: str, expected: []token) void = {
	let buf = memio::fixed(strings::toutf8(in));
	let lexer = init(&buf, "<test>");
	for (let i = 0z; i < len(expected); i += 1) {
		let etok = expected[i];
		let tl = match (lex(&lexer)) {
		case let tl: token =>
			yield tl;
		case let err: error =>
			fmt::errorfln("{}: {}", i, strerror(err))!;
			abort();
		};
		if (tl.0 != etok.0) {
			fmt::errorfln("Expected {}, got {}",
				tokstr(etok), tokstr(tl))!;
		};
		assert(tl.0 == etok.0);
		vassert(tl.1, etok.1);
		if (tl.2.line != etok.2.line || tl.2.col != etok.2.col
				|| tl.2.path != etok.2.path) {
			fmt::errorfln("{}:{}:{} != {}:{}:{}",
				tl.2.path, tl.2.line, tl.2.col,
				etok.2.path, etok.2.line, etok.2.col)!;
			abort();
		};
	};
	let t = lex(&lexer) as token;
	assert(t.0 == ltok::EOF);
};

fn loc(line: uint, col: uint) location = location {
	path = "<test>",
	line = line,
	col = col,
};

@test fn lex1() void = {
	const in = "~,{[(}]);";
	const expected: [_]token = [
		(ltok::BNOT, void, loc(1, 1)),
		(ltok::COMMA, void, loc(1, 2)),
		(ltok::LBRACE, void, loc(1, 3)),
		(ltok::LBRACKET, void, loc(1, 4)),
		(ltok::LPAREN, void, loc(1, 5)),
		(ltok::RBRACE, void, loc(1, 6)),
		(ltok::RBRACKET, void, loc(1, 7)),
		(ltok::RPAREN, void, loc(1, 8)),
		(ltok::SEMICOLON, void, loc(1, 9)),
	];
	lextest(in, expected);
};

@test fn lex2() void = {
	// Ends with = to test =, EOF
	const in = "* *= % %= + += - -= : :: = == / /= =";
	const expected: [_]token = [
		(ltok::TIMES, void, loc(1, 1)),
		(ltok::TIMESEQ, void, loc(1, 3)),
		(ltok::MODULO, void, loc(1, 6)),
		(ltok::MODEQ, void, loc(1, 8)),
		(ltok::PLUS, void, loc(1, 11)),
		(ltok::PLUSEQ, void, loc(1, 13)),
		(ltok::MINUS, void, loc(1, 16)),
		(ltok::MINUSEQ, void, loc(1, 18)),
		(ltok::COLON, void, loc(1, 21)),
		(ltok::DOUBLE_COLON, void, loc(1, 23)),
		(ltok::EQUAL, void, loc(1, 26)),
		(ltok::LEQUAL, void, loc(1, 28)),
		(ltok::DIV, void, loc(1, 31)),
		(ltok::DIVEQ, void, loc(1, 33)),
		(ltok::EQUAL, void, loc(1, 36)),
	];
	lextest(in, expected);
};

@test fn lex3() void = {
	const in = ". .. ... < << <= <<= > >> >= >>= >>";
	const expected: [_]token = [
		(ltok::DOT, void, loc(1, 1)),
		(ltok::SLICE, void, loc(1, 3)),
		(ltok::ELLIPSIS, void, loc(1, 6)),
		(ltok::LESS, void, loc(1, 10)),
		(ltok::LSHIFT, void, loc(1, 12)),
		(ltok::LESSEQ, void, loc(1, 15)),
		(ltok::LSHIFTEQ, void, loc(1, 18)),
		(ltok::GT, void, loc(1, 22)),
		(ltok::RSHIFT, void, loc(1, 24)),
		(ltok::GTEQ, void, loc(1, 27)),
		(ltok::RSHIFTEQ, void, loc(1, 30)),
		(ltok::RSHIFT, void, loc(1, 34)),
	];
	lextest(in, expected);

	const in = "& && &= &&= | || |= ||= ^ ^^ ^= ^^= ^";
	const expected: [_]token = [
		(ltok::BAND, void, loc(1, 1)),
		(ltok::LAND, void, loc(1, 3)),
		(ltok::BANDEQ, void, loc(1, 6)),
		(ltok::LANDEQ, void, loc(1, 9)),
		(ltok::BOR, void, loc(1, 13)),
		(ltok::LOR, void, loc(1, 15)),
		(ltok::BOREQ, void, loc(1, 18)),
		(ltok::LOREQ, void, loc(1, 21)),
		(ltok::BXOR, void, loc(1, 25)),
		(ltok::LXOR, void, loc(1, 27)),
		(ltok::BXOREQ, void, loc(1, 30)),
		(ltok::LXOREQ, void, loc(1, 33)),
		(ltok::BXOR, void, loc(1, 37)),
	];
	lextest(in, expected);
};

@test fn lexname() void = {
	const in = "hello world return void foobar :foobaz";
	const expected: [_]token = [
		(ltok::NAME, "hello", loc(1, 1)),
		(ltok::NAME, "world", loc(1, 7)),
		(ltok::RETURN, void, loc(1, 13)),
		(ltok::VOID, void, loc(1, 20)),
		(ltok::NAME, "foobar", loc(1, 25)),
		(ltok::COLON, void, loc(1, 32)),
		(ltok::NAME, "foobaz", loc(1, 33)),
	];
	lextest(in, expected);
};

@test fn keywords() void = {
	let keywords = bmap[..ltok::LAST_KEYWORD+1];
	for (let i = 0z; i < len(keywords); i += 1) {
		let buf = memio::fixed(strings::toutf8(keywords[i]));
		let lexer = init(&buf, "<test>");
		let tok = lex(&lexer) as token;
		assert(tok.0 == i: ltok);
	};
};

@test fn comments() void = {
	const in = "hello world // foo\nbar";
	const expected: [_]token = [
		(ltok::NAME, "hello", loc(1, 1)),
		(ltok::NAME, "world", loc(1, 7)),
		(ltok::NAME, "bar", loc(2, 1)),
	];
	lextest(in, expected);

	let in = "// foo\n// bar\nhello world// baz\n\n// bad\ntest";
	let buf = memio::fixed(strings::toutf8(in));
	let lexer = init(&buf, "<input>", flag::COMMENTS);
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == " foo\n bar\n");
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == " baz\n");
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == " bad\n");
};

@test fn runes() void = {
	const in = "'a' 'b' '\\a' '\\b' '\\f' '\\n' '\\r' '\\t' '\\v' '\\0' "
		"'\\\\' '\\\'' '\\x0A' '\\u1234' '\\U12345678'";
	const expected: [_]token = [
		(ltok::LIT_RCONST, 'a', loc(1, 1)),
		(ltok::LIT_RCONST, 'b', loc(1, 5)),
		(ltok::LIT_RCONST, '\a', loc(1, 9)),
		(ltok::LIT_RCONST, '\b', loc(1, 14)),
		(ltok::LIT_RCONST, '\f', loc(1, 19)),
		(ltok::LIT_RCONST, '\n', loc(1, 24)),
		(ltok::LIT_RCONST, '\r', loc(1, 29)),
		(ltok::LIT_RCONST, '\t', loc(1, 34)),
		(ltok::LIT_RCONST, '\v', loc(1, 39)),
		(ltok::LIT_RCONST, '\0', loc(1, 44)),
		(ltok::LIT_RCONST, '\\', loc(1, 49)),
		(ltok::LIT_RCONST, '\'', loc(1, 54)),
		(ltok::LIT_RCONST, '\x0A', loc(1, 59)),
		(ltok::LIT_RCONST, '\u1234', loc(1, 66)),
		(ltok::LIT_RCONST, '\U12345678', loc(1, 75)),
	];
	lextest(in, expected);
};

@test fn strings() void = {
	const in = `"a" "b" "\a" "\b" "\f" "\n" "\r" "\t" "\v" "\0" "\\" "\'"`;
	const expected: [_]token = [
		(ltok::LIT_STR, "ab\a\b\f\n\r\t\v\0\\\'", loc(1, 1)),
	];
	// TODO: test \x and \u and \U
	lextest(in, expected);
	const in = `"ab\a\b\f\n\r\t\v\0\\\'"`;
	const expected: [_]token = [
		(ltok::LIT_STR, "ab\a\b\f\n\r\t\v\0\\\'", loc(1, 1)),
	];
	lextest(in, expected);
	const in = `"hello world", "こんにちは", "return", "foo"`;
	const expected: [_]token = [
		(ltok::LIT_STR, "hello world", loc(1, 1)),
		(ltok::COMMA, void, loc(1, 14)),
		(ltok::LIT_STR, "こんにちは", loc(1, 16)),
		(ltok::COMMA, void, loc(1, 23)),
		(ltok::LIT_STR, "return", loc(1, 25)),
		(ltok::COMMA, void, loc(1, 33)),
		(ltok::LIT_STR, "foo", loc(1, 35)),
	];
	lextest(in, expected);
	const in = "\"foo\"\n"
		"// bar\n"
		"\"baz\"";
	const expected: [_]token = [
		(ltok::LIT_STR, "foobaz", loc(1, 1)),
	];
	lextest(in, expected);
};

@test fn literals() void = {
	const in = "1e5 -1i32 9223372036854775809 1e2z 255u8 0o42u16\n"
		"0b1000101u32 0xDEADBEEFu64 -0b10i8 -5e0i16 -0o16i32\n"
		"0b00000010000001100000011100001111000000100000011000000111i64\n"
		"13.37 13.37f32 13.37f64 6.022e23 1.616255e-35f64 1e-1";
	const expected: [_]token = [
		(ltok::LIT_ICONST, 1e5u64, loc(1, 1)),
		(ltok::MINUS, void, loc(1, 5)),
		(ltok::LIT_I32, 1u64, loc(1, 6)),
		(ltok::LIT_ICONST, 9223372036854775809u64, loc(1, 11)),
		(ltok::LIT_SIZE, 1e2u64, loc(1, 31)),
		(ltok::LIT_U8, 255u64, loc(1, 36)),
		(ltok::LIT_U16, 0o42u64, loc(1, 42)),
		(ltok::LIT_U32, 0b1000101u64, loc(2, 1)),
		(ltok::LIT_U64, 0xDEADBEEFu64, loc(2, 14)),
		(ltok::MINUS, void, loc(2, 28)),
		(ltok::LIT_I8, 0b10u64, loc(2, 29)),
		(ltok::MINUS, void, loc(2, 36)),
		(ltok::LIT_I16, 5e0u64, loc(2, 37)),
		(ltok::MINUS, void, loc(2, 44)),
		(ltok::LIT_I32, 0o16u64, loc(2, 45)),
		(ltok::LIT_I64, 0b00000010000001100000011100001111000000100000011000000111u64, loc(3, 1)),
		(ltok::LIT_FCONST, 13.37, loc(4, 1)),
		(ltok::LIT_F32, 13.37, loc(4, 7)),
		(ltok::LIT_F64, 13.37, loc(4, 16)),
		(ltok::LIT_FCONST, 6.022e23, loc(4, 25)),
		(ltok::LIT_F64, 1.616255e-35, loc(4, 34)),
		(ltok::LIT_FCONST, 1e-1, loc(4, 50)),
	];
	lextest(in, expected);
};

@test fn invalid() void = {
	// Using \x80 within a string literal will cause this to output an
	// empty string
	const in = ['1': u8, 0x80];

	let buf = memio::fixed(in);
	let lexer = init(&buf, "<test>");

	const s = lex(&lexer) as error as syntax;
	assert(s.1 == "Source file is not valid UTF-8");

	// Regression: invalid UTF-8 at the beginning of a token used to cause
	// a crash in nextw
	const in = [0x80: u8];

	let buf = memio::fixed(in);
	let lexer = init(&buf, "<test>");

	const s = lex(&lexer) as error as syntax;
	assert(s.1 == "Source file is not valid UTF-8");

	// Regression: invalid escape sequences such as "\^" used to casue a
	// crash
	const in = ['"': u8, '\\': u8, '^': u8, '"': u8];

	let buf = memio::fixed(in);
	let lexer = init(&buf, "<test>");

	const s = lex(&lexer) as error as syntax;
	assert(s.1 == "unknown escape sequence");

	// Regression: <X>e followed by another token used to cause a crash
	const in = ['0': u8, 'e': u8, ')': u8];

	let buf = memio::fixed(in);
	let lexer = init(&buf, "<test>");

	const s = lex(&lexer) as error as syntax;
	assert(s.1 == "expected exponent");
};


// Small virtual machine for testing mkloc/prevloc.
// NEXT, UNGET, LEX, and UNLEX call the obvious functions (with UNGET and UNLEX
// pulling from a buffer that NEXT/LEX feed into).
// After each instruction, the results of mkloc/prevloc are checked against the
// next element of the test vector.
type op = enum {
	LEX,
	NEXT,
	UNGET,
	UNLEX,
};

@test fn loc() void = {
	const src = "h 	ello: my	name is Inigo Montoya";
	let buf = memio::fixed(strings::toutf8(src));
	let lexer = init(&buf, "<test>");
	const ops: [_]op = [
		op::NEXT,
		op::NEXT,
		op::NEXT,
		op::UNGET,
		op::UNGET,
		op::NEXT,
		op::NEXT,
		op::LEX,
		op::LEX,
		op::UNLEX,
		op::LEX,
		op::LEX,
		op::UNLEX,
		op::LEX,
		op::LEX,
		op::LEX,
		op::LEX,
	];
	const vector: [_](location, location) = [
		(loc(1, 2), loc(1, 1)),
		(loc(1, 3), loc(1, 2)),
		(loc(1, 9), loc(1, 3)),
		(loc(1, 3), loc(1, 2)),
		(loc(1, 2), loc(1, 1)),
		(loc(1, 3), loc(1, 2)),
		(loc(1, 9), loc(1, 3)),
		(loc(1, 13), loc(1, 12)),
		(loc(1, 14), loc(1, 13)),
		(loc(1, 13), loc(1, 12)),
		(loc(1, 14), loc(1, 13)),
		(loc(1, 17), loc(1, 16)),
		(loc(1, 14), loc(1, 13)),
		(loc(1, 17), loc(1, 16)),
		(loc(1, 29), loc(1, 28)),
		(loc(1, 32), loc(1, 31)),
		(loc(1, 38), loc(1, 37)),
	];

	// We could statically allocate r and t, but what's the point
	let r: [](rune, location) = [];
	defer free(r);
	let t: []token = [];
	defer free(t);
	for (let i = 0z; i < len(ops); i += 1) {
		switch (ops[i]) {
		case op::LEX =>
			append(t, lex(&lexer)!);
		case op::NEXT =>
			append(r, next(&lexer) as (rune, location));
		case op::UNGET =>
			unget(&lexer, r[len(r) - 1]);
			delete(r[len(r) - 1]);
		case op::UNLEX =>
			unlex(&lexer, t[len(t) - 1]);
			delete(t[len(t) - 1]);
		};
		let loc = mkloc(&lexer);
		let ploc = prevloc(&lexer);
		// TODO: Aggregate equality
		assert(loc.path == vector[i].0.path
			&& loc.line == vector[i].0.line
			&& loc.col == vector[i].0.col);
		assert(ploc.path == vector[i].1.path
			&& ploc.line == vector[i].1.line
			&& ploc.col == vector[i].1.col);
	};
};

@test fn access_tuple() void = {
	const in = "((0, 1), 2).0.1";
	const expected: []token = [
		(ltok::LPAREN, void, loc(1, 1)),
		(ltok::LPAREN, void, loc(1, 2)),
		(ltok::LIT_ICONST, 0, loc(1, 3)),
		(ltok::COMMA, void, loc(1, 4)),
		(ltok::LIT_ICONST, 1, loc(1, 6)),
		(ltok::RPAREN, void, loc(1, 7)),
		(ltok::COMMA, void, loc(1, 8)),
		(ltok::LIT_ICONST, 2, loc(1, 10)),
		(ltok::RPAREN, void, loc(1, 11)),
		(ltok::DOT, void, loc(1, 12)),
		(ltok::LIT_ICONST, 0, loc(1, 13)),
		(ltok::DOT, void, loc(1, 14)),
		(ltok::LIT_ICONST, 1, loc(1, 15)),
	];
	lextest(in, expected);
};
