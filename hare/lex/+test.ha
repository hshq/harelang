use bufio;
use fmt;
use io;
use strings;

@test fn unget() void = {
	let lexer = lexer_init(bufio::fixed(strings::to_utf8("z")), "<test>");
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
	let lexer = lexer_init(io::empty, "<test>");
	unlex(&lexer, (btoken::IF, location {
		path = "<test>",
		line = 1234,
		col = 1234,
	}));
	let t = lex(&lexer) as (token, location);
	assert(t.0 is btoken);
	assert(t.0 as btoken == btoken::IF);
	assert(t.1.path == "<test>");
	assert(t.1.line == 1234 && t.1.col == 1234);
};

fn lextest(in: str, expected: [](uint, uint, token)) void = {
	let lexer = lexer_init(bufio::fixed(strings::to_utf8(in)), "<test>");
	for (let i = 0z; i < len(expected); i += 1) {
		let eline = expected[i].0, ecol = expected[i].1,
			etok = expected[i].2;
		let tl = match (lex(&lexer)) {
			tl: (token, location) => tl,
			* => abort(),
		};
		let tok = tl.0, loc = tl.1;
		match (tok) {
			b: btoken => if (!(etok is btoken) || etok as btoken != b) {
				fmt::errorln("bad token at {}: got {}, wanted {}",
					i, tokstr(tok), tokstr(etok));
				abort();
			},
			n: name => if (!(etok is name) || etok as name != n) {
				fmt::errorln("bad token at {}: got {}, wanted {}",
					i, tokstr(tok), tokstr(etok));
				abort();
			},
			* => abort("TODO"),
		};
		assert(loc.path == "<test>");
		if (loc.line != eline || loc.col != ecol) {
			fmt::errorln("bad line/col at {}: got {},{}; wanted {},{}",
				i, loc.line, loc.col, eline, ecol);
			abort();
		};
	};
	assert(lex(&lexer) is io::EOF);
};

@test fn lex1() void = {
	const in = "~,{[(}]);";
	const expected: [_](uint, uint, token) = [
		(1, 1, btoken::BNOT),
		(1, 2, btoken::COMMA),
		(1, 3, btoken::LBRACE),
		(1, 4, btoken::LBRACKET),
		(1, 5, btoken::LPAREN),
		(1, 6, btoken::RBRACE),
		(1, 7, btoken::RBRACKET),
		(1, 8, btoken::RPAREN),
		(1, 9, btoken::SEMICOLON),
	];
	lextest(in, expected);
};

@test fn lex2() void = {
	// Ends with = to test =, EOF
	const in = "^ ^^ ^= * *= % %= + += - -= : :: & && &= | || |= = == / /= =";
	const expected: [_](uint, uint, token) = [
		(1, 1,  btoken::BXOR),
		(1, 3,  btoken::LXOR),
		(1, 6,  btoken::BXOREQ),
		(1, 9,  btoken::TIMES),
		(1, 11, btoken::TIMESEQ),
		(1, 14, btoken::MODULO),
		(1, 16, btoken::MODEQ),
		(1, 19, btoken::PLUS),
		(1, 21, btoken::PLUSEQ),
		(1, 24, btoken::MINUS),
		(1, 26, btoken::MINUSEQ),
		(1, 29, btoken::COLON),
		(1, 31, btoken::DOUBLE_COLON),
		(1, 34, btoken::BAND),
		(1, 36, btoken::LAND),
		(1, 39, btoken::ANDEQ),
		(1, 42, btoken::BOR),
		(1, 44, btoken::LOR),
		(1, 47, btoken::OREQ),
		(1, 50, btoken::EQUAL),
		(1, 52, btoken::LEQUAL),
		(1, 55,  btoken::DIV),
		(1, 57, btoken::DIVEQ),
		(1, 60, btoken::EQUAL),
	];
	lextest(in, expected);
};

@test fn lex3() void = {
	const in = ". .. ... < << <= <<= > >> >= >>= >>";
	const expected: [_](uint, uint, token) = [
		(1, 1,  btoken::DOT),
		(1, 3,  btoken::SLICE),
		(1, 6,  btoken::ELLIPSIS),
		(1, 10, btoken::LESS),
		(1, 12, btoken::LSHIFT),
		(1, 15, btoken::LESSEQ),
		(1, 18, btoken::LSHIFTEQ),
		(1, 22, btoken::GREATER),
		(1, 24, btoken::RSHIFT),
		(1, 27, btoken::GREATEREQ),
		(1, 30, btoken::RSHIFTEQ),
		(1, 34, btoken::RSHIFT),
	];
	lextest(in, expected);
};

@test fn lexname() void = {
	const in = "hello world return void foobar";
	const expected: [_](uint, uint, token) = [
		(1, 1,  "hello": name),
		(1, 7,  "world": name),
		(1, 13, btoken::RETURN),
		(1, 20, btoken::VOID),
		(1, 25, "foobar": name),
	];
	lextest(in, expected);
};

@test fn comments() void = {
	const in = "hello world // foo\nbar";
	const expected: [_](uint, uint, token) = [
		(1, 1,  "hello": name),
		(1, 7,  "world": name),
		(2, 1, "bar": name),
	];
	lextest(in, expected);
};
