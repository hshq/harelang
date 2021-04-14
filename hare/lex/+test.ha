use bufio;
use fmt;
use io;
use io::{mode};
use strings;

@test fn unget() void = {
	let buf = bufio::fixed(strings::toutf8("z"), mode::READ);
	defer io::close(buf);
	let lexer = init(buf, "<test>");
	unget(&lexer, 'x');
	unget(&lexer, 'y');
	assert(next(&lexer) as rune == 'y');
	assert(next(&lexer) as rune == 'x');
	assert(next(&lexer) as rune == 'z');
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

fn vassert(expected: value, actual: value) void = match (expected) {
	expected: str => assert(actual as str == expected),
	expected: rune => assert(actual as rune == expected),
	expected: i64 => assert(actual as i64 == expected),
	expected: u64 => assert(actual as u64 == expected),
	expected: f64 => assert(actual as f64 == expected),
	void => assert(actual is void),
};

fn lextest(in: str, expected: []token) void = {
	let buf = bufio::fixed(strings::toutf8(in), mode::READ);
	defer io::close(buf);
	let lexer = init(buf, "<test>");
	for (let i = 0z; i < len(expected); i += 1) {
		let etok = expected[i];
		let tl = match (lex(&lexer)) {
			tl: token => tl,
			err: error => {
				fmt::errorfln("{}: {}", i, strerror(err));
				abort();
			},
		};
		assert(tl.0 == etok.0);
		vassert(tl.1, etok.1);
		assert(tl.2.line == etok.2.line && tl.2.col == etok.2.col
			&& tl.2.path == etok.2.path);
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
	const in = "^ ^^ ^= * *= % %= + += - -= : :: & && &= | || |= = == / /= =";
	const expected: [_]token = [
		(ltok::BXOR, void, loc(1, 1)),
		(ltok::LXOR, void, loc(1, 3)),
		(ltok::BXOREQ, void, loc(1, 6)),
		(ltok::TIMES, void, loc(1, 9)),
		(ltok::TIMESEQ, void, loc(1, 11)),
		(ltok::MODULO, void, loc(1, 14)),
		(ltok::MODEQ, void, loc(1, 16)),
		(ltok::PLUS, void, loc(1, 19)),
		(ltok::PLUSEQ, void, loc(1, 21)),
		(ltok::MINUS, void, loc(1, 24)),
		(ltok::MINUSEQ, void, loc(1, 26)),
		(ltok::COLON, void, loc(1, 29)),
		(ltok::DOUBLE_COLON, void, loc(1, 31)),
		(ltok::BAND, void, loc(1, 34)),
		(ltok::LAND, void, loc(1, 36)),
		(ltok::ANDEQ, void, loc(1, 39)),
		(ltok::BOR, void, loc(1, 42)),
		(ltok::LOR, void, loc(1, 44)),
		(ltok::OREQ, void, loc(1, 47)),
		(ltok::EQUAL, void, loc(1, 50)),
		(ltok::LEQUAL, void, loc(1, 52)),
		(ltok::DIV, void, loc(1, 55)),
		(ltok::DIVEQ, void, loc(1, 57)),
		(ltok::EQUAL, void, loc(1, 60)),
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
		(ltok::GREATER, void, loc(1, 22)),
		(ltok::RSHIFT, void, loc(1, 24)),
		(ltok::GREATEREQ, void, loc(1, 27)),
		(ltok::RSHIFTEQ, void, loc(1, 30)),
		(ltok::RSHIFT, void, loc(1, 34)),
	];
	lextest(in, expected);
};

@test fn lexname() void = {
	const in = "hello world return void foobar";
	const expected: [_]token = [
		(ltok::NAME, "hello", loc(1, 1)),
		(ltok::NAME, "world", loc(1, 7)),
		(ltok::RETURN, void, loc(1, 13)),
		(ltok::VOID, void, loc(1, 20)),
		(ltok::NAME, "foobar", loc(1, 25)),
	];
	lextest(in, expected);
};

@test fn keywords() void = {
	let keywords = bmap[..ltok::LAST_KEYWORD+1];
	for (let i = 0z; i < len(keywords); i += 1) {
		let buf = bufio::fixed(strings::toutf8(keywords[i]), mode::READ);
		defer io::close(buf);
		let lexer = init(buf, "<test>");
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
	let buf = bufio::fixed(strings::toutf8(in), mode::READ);
	defer io::close(buf);
	let lexer = init(buf, "<input>", flags::COMMENTS);
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == " foo\n bar\n");
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == "");
	assert(lex(&lexer) is token);
	assert(comment(&lexer) == " bad\n");
};

@test fn runes() void = {
	const in = "'a' 'b' '\\a' '\\b' '\\f' '\\n' '\\r' '\\t' '\\v' '\\0' "
		"'\\\\' '\\\'' '\\x0A' '\\u1234' '\\U12345678'";
	const expected: [_]token = [
		(ltok::LIT_RUNE, 'a', loc(1, 1)),
		(ltok::LIT_RUNE, 'b', loc(1, 5)),
		(ltok::LIT_RUNE, '\a', loc(1, 9)),
		(ltok::LIT_RUNE, '\b', loc(1, 14)),
		(ltok::LIT_RUNE, '\f', loc(1, 19)),
		(ltok::LIT_RUNE, '\n', loc(1, 24)),
		(ltok::LIT_RUNE, '\r', loc(1, 29)),
		(ltok::LIT_RUNE, '\t', loc(1, 34)),
		(ltok::LIT_RUNE, '\v', loc(1, 39)),
		(ltok::LIT_RUNE, '\0', loc(1, 44)),
		(ltok::LIT_RUNE, '\\', loc(1, 49)),
		(ltok::LIT_RUNE, '\'', loc(1, 54)),
		(ltok::LIT_RUNE, '\x0A', loc(1, 59)),
		(ltok::LIT_RUNE, '\u1234', loc(1, 66)),
		(ltok::LIT_RUNE, '\U12345678', loc(1, 75)),
	];
	lextest(in, expected);
};

@test fn strings() void = {
	const in = "\"a\" \"b\" \"\\a\" \"\\b\" \"\\f\" \"\\n\" \"\\r\" "
		"\"\\t\" \"\\v\" \"\\0\" \"\\\\\" \"\\\'\"";
	const expected: [_]token = [
		(ltok::LIT_STR, "a", loc(1, 1)),
		(ltok::LIT_STR, "b", loc(1, 5)),
		(ltok::LIT_STR, "\a", loc(1, 9)),
		(ltok::LIT_STR, "\b", loc(1, 14)),
		(ltok::LIT_STR, "\f", loc(1, 19)),
		(ltok::LIT_STR, "\n", loc(1, 24)),
		(ltok::LIT_STR, "\r", loc(1, 29)),
		(ltok::LIT_STR, "\t", loc(1, 34)),
		(ltok::LIT_STR, "\v", loc(1, 39)),
		(ltok::LIT_STR, "\0", loc(1, 44)),
		(ltok::LIT_STR, "\\", loc(1, 49)),
		(ltok::LIT_STR, "\'", loc(1, 54)),
	];
	// TODO: test \x and \u and \U
	lextest(in, expected);
	const in = "\"ab\\a\\b\\f\\n\\r\\t\\v\\0\\\\\\'\"";
	const expected: [_]token = [
		(ltok::LIT_STR, "ab\a\b\f\n\r\t\v\0\\\'", loc(1, 1)),
	];
	lextest(in, expected);
	const in = "\"hello world\" \"こんにちは\" \"return\" \"foo\"";
	const expected: [_]token = [
		(ltok::LIT_STR, "hello world", loc(1, 1)),
		(ltok::LIT_STR, "こんにちは", loc(1, 15)),
		(ltok::LIT_STR, "return", loc(1, 23)),
		(ltok::LIT_STR, "foo", loc(1, 32)),
	];
	lextest(in, expected);
};

@test fn literals() void = {
	// TODO: Float literals
	const in = "1e5 -1i32 9223372036854775809 1e2z 255u8 0o42u16\n"
		"0b1000101u32 0xDEADBEEFu64 -0b10i8 -5e0i16 -0o16i32\n"
		"0b00000010000001100000011100001111000000100000011000000111i64";
	const expected: [_]token = [
		(ltok::LIT_ICONST, 1e5i64, loc(1, 1)),
		(ltok::LIT_I32, -1i64, loc(1, 5)),
		(ltok::LIT_U64, 9223372036854775809u64, loc(1, 11)),
		(ltok::LIT_SIZE, 1e2u64, loc(1, 31)),
		(ltok::LIT_U8, 255u64, loc(1, 36)),
		(ltok::LIT_U16, 0o42u64, loc(1, 42)),
		(ltok::LIT_U32, 0b1000101u64, loc(2, 1)),
		(ltok::LIT_U64, 0xDEADBEEFu64, loc(2, 14)),
		(ltok::LIT_I8, -0b10i64, loc(2, 28)),
		(ltok::LIT_I16, -5e0i64, loc(2, 36)),
		(ltok::LIT_I32, -0o16i64, loc(2, 44)),
		// Binary solo
		(ltok::LIT_I64, 0b00000010000001100000011100001111000000100000011000000111i64, loc(3, 1)),
	];
	lextest(in, expected);
};
