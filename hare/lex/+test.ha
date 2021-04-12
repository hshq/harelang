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

fn vassert(expected: value, actual: value) bool = {
	if (expected.storage != actual.storage) {
		return false;
	};
	return switch (expected.storage) {
		storage::U8,
		storage::U16,
		storage::U32,
		storage::U64,
		storage::UINT,
		storage::UINTPTR => expected._uint == actual._uint,
		storage::I8,
		storage::I16,
		storage::I32,
		storage::I64,
		storage::INT,
		storage::ICONST => expected._int == actual._int,
		storage::F32,
		storage::F64,
		storage::FCONST => expected.float == actual.float,
		storage::RUNE => expected._rune == actual._rune,
		storage::STR => expected.string == actual.string,
	};
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
		if (etok.1 is void) {
			assert(tl.1 is void);
		} else if (etok.1 is str) {
			assert(tl.1 as str == etok.1 as str);
		} else {
			vassert(tl.1 as value, etok.1 as value);
		};
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
};

@test fn runes() void = {
	const in = "'a' 'b' '\\a' '\\b' '\\f' '\\n' '\\r' '\\t' '\\v' '\\0' "
		"'\\\\' '\\\'' '\\x0A' '\\u1234' '\\U12345678'";
	const expected: [_]token = [
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = 'a' }, loc(1, 1)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = 'b' }, loc(1, 5)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\a' }, loc(1, 9)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\b' }, loc(1, 14)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\f' }, loc(1, 19)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\n' }, loc(1, 24)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\r' }, loc(1, 29)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\t' }, loc(1, 34)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\v' }, loc(1, 39)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\0' }, loc(1, 44)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\\' }, loc(1, 49)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\'' }, loc(1, 54)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\x0A' }, loc(1, 59)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\u1234' }, loc(1, 66)),
		(ltok::LITERAL, value { storage = storage::RUNE, _rune = '\U12345678' }, loc(1, 75)),
	];
	lextest(in, expected);
};

@test fn strings() void = {
	const in = "\"a\" \"b\" \"\\a\" \"\\b\" \"\\f\" \"\\n\" \"\\r\" "
		"\"\\t\" \"\\v\" \"\\0\" \"\\\\\" \"\\\'\"";
	const expected: [_]token = [
		(ltok::LITERAL, value { storage = storage::STR, string = "a" }, loc(1, 1)),
		(ltok::LITERAL, value { storage = storage::STR, string = "b" }, loc(1, 5)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\a" }, loc(1, 9)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\b" }, loc(1, 14)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\f" }, loc(1, 19)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\n" }, loc(1, 24)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\r" }, loc(1, 29)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\t" }, loc(1, 34)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\v" }, loc(1, 39)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\0" }, loc(1, 44)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\\" }, loc(1, 49)),
		(ltok::LITERAL, value { storage = storage::STR, string = "\'" }, loc(1, 54)),
	];
	// TODO: test \x and \u and \U
	lextest(in, expected);
	const in = "\"ab\\a\\b\\f\\n\\r\\t\\v\\0\\\\\\'\"";
	const expected: [_]token = [
		(ltok::LITERAL, value { storage = storage::STR, string = "ab\a\b\f\n\r\t\v\0\\\'" }, loc(1, 1)),
	];
	lextest(in, expected);
	const in = "\"hello world\" \"こんにちは\" \"return\" \"foo\"";
	const expected: [_]token = [
		(ltok::LITERAL, value { storage = storage::STR, string = "hell }o world" }, loc(1, 1)),
		(ltok::LITERAL, value { storage = storage::STR, string = "こんにちは" }, loc(1, 15)),
		(ltok::LITERAL, value { storage = storage::STR, string = "return" }, loc(1, 23)),
		(ltok::LITERAL, value { storage = storage::STR, string = "foo" }, loc(1, 32)),
	];
	lextest(in, expected);
};
