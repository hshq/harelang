// hare::lex provides a lexer for Hare source code.
use ascii;
use bufio;
use encoding::utf8;
use fmt;
use io;
use sort;
use strconv;
use strings;

// State associated with a lexer.
export type lexer = struct {
	in: *io::stream,
	path: str,
	loc: (uint, uint),
	un: (token | void),
	rb: [2](rune | io::EOF | void),
};

// A syntax error
export type syntax = (location, str)!;

// All possible lexer errors
export type error = (io::error | syntax)!;

// Returns a human-friendly string for a given error
export fn strerror(err: error) const str = {
	static let buf: [2048]u8 = [0...];
	return match (err) {
		err: io::error => io::strerror(err),
		s: syntax => fmt::bsprintf(buf, "{}:{},{}: Syntax error: {}",
			s.0.path, s.0.line, s.0.col, s.1),
	};
};

// Initializes a new lexer for the given input stream. The path is borrowed.
export fn init(in: *io::stream, path: str) lexer = lexer {
	in = in,
	path = path,
	loc = (1, 1),
	un = void,
	rb = [void...],
};

// Returns the next token from the lexer.
export fn lex(lex: *lexer) (token | error) = {
	match (lex.un) {
		tok: token => {
			lex.un = void;
			return tok;
		},
		void => void,
	};

	let loc = location { ... };
	let r: rune = match (nextw(lex)?) {
		io::EOF => return (ltok::EOF, void, mkloc(lex)),
		r: (rune, location) => {
			loc = r.1;
			r.0;
		},
	};

	if (is_name(r, false)) {
		unget(lex, r);
		return lex_name(lex, loc);
	};
	if (ascii::isdigit(r)) {
		unget(lex, r);
		abort(); // TODO: Literals
	};

	let tok: ltok = switch (r) {
		* => return syntaxerr(loc, "invalid character"),
		'"', '\'' => {
			unget(lex, r);
			return lex_rn_str(lex, loc);
		},
		'.', '<', '>' => return lex3(lex, loc, r),
		'^', '*', '%', '/', '+', '-', ':', '!', '&', '|', '=' => {
			return lex2(lex, loc, r);
		},
		'~' => ltok::BNOT,
		',' => ltok::COMMA,
		'{' => ltok::LBRACE,
		'[' => ltok::LBRACKET,
		'(' => ltok::LPAREN,
		'}' => ltok::RBRACE,
		']' => ltok::RBRACKET,
		')' => ltok::RPAREN,
		';' => ltok::SEMICOLON,
		'?' => ltok::QUESTION,
	};
	return (tok, void, loc);
};

fn is_name(r: rune, num: bool) bool =
	ascii::isalpha(r) || r == '_' || r == '@' || (num && ascii::isdigit(r));

fn ncmp(a: const *void, b: const *void) int = {
	let a = a: const *str, b = b: const *str;
	return match (ascii::strcmp(*a, *b)) {
		void => abort("non-ascii name"), // TODO: Bubble me up
		i: int => i,
	};
};

fn lex_unicode(lex: *lexer, loc: location, n: size) (rune | error) = {
	assert(n < 9);
	let buf: [9]u8 = [0...];
	for (let i = 0z; i < n; i += 1z) {
		let r = match (next(lex)?) {
			io::EOF => return syntaxerr(loc,
				"unexpected EOF scanning for escape"),
			r: rune => r,
		};
		if (!ascii::isxdigit(r)) {
			return syntaxerr(loc,
				"unexpected rune scanning for escape");
		};
		buf[i] = r: u32: u8;
	};
	let s = strings::fromutf8_unsafe(buf[..n]);
	return strconv::stou32b(s, strconv::base::HEX) as u32: rune;
};

fn lex_rune(lex: *lexer, loc: location) (rune | error) = {
	let r = match (next(lex)?) {
		io::EOF => return syntaxerr(loc,
			"unexpected EOF scanning for rune"),
		r: rune => r,
	};
	if (r != '\\') {
		return r;
	};
	r = match (next(lex)?) {
		io::EOF => return syntaxerr(loc,
			"unexpected EOF scanning for escape"),
		r: rune => r,
	};
	return switch (r) {
		'\\' => '\\',
		'\'' => '\'',
		'0' => '\0',
		'a' => '\a',
		'b' => '\b',
		'f' => '\f',
		'n' => '\n',
		'r' => '\r',
		't' => '\t',
		'v' => '\v',
		'"' => '\"',
		'x' => lex_unicode(lex, loc, 2),
		'u' => lex_unicode(lex, loc, 4),
		'U' => lex_unicode(lex, loc, 8),
	};
};

fn lex_string(lex: *lexer, loc: location) (token | error) = {
	let chars: []u8 = [];
	for (true) match (next(lex)?) {
		io::EOF => return syntaxerr(loc, "unexpected EOF scanning string literal"),
		r: rune =>
			if (r == '"') break
			else {
				unget(lex, r);
				r = lex_rune(lex, loc)?;
				append(chars, utf8::encoderune(r)...);
			},
	};
	return (ltok::LITERAL, strings::fromutf8(chars), loc);
};

fn lex_rn_str(lex: *lexer, loc: location) (token | error) = {
	let r = match (next(lex)) {
		r: rune => r,
		(io::EOF | io::error) => abort(),
	};
	switch (r) {
		'\"' => return lex_string(lex, loc),
		'\'' => void,
		* => abort(), // Invariant
	};

	// Rune literal
	let ret: token = (ltok::LITERAL, lex_rune(lex, loc)?, loc);
	match (next(lex)?) {
		io::EOF =>
			return syntaxerr(loc, "unexpected EOF"),
		n: rune => if (n != '\'')
			return syntaxerr(loc, "expected \"\'\""),
	};
	return ret;
};

fn lex_name(lex: *lexer, loc: location) (token | error) = {
	let chars: []u8 = [];
	match (next(lex)) {
		r: rune => {
			assert(is_name(r, false));
			append(chars, utf8::encoderune(r)...);
		},
		(io::EOF | io::error) => abort(),
	};

	for (true) match (next(lex)?) {
		io::EOF => break,
		r: rune => {
			if (!is_name(r, true)) {
				unget(lex, r);
				break;
			};
			append(chars, utf8::encoderune(r)...);
		},
	};

	let n = strings::fromutf8(chars);
	return match (sort::search(bmap[..ltok::LAST_KEYWORD+1],
			size(str), &n, &ncmp)) {
		// TODO: Validate that names are ASCII
		null => (ltok::NAME, n, loc),
		v: *void => {
			let tok = v: uintptr - &bmap[0]: uintptr;
			tok /= size(str): uintptr;
			(tok: ltok, void, loc);
		},
	};
};

fn lex2(lexr: *lexer, loc: location, r: rune) (token | error) = {
	let n = next(lexr)?;
	let tok: ltok = switch (r) {
		'^' => match (n) {
			r: rune => switch (r) {
				'^' => return (ltok::LXOR, void, loc),
				'=' => return (ltok::BXOREQ, void, loc),
				*   => ltok::BXOR,
			},
			io::EOF => ltok::BXOR,
		},
		'*' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::TIMESEQ, void, loc),
				*   => ltok::TIMES,
			},
			io::EOF => ltok::TIMES,
		},
		'/' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::DIVEQ, void, loc),
				'/' => {
					// Comment
					for (true) match (next(lexr)?) {
						io::EOF => break,
						r: rune => if (r == '\n') {
							break;
						},
					};
					return lex(lexr);
				},
				*   => ltok::DIV,
			},
			io::EOF => ltok::DIV,
		},
		'%' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::MODEQ, void, loc),
				*   => ltok::MODULO,
			},
			io::EOF => ltok::MODULO,
		},
		'+' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::PLUSEQ, void, loc),
				*   => ltok::PLUS,
			},
			io::EOF => ltok::PLUS,
		},
		'-' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::MINUSEQ, void, loc),
				*   => ltok::MINUS,
			},
			io::EOF => ltok::MINUS,
		},
		':' => match (n) {
			r: rune => switch (r) {
				':' => return (ltok::DOUBLE_COLON, void, loc),
				*   => ltok::COLON,
			},
			io::EOF => ltok::COLON,
		},
		'!' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::NEQUAL, void, loc),
				*   => ltok::LNOT,
			},
			io::EOF => ltok::LNOT,
		},
		'&' => match (n) {
			r: rune => switch (r) {
				'&' => return (ltok::LAND, void, loc),
				'=' => return (ltok::ANDEQ, void, loc),
				*   => ltok::BAND,
			},
			io::EOF => ltok::BAND,
		},
		'|' => match (n) {
			r: rune => switch (r) {
				'|' => return (ltok::LOR, void, loc),
				'=' => return (ltok::OREQ, void, loc),
				*   => ltok::BOR,
			},
			io::EOF => ltok::BOR,
		},
		'=' => match (n) {
			r: rune => switch (r) {
				'=' => return (ltok::LEQUAL, void, loc),
				*   => ltok::EQUAL,
			},
			io::EOF => ltok::EQUAL,
		},
		* => return syntaxerr(loc, "unknown token sequence"),
	};
	unget(lexr, n);
	return (tok, void, loc);
};

fn lex3(lex: *lexer, loc: location, r: rune) (token | error) = {
	let n = match (next(lex)?) {
		io::EOF => return switch (r) {
			'.' => (ltok::DOT, void, loc),
			'<' => (ltok::LESS, void, loc),
			'>' => (ltok::GREATER, void, loc),
			*   => abort(), // Invariant
		},
		r: rune => r,
	};
	return switch (r) {
		'.' => lex3dot(lex, loc, n),
		'<' => lex3lt(lex, loc, n),
		'>' => lex3gt(lex, loc, n),
		* => syntaxerr(loc, "unknown token sequence"),
	};
};

fn lex3dot(lex: *lexer, loc: location, n: rune) (token | error) = {
	let tok: ltok = switch (n) {
		'.' => {
			let q = match (next(lex)?) {
				io::EOF => io::EOF,
				r: rune => r,
			};
			let t = match (q) {
				r: rune => switch (r) {
					'.' => return (ltok::ELLIPSIS, void, loc),
					*   => ltok::SLICE,
				},
				io::EOF => ltok::SLICE,
			};
			unget(lex, q);
			t;
		},
		* => {
			unget(lex, n);
			ltok::DOT;
		}
	};
	return (tok, void, loc);
};

fn lex3lt(lex: *lexer, loc: location, n: rune) (token | error) = {
	let tok: ltok = switch (n) {
		'<' => {
			let q = match (next(lex)?) {
				io::EOF => io::EOF,
				r: rune => r,
			};
			let t = match (q) {
				r: rune => switch (r) {
					'=' => return (ltok::LSHIFTEQ, void, loc),
					*   => ltok::LSHIFT,
				},
				io::EOF => ltok::LSHIFT,
			};
			unget(lex, q);
			t;
		},
		'=' => ltok::LESSEQ,
		* => {
			unget(lex, n);
			ltok::LESS;
		}
	};
	return (tok, void, loc);
};

fn lex3gt(lex: *lexer, loc: location, n: rune) (token | error) = {
	let tok: ltok = switch (n) {
		'>' => {
			let q = match (next(lex)?) {
				io::EOF => io::EOF,
				r: rune => r,
			};
			let t = match (q) {
				r: rune => switch (r) {
					'=' => return (ltok::RSHIFTEQ, void, loc),
					*   => ltok::RSHIFT,
				},
				io::EOF => ltok::RSHIFT,
			};
			unget(lex, q);
			t;
		},
		'=' => ltok::GREATEREQ,
		* => {
			unget(lex, n);
			ltok::GREATER;
		}
	};
	return (tok, void, loc);
};

// Unlex a single token. The next call to [lex] will return this token. Only one
// unlex is supported at a time; you must call [lex] before calling [unlex]
// again.
export fn unlex(lex: *lexer, tok: token) void = {
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
		return match (bufio::scanrune(lex.in)) {
			e: (io::EOF | io::error) => e,
			r: rune => {
				lexloc(lex, r);
				r;
			},
		};
	};

	abort("unreachable");
};

fn nextw(lex: *lexer) ((rune, location) | io::EOF | io::error) = {
	for (true) {
		let loc = mkloc(lex);
		match (next(lex)) {
			e: (io::error | io::EOF) => return e,
			r: rune => if (!ascii::isspace(r)) {
				return (r, loc);
			},
		};
	};
	abort();
};

fn lexloc(lex: *lexer, r: rune) void = {
	switch (r) {
		'\n' => {
			lex.loc.0 += 1;
			lex.loc.1 = 1;
		},
		'\t' => lex.loc.1 += 8,
		*    => lex.loc.1 += 1,
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

fn syntaxerr(loc: location, why: str) error = (loc, why);
