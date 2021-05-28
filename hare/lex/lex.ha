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

export type lexer = struct {
	in: *io::stream,
	path: str,
	loc: (uint, uint),
	un: (token | void),
	rb: [2]((rune, location) | io::EOF | void),
	// 1 more than the size of un and rb respectively
	prevunlocs: [2](location, location),
	prevrlocs: [3]location,
	flags: flags,
	comment: str,
};

// Flags which apply to this lexer
export type flags = enum uint {
	// Enables lexing comments
	COMMENTS = 1 << 0,
};

// A syntax error
export type syntax = !(location, str);

// All possible lexer errors
export type error = !(io::error | syntax);

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
	const loc = location { path = path, line = 1, col = 1 };
	return lexer {
		in = in,
		path = path,
		loc = (1, 1),
		un = void,
		rb = [void...],
		prevunlocs = [(loc, loc)...],
		prevrlocs = [loc...],
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
		void => void,
	};

	defer {
		lex.prevunlocs[1] = lex.prevunlocs[0];
		lex.prevunlocs[0] = (prevloc(lex), mkloc(lex));
	};

	let r = match (nextw(lex)?) {
		io::EOF => return (ltok::EOF, void, mkloc(lex)),
		r: (rune, location) => r,
	};

	if (is_name(r.0, false)) {
		unget(lex, r);
		return lex_name(lex, r.1, false);
	};
	if (ascii::isdigit(r.0)) {
		unget(lex, r);
		return lex_literal(lex);
	};

	let tok = switch (r.0) {
		* => return syntaxerr(r.1, "invalid character"),
		'"', '\'' => {
			unget(lex, r);
			return lex_rn_str(lex);
		},
		'.', '<', '>', '&', '|', '^' => {
			unget(lex, r);
			return lex3(lex);
		},
		'*', '%', '/', '+', '-', ':', '!', '=' => {
			unget(lex, r);
			return lex2(lex);
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
	return (tok, void, r.1);
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
			r: (rune, location) => r.0,
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
		r: (rune, location) => r.0,
	};
	if (r != '\\') {
		return r;
	};
	r = match (next(lex)?) {
		io::EOF => return syntaxerr(loc,
			"unexpected EOF scanning for escape"),
		r: (rune, location) => r.0,
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
		r: (rune, location) =>
			if (r.0 == '"') break
			else {
				unget(lex, r);
				let r = lex_rune(lex, loc)?;
				strio::appendrune(buf, r)?;
			},
	};
	match (nextw(lex)?) {
		io::EOF => void,
		r: (rune, location) => {
			if (r.0 == '"') {
				const tok = lex_string(lex, loc)?;
				const next = tok.1 as str;
				strio::concat(buf, next)!;
				free(next);
			} else {
				unget(lex, r);
			};
		},
	};
	return (ltok::LIT_STR, strio::finish(buf), loc);
};

fn lex_rn_str(lex: *lexer) (token | error) = {
	const loc = mkloc(lex);
	let r = match (next(lex)) {
		r: (rune, location) => r.0,
		(io::EOF | io::error) => abort(),
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
		n: (rune, location) => if (n.0 != '\'')
			return syntaxerr(n.1, "expected \"\'\""),
	};
	return ret;
};

fn lex_name(lex: *lexer, loc: location, label: bool) (token | error) = {
	let buf = strio::dynamic();
	match (next(lex)) {
		r: (rune, location) => {
			assert(is_name(r.0, false));
			strio::appendrune(buf, r.0)!;
		},
		(io::EOF | io::error) => abort(),
	};

	for (true) match (next(lex)?) {
		io::EOF => break,
		r: (rune, location) => {
			if (!is_name(r.0, true)) {
				unget(lex, r);
				break;
			};
			strio::appendrune(buf, r.0)?;
		},
	};

	let n = strio::finish(buf);
	if (label) {
		return (ltok::LABEL, n, loc);
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

fn lex_comment(lexr: *lexer) (token | error) = {
	if (lexr.flags & flags::COMMENTS != flags::COMMENTS) {
		for (true) match (next(lexr)?) {
			io::EOF => break,
			r: (rune, location) => if (r.0 == '\n') break,
		};
		return lex(lexr);
	};

	let buf = strio::dynamic();
	defer io::close(buf);
	for (true) match (next(lexr)?) {
		io::EOF => break,
		r: (rune, location) => {
			strio::appendrune(buf, r.0)!;
			if (r.0 == '\n') break;
		},
	};
	let new = strings::concat(lexr.comment, strio::string(buf));
	free(lexr.comment);
	lexr.comment = new;
	return lex(lexr);
};

fn lex_literal(lex: *lexer) (token | error) = {
	const loc = mkloc(lex);
	let chars: []u8 = [];
	let r = match (next(lex)?) {
		io::EOF => return (ltok::EOF, void, loc),
		r: (rune, location) => r,
	};
	if (r.0 == '-') {
		append(chars, utf8::encoderune(r.0)...);
		r = match (next(lex)?) {
			io::EOF => return (ltok::EOF, void, loc),
			r: (rune, location) => r,
		};
	};

	let base = 10u;
	if (r.0 == '0') {
		append(chars, utf8::encoderune(r.0)...);
		r = match (next(lex)?) {
			io::EOF => return (ltok::LIT_ICONST, 0i64, loc),
			r: (rune, location) => r,
		};
		switch (r.0) {
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
			r: (rune, location) => r,
		};
		if (!strings::contains(basechrs, r.0)) switch (r.0) {
			'.' => if (float || exp is size || suff is size
					|| base != 10) {
				unget(lex, r);
				break;
			} else {
				r = match (next(lex)?) {
					io::EOF => break,
					r: (rune, location) => r,
				};
				if (!strings::contains(basechrs, r.0)) {
					unget(lex, r);
					unget(lex, ('.', location {
						path = r.1.path,
						line = r.1.line,
						col = r.1.col - 1,
					}));
					break;
				};
				unget(lex, r);
				float = true;
				append(chars, utf8::encoderune('.')...);
			},
			'e', 'E' => if (exp is size || suff is size || base != 10) {
				unget(lex, r);
				break;
			} else {
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r.0)...);
				exp = len(chars);
				r = match (next(lex)?) {
					io::EOF => break,
					r: (rune, location) => r,
				};
				switch (r.0) {
					'+', '-' => append(chars,
							utf8::encoderune(r.0)...),
					* => unget(lex, r),
				};
				basechrs = "0123456789";
			},
			'i', 'u', 'f', 'z' => if (suff is size) {
				unget(lex, r);
				break;
			} else {
				suff = len(chars);
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r.0)...);
				basechrs = "0123456789";
			},
			* => {
				unget(lex, r);
				break;
			},
		} else append(chars, utf8::encoderune(r.0)...);
	};
	if (end == 0) end = len(chars);

	let exp = match (exp) {
		void => "0",
		exp: size => {
			let end = match (suff) {
				void => len(chars),
				suff: size => suff,
			};
			strings::fromutf8(chars[exp..end]);
		},
	};
	let exp = match (strconv::stoi(exp)) {
		exp: int => exp,
		strconv::invalid => abort(), // Shouldn't be lexed in
		strconv::overflow =>
			return syntaxerr(loc, "overflow in exponent"),
	};

	let floatend = match (suff) {
		suff: size => suff,
		void => len(chars),
	};
	let suff = match (suff) {
		suff: size => strings::fromutf8(chars[suff..]),
		void => "",
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

	let exp = if (exp < 0) switch (suff) {
		ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST => exp: size,
		* => return syntaxerr(loc,
				"invalid negative exponent of integer"),
	} else exp: size;

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
		ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST => {
			val = strings::fromutf8(chars[..floatend]);
			strconv::stof64(val);
		},
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
		val: f64 => val,
		strconv::invalid => abort(), // Shouldn't be lexed in
		strconv::overflow =>
			return syntaxerr(loc, "overflow in exponent"),
	};

	return (suff, val, loc);
};

fn lex2(lex: *lexer) (token | error) = {
	let first = next(lex)? as (rune, location);
	let second = next(lex)?;
	let loc = first.1;
	let n = match (second) {
		n: (rune, location) => n.0,
		io::EOF => io::EOF,
	};
	let tok: ltok = switch (first.0) {
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
				'/' => return lex_comment(lex),
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
					unget(lex, second);
					unget(lex, first);
					return lex_literal(lex);
				} else {
					ltok::MINUS;
				},
			},
			io::EOF => ltok::MINUS,
		},
		':' => match (second) {
			r: (rune, location) => switch (r.0) {
				':' => return (ltok::DOUBLE_COLON, void, loc),
				* => if (is_name(r.0, false)) {
					unget(lex, second);
					return lex_name(lex, first.1, true)?;
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
	unget(lex, second);
	return (tok, void, loc);
};

fn lex3(lex: *lexer) (token | error) = {
	let r = next(lex)? as (rune, location);
	let toks = switch (r.0) {
		'.' => {
			let tok = if (try(lex, '.') is void) ltok::DOT
				else if (try(lex, '.') is void) ltok::SLICE
				else ltok::ELLIPSIS;
			return (tok, void, r.1);
		},
		'<' => [ltok::LESS, ltok::LESSEQ, ltok::LSHIFT, ltok::LSHIFTEQ],
		'>' => [ltok::GREATER, ltok::GREATEREQ, ltok::RSHIFT,
			ltok::RSHIFTEQ],
		'&' => [ltok::BAND, ltok::BANDEQ, ltok::LAND, ltok::LANDEQ],
		'|' => [ltok::BOR, ltok::BOREQ, ltok::LOR, ltok::LOREQ],
		'^' => [ltok::BXOR, ltok::BXOREQ, ltok::LXOR, ltok::LXOREQ],
		*   => return syntaxerr(r.1, "unknown token sequence"),
	};
	let idx = match (try(lex, r.0, '=')?) {
		void => 0, // X
		n: (rune, location) => switch (n.0) {
			'=' => 1, // X=
			* => match (try(lex, '=')?) {
				void => 2, // XX
				(rune, location) => 3, // XX=
			},
		},
	};
	return (toks[idx], void, r.1);
};

// Unlex a single token. The next call to [[lex]] will return this token. Only one
// unlex is supported at a time; you must call [[lex]] before calling [[unlex]]
// again.
export fn unlex(lex: *lexer, tok: token) void = {
	assert(lex.un is void, "attempted to unlex more than one token");
	lex.un = tok;
};

fn next(lex: *lexer) ((rune, location) | io::EOF | io::error) = {
	match (lex.rb[0]) {
		void => void,
		r: ((rune, location) | io::EOF) => {
			lex.rb[0] = lex.rb[1];
			lex.rb[1] = void;
			return r;
		},
	};

	return match (bufio::scanrune(lex.in)) {
		e: (io::EOF | io::error) => e,
		r: rune => {
			const loc = mkloc(lex);
			let tmp = lex.prevrlocs;
			lex.prevrlocs[1..] = tmp[..len(tmp) - 1];
			lex.prevrlocs[0] = loc;
			lexloc(lex, r);
			return (r, loc);
		},
	};
};

fn nextw(lex: *lexer) ((rune, location) | io::EOF | io::error) = {
	for (true) match (next(lex)) {
		e: (io::error | io::EOF) => return e,
		r: (rune, location) => if (!ascii::isspace(r.0)) {
			return r;
		} else {
			free(lex.comment);
			lex.comment = "";
		},
	};
	abort();
};

fn try(lex: *lexer, want: rune...) ((rune, location) | void | io::error) = {
	let r = match (next(lex)?) {
		io::EOF => return void,
		r: (rune, location) => r,
	};
	assert(len(want) > 0);
	for (let i = 0z; i < len(want); i += 1) {
		if (r.0 == want[i]) {
			return r;
		};
	};
	unget(lex, r);
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

fn unget(lex: *lexer, r: ((rune, location) | io::EOF)) void = {
	if (!(lex.rb[0] is void)) {
		assert(lex.rb[1] is void, "ungot too many runes");
		lex.rb[1] = lex.rb[0];
	};
	lex.rb[0] = r;
};

export fn mkloc(lex: *lexer) location = match (lex.rb[0]) {
	r: (rune, location) => r.1,
	void => location {
		path = lex.path,
		line = lex.loc.0,
		col = lex.loc.1,
	},
};

export fn prevloc(lex: *lexer) location = match (lex.un) {
	t: token => lex.prevunlocs[1].0,
	void => {
		let i = 0z;
		for (i < len(lex.rb); i += 1) if (lex.rb[i] is void) break;
		return lex.prevrlocs[i];
	},
};

fn syntaxerr(loc: location, why: str) error = (loc, why);
