// hare::lex provides a lexer for Hare source code.
use ascii;
use bufio;
use io;
use strings;
use types;

// State associated with a lexer.
export type lexer = struct {
	in: *io::stream,
	path: str,
	loc: (uint, uint),
	un: ((token, location) | void),
	rb: [2](rune | io::EOF | void),
};

// A syntax error
export type syntax = location;

// All possible lexer errors
export type error = (io::error | syntax);

export fn errstr(err: error) const str = {
	return match (err) {
		err: io::error => io::errstr(err),
		syntax => "Syntax error", // TODO: add line info
	};
};

// Initializes a new lexer for the given input stream. The path is borrowed.
export fn lexer_init(in: *io::stream, path: str) lexer = lexer {
	in = in,
	path = path,
	loc = (1, 1),
	un = void,
	rb = [void...],
};

// Returns the next token from the lexer.
export fn lex(lex: *lexer) ((token, location) | io::EOF | error) = {
	match (lex.un) {
		tok: (token, location) => {
			lex.un = void;
			return tok;
		},
		void => void,
	};

	let loc = mkloc(lex);
	let r: rune = match (next(lex)) {
		e: io::error => return e,
		io::EOF => return io::EOF,
		r: rune => r,
	};

	if (ascii::isalpha(r) || r == '_' || r == '@') {
		unget(lex, r);
		abort(); // TODO: Keywords/names
	};
	if (ascii::isdigit(r)) {
		unget(lex, r);
		abort(); // TODO: Literals
	};

	let tok: token = switch (r) {
		* => return mkloc(lex),
		'"', '\'' => abort(), // TODO: Strings/runes
		'.', '<', '>' => return lex3(lex, r),
		'^', '*', '%', '/', '+', '-', ':', '!', '&', '|', '=' => {
			return lex2(lex, r);
		},
		'~' => btoken::BNOT,
		',' => btoken::COMMA,
		'{' => btoken::LBRACE,
		'[' => btoken::LBRACKET,
		'(' => btoken::LPAREN,
		'}' => btoken::RBRACE,
		']' => btoken::RBRACKET,
		')' => btoken::RPAREN,
		';' => btoken::SEMICOLON,
	};

	return (tok, loc);
};

fn lex3(lex: *lexer, r: rune) ((token, location) | io::EOF | error) = {
	abort();
	return io::EOF; // TODO
};

fn lex2(lex: *lexer, r: rune) ((token, location) | io::EOF | error) = {
	abort();
	return io::EOF; // TODO
};

// Unlex a single token. The next call to [lex] will return this token, location
// pair. Only one unlex is supported at a time; you must call [lex] before
// calling [unlex] again.
export fn unlex(lex: *lexer, tok: (token, location)) void = {
	assert(lex.un is void, "attempted to unlex more than one token");
	lex.un = tok;
};

fn next(lex: *lexer) (rune | io::EOF | io::error) = {
	match (lex.rb[0]) {
		void => void,
		r: (rune | io::EOF) => {
			lex.rb[0] = lex.rb[1];
			lex.rb[1] = void;
			return r;
		},
	};

	for (true) {
		return match (io::getrune(lex.in)) {
			io::EOF => io::EOF,
			err: io::error => err,
			r: rune => {
				lexloc(lex, r);
				if (ascii::isspace(r)) continue;
				r;
			},
		};
	};

	abort("unreachable");
};

fn lexloc(lex: *lexer, r: rune) void = {
	switch (r) {
		'\n' => {
			lex.loc.0 += 1;
			lex.loc.1 = 1;
		},
		'\t' => {
			lex.loc.1 += 8;
		},
		* => {
			lex.loc.1 += 1;
		},
	};
};

fn unget(lex: *lexer, r: (rune | io::EOF)) void = {
	if (!(lex.rb[0] is void)) {
		assert(lex.rb[1] is void, "ungot too many runes");
		lex.rb[1] = lex.rb[0];
	};
	lex.rb[0] = r;
};

fn mkloc(lex: *lexer) location = location {
	path = lex.path,
	line = lex.loc.0,
	col = lex.loc.1,
};

@test fn unget() void = {
	let lexer = lexer_init(io::empty, "<test>");
	unget(&lexer, 'x');
	unget(&lexer, 'y');
	assert(next(&lexer) as rune == 'y');
	assert(next(&lexer) as rune == 'x');
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

@test fn lex1() void = {
	const in = "~,{[(}]);";
	const expected = [
		btoken::BNOT,
		btoken::COMMA,
		btoken::LBRACE,
		btoken::LBRACKET,
		btoken::LPAREN,
		btoken::RBRACE,
		btoken::RBRACKET,
		btoken::RPAREN,
		btoken::SEMICOLON,
	];
	let lexer = lexer_init(bufio::fixed(strings::to_utf8(in)), "<test>");
	for (let i = 0z; i < len(expected); i += 1) {
		let tl = lex(&lexer) as (token, location);
		let tok = tl.0, loc = tl.1;
		assert(tok as btoken == expected[i]);
		assert(loc.path == "<test>");
		assert(loc.line == 1 && loc.col == i + 1);
	};
};
