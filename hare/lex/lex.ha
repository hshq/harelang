use ascii;
use bufio;
use encoding::utf8;
use fmt;
use io;
use sort;
use strconv;
use strings;
use strio;
use types;

// State associated with a lexer.
export type lexer = struct {
	in: *io::stream,
	path: str,
	loc: (uint, uint),
	un: (token | void),
	rb: [2](rune | io::EOF | void),
	flags: flags,
	comment: str,
};

// Flags which apply to this lexer
export type flags = enum uint {
	// Enables lexing comments
	COMMENTS = 1 << 0,
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
export fn init(in: *io::stream, path: str, flags: flags...) lexer = {
	let f: flags = 0: flags;
	for (let i = 0z; i < len(flags); i += 1) {
		f |= flags[i];
	};
	return lexer {
		in = in,
		path = path,
		loc = (1, 1),
		un = void,
		rb = [void...],
		flags = f,
		comment = "",
	};
};

// Returns the current value of the comment buffer, or empty string if unset (or
// if [[flags::COMMENTS]] was not enabled for this lexer).
export fn comment(lex: *lexer) str = lex.comment;

// Returns the next token from the lexer.
export fn lex(lex: *lexer) (token | error) = {
	match (lex.un) {
		tok: token => {
			lex.un = void;
			return tok;
		},
		_: void => void,
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
		return lex_name(lex, loc, true);
	};
	if (ascii::isdigit(r)) {
		unget(lex, r);
		return lex_literal(lex, loc);
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
		_: void => abort("non-ascii name"), // TODO: Bubble me up
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
	let buf = strio::dynamic();
	for (true) match (next(lex)?) {
		io::EOF => return syntaxerr(loc, "unexpected EOF scanning string literal"),
		r: rune =>
			if (r == '"') break
			else {
				unget(lex, r);
				r = lex_rune(lex, loc)?;
				strio::appendrune(buf, r);
			},
	};
	return (ltok::LIT_STR, strio::finish(buf), loc);
};

fn lex_rn_str(lex: *lexer, loc: location) (token | error) = {
	let r = match (next(lex)) {
		r: rune => r,
		_: (io::EOF | io::error) => abort(),
	};
	switch (r) {
		'\"' => return lex_string(lex, loc),
		'\'' => void,
		* => abort(), // Invariant
	};

	// Rune literal
	let ret: token = (ltok::LIT_RUNE, lex_rune(lex, loc)?, loc);
	match (next(lex)?) {
		io::EOF =>
			return syntaxerr(loc, "unexpected EOF"),
		n: rune => if (n != '\'')
			return syntaxerr(loc, "expected \"\'\""),
	};
	return ret;
};

fn lex_name(lex: *lexer, loc: location, keyword: bool) (token | error) = {
	let buf = strio::dynamic();
	match (next(lex)) {
		r: rune => {
			assert(is_name(r, false));
			strio::appendrune(buf, r);
		},
		_: (io::EOF | io::error) => abort(),
	};

	for (true) match (next(lex)?) {
		io::EOF => break,
		r: rune => {
			if (!is_name(r, true)) {
				unget(lex, r);
				break;
			};
			strio::appendrune(buf, r);
		},
	};

	let n = strio::finish(buf);
	if (!keyword) {
		return (ltok::NAME, n, loc);
	};

	return match (sort::search(bmap[..ltok::LAST_KEYWORD+1],
			size(str), &n, &ncmp)) {
		null => (ltok::NAME, n, loc),
		v: *void => {
			defer free(n);
			let tok = v: uintptr - &bmap[0]: uintptr;
			tok /= size(str): uintptr;
			(tok: ltok, void, loc);
		},
	};
};

fn lex_comment(lexr: *lexer, loc: location) (token | error) = {
	if (lexr.flags & flags::COMMENTS != flags::COMMENTS) {
		for (true) match (next(lexr)?) {
			io::EOF => break,
			r: rune => if (r == '\n') break,
		};
		return lex(lexr);
	};

	let buf = strio::dynamic();
	defer io::close(buf);
	for (true) match (next(lexr)?) {
		io::EOF => break,
		r: rune => {
			strio::appendrune(buf, r);
			if (r == '\n') break;
		},
	};
	let new = strings::concat(lexr.comment, strio::string(buf));
	free(lexr.comment);
	lexr.comment = new;
	return lex(lexr);
};

fn lex_literal(lex: *lexer, loc: location) (token | error) = {
	let chars: []u8 = [];
	let r = match (next(lex)?) {
		io::EOF => return (ltok::EOF, void, loc),
		r: rune => r,
	};
	if (r == '-') {
		append(chars, utf8::encoderune(r)...);
		r = match (next(lex)?) {
			io::EOF => return (ltok::EOF, void, loc),
			r: rune => r,
		};
	};

	let base = 10u;
	if (r == '0') {
		append(chars, utf8::encoderune(r)...);
		r = match (next(lex)?) {
			io::EOF => return (ltok::LIT_ICONST, 0i64, loc),
			r: rune => r,
		};
		switch (r) {
			'b' => base = 2,
			'o' => base = 8,
			'x' => base = 16,
			* => unget(lex, r),
		};
	} else unget(lex, r);
	let basechrs = switch (base) {
		2 => "01",
		8 => "01234567",
		10 => "0123456789",
		16 => "0123456789ABCDEFabcdef",
	};

	let suff: (size | void) = void;
	let exp: (size | void) = void;
	let end = 0z;
	let float = false;
	for (true) {
		r = match (next(lex)?) {
			io::EOF => break,
			r: rune => r,
		};
		if (!strings::contains(basechrs, r)) switch (r) {
			'.' => if (float || exp is size || suff is size
					|| base != 10) {
				unget(lex, r);
				break;
			} else {
				r = match (next(lex)?) {
					io::EOF => break,
					r: rune => r,
				};
				if (!strings::contains(basechrs, r)) {
					unget(lex, r);
					unget(lex, '.');
					break;
				};
				unget(lex, r);
				float = true;
				append(chars, utf8::encoderune('.')...);
			},
			'e' => if (exp is size || suff is size || base != 10) {
				unget(lex, r);
				break;
			} else {
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r)...);
				exp = len(chars);
			},
			'i', 'u', 'f', 'z' => if (suff is size) {
				unget(lex, r);
				break;
			} else {
				suff = len(chars);
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r)...);
				basechrs = "0123456789";
			},
			* => {
				unget(lex, r);
				break;
			},
		} else append(chars, utf8::encoderune(r)...);
	};
	if (end == 0) end = len(chars);

	let exp = match (exp) {
		_: void => "0",
		exp: size => {
			let end = match (suff) {
				_: void => len(chars),
				suff: size => suff,
			};
			strings::fromutf8(chars[exp..end]);
		},
	};
	let exp = match (strconv::stoz(exp)) {
		exp: size => exp,
		strconv::invalid => abort(), // Shouldn't be lexed in
		strconv::overflow =>
			return syntaxerr(loc, "overflow in exponent"),
	};

	let suff = match (suff) {
		suff: size => strings::fromutf8(chars[suff..]),
		_: void => "",
	};
	let suff = if (suff == "u8") ltok::LIT_U8
		else if (suff == "u16") ltok::LIT_U16
		else if (suff == "u32") ltok::LIT_U32
		else if (suff == "u64") ltok::LIT_U64
		else if (suff == "u") ltok::LIT_UINT
		else if (suff == "z") ltok::LIT_SIZE
		else if (suff == "i8") ltok::LIT_I8
		else if (suff == "i16") ltok::LIT_I16
		else if (suff == "i32") ltok::LIT_I32
		else if (suff == "i64") ltok::LIT_I64
		else if (suff == "i") ltok::LIT_INT
		else if (suff == "" && !float) ltok::LIT_ICONST
		else if (suff == "f32") ltok::LIT_F32
		else if (suff == "f64") ltok::LIT_F64
		else if (suff == "" && float) ltok::LIT_FCONST
		else return syntaxerr(loc, "invalid literal suffix");

	let val = strings::fromutf8(chars[..end]);
	let val = switch (suff) {
		ltok::LIT_U8, ltok::LIT_U16, ltok::LIT_U32, ltok::LIT_U64,
		ltok::LIT_UINT, ltok::LIT_SIZE => strconv::stou64b(val, base),
		ltok::LIT_ICONST => match (strconv::stoi64b(val, base)) {
			i: i64 => i,
			strconv::invalid => abort(),
			strconv::overflow => if (chars[0] != '-': u32: u8) {
				suff = ltok::LIT_U64;
				strconv::stou64b(val, base);
			} else strconv::overflow,
		},
		ltok::LIT_I8, ltok::LIT_I16, ltok::LIT_I32, ltok::LIT_I64,
		ltok::LIT_INT => strconv::stoi64b(val, base),
		ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST => abort(), // TODO
	};
	let val = match (val) {
		val: u64 => {
			for (let i = 0z; i < exp; i += 1) {
				val *= 10;
			};
			val;
		},
		val: i64 => {
			for (let i = 0z; i < exp; i += 1) {
				val *= 10;
			};
			val;
		},
		strconv::invalid => abort(), // Shouldn't be lexed in
		strconv::overflow =>
			return syntaxerr(loc, "overflow in exponent"),
	};

	return (suff, val, loc);
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
				'/' => return lex_comment(lexr, loc),
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
				*   => if (ascii::isdigit(r)) {
					unget(lexr, r);
					unget(lexr, '-');
					return lex_literal(lexr, loc);
				} else {
					ltok::MINUS;
				},
			},
			io::EOF => ltok::MINUS,
		},
		':' => match (n) {
			r: rune => switch (r) {
				':' => return (ltok::DOUBLE_COLON, void, loc),
				* => if (is_name(r, false)) {
					unget(lexr, r);
					let tok = lex_name(lexr, loc, false)?;
					tok.0 = ltok::LABEL;
					return tok;
				} else ltok::COLON,
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
				'>' => return (ltok::CASE, void, loc),
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

// Unlex a single token. The next call to [[lex]] will return this token. Only one
// unlex is supported at a time; you must call [[lex]] before calling [[unlex]]
// again.
export fn unlex(lex: *lexer, tok: token) void = {
	assert(lex.un is void, "attempted to unlex more than one token");
	lex.un = tok;
};

fn next(lex: *lexer) (rune | io::EOF | io::error) = {
	match (lex.rb[0]) {
		_: void => void,
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
			} else {
				free(lex.comment);
				lex.comment = "";
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
