// hare::lex provides a lexer for Hare source code.
use bufio;
use io;
use strings;
use types;

// State associated with a lexer.
export type lexer = struct {
	in: *io::stream,
	path: str,
	loc: linecol,
	un: ((token, location) | void),
	rb: [2](rune | io::EOF | void),
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
export fn lex(lex: *lexer) ((token, location) | io::EOF | io::error) = {
	match (lex.un) {
		tok: (token, location) => {
			lex.un = void;
			return tok;
		},
		void => void,
	};

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
	return match (io::getrune(lex.in)) {
		r: rune => r,
		io::EOF => io::EOF,
		err: io::error => err,
	};
};

fn unget(lex: *lexer, r: (rune | io::EOF)) void = {
	if (!(lex.rb[0] is void)) {
		assert(lex.rb[1] is void, "ungot too many runes");
		lex.rb[1] = lex.rb[0];
	};
	lex.rb[0] = r;
};

@test fn unget() void = {
	let lexer = lexer_init(bufio::fixed([]), "<test>");
	unget(&lexer, 'x');
	unget(&lexer, 'y');
	assert(next(&lexer) as rune == 'y');
	assert(next(&lexer) as rune == 'x');
	assert(next(&lexer) is io::EOF);
};
