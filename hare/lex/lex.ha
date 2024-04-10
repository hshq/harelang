// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use encoding::utf8;
use fmt;
use io;
use memio;
use os;
use path;
use sort;
use sort::cmp;
use strconv;
use strings;
use types;

export type lexer = struct {
	in: *bufio::scanner,
	path: str,
	loc: (uint, uint),
	prevrloc: (uint, uint),
	un: token, // ltok::EOF when no token was unlexed
	prevunlocs: [2]((uint, uint), (uint, uint)),
	flags: flag,
	comment: str,
	require_int: bool,
};

// Flags which apply to this lexer
export type flag = enum uint {
	NONE = 0,
	// Enables lexing comments
	COMMENTS = 1 << 0,
};

// A syntax error
export type syntax = !(location, str);

// All possible lexer errors
export type error = !(io::error | syntax);

// Returns a human-friendly string for a given error. The result may be
// statically allocated.
export fn strerror(err: error) const str = {
	static let buf: [2048]u8 = [0...];
	match (err) {
	case let err: io::error =>
		return io::strerror(err);
	case let s: syntax =>
		return fmt::bsprintf(buf, "{}:{}:{}: syntax error: {}",
			s.0.path, s.0.line, s.0.col, s.1);
	};
};

// Initializes a new lexer for the given [[bufio::scanner]]. The path is
// borrowed.
export fn init(
	in: *bufio::scanner,
	path: str,
	flags: flag = flag::NONE,
) lexer = {
	const loc = location { path = path, line = 1, col = 1 };
	return lexer {
		in = in,
		path = path,
		loc = (1, 1),
		prevrloc = (1, 1),
		un = (ltok::EOF, void, loc),
		prevunlocs = [((1, 1), (1, 1))...],
		flags = flags,
		...
	};
};

// Returns the current value of the comment buffer, or empty string if unset (or
// if [[flag::COMMENTS]] was not enabled for this lexer).
export fn comment(lex: *lexer) str = lex.comment;

// Returns the next token from the lexer.
export fn lex(lex: *lexer) (token | error) = {
	if (lex.un.0 != ltok::EOF) {
		defer lex.un.0 = ltok::EOF;
		return lex.un;
	};

	defer {
		lex.prevunlocs[1] = lex.prevunlocs[0];
		const prev = prevloc(lex);
		const loc = mkloc(lex);
		lex.prevunlocs[0] = (
			(prev.line, prev.col),
			(loc.line, loc.col),
		);
	};

	let r = match (nextw(lex)?) {
	case io::EOF =>
		return (ltok::EOF, void, mkloc(lex));
	case let r: (rune, location) =>
		yield r;
	};

	if (ascii::isdigit(r.0)) {
		unget(lex, r.0);
		return lex_literal(lex);
	};

	lex.require_int = false;
	if (is_name(r.0, false)) {
		unget(lex, r.0);
		return lex_name(lex, r.1);
	};

	let tok = switch (r.0) {
	case '"', '\'', '`' =>
		unget(lex, r.0);
		return lex_rn_str(lex);
	case '.', '<', '>', '&', '|', '^' =>
		unget(lex, r.0);
		return lex3(lex);
	case '*', '%', '/', '+', '-', ':', '!', '=' =>
		unget(lex, r.0);
		return lex2(lex);
	case '~' =>
		yield ltok::BNOT;
	case ',' =>
		yield ltok::COMMA;
	case '{' =>
		yield ltok::LBRACE;
	case '[' =>
		yield ltok::LBRACKET;
	case '(' =>
		yield ltok::LPAREN;
	case '}' =>
		yield ltok::RBRACE;
	case ']' =>
		yield ltok::RBRACKET;
	case ')' =>
		yield ltok::RPAREN;
	case ';' =>
		yield ltok::SEMICOLON;
	case '?' =>
		yield ltok::QUESTION;
	case =>
		return syntaxerr(r.1, "invalid character");
	};

	line_comment(lex)?;
	return (tok, void, r.1);
};

fn is_name(r: rune, num: bool) bool =
	ascii::isalpha(r) || r == '_' || r == '@' || (num && ascii::isdigit(r));

fn lex_unicode(lex: *lexer, loc: location, n: size) (rune | error) = {
	assert(n < 9);
	let buf: [8]u8 = [0...];
	for (let i = 0z; i < n; i += 1z) {
		let r = match (next(lex)?) {
		case io::EOF =>
			return syntaxerr(loc,
				"unexpected EOF scanning for escape");
		case let r: (rune, location) =>
			yield r.0;
		};
		if (!ascii::isxdigit(r)) {
			return syntaxerr(loc,
				"unexpected rune scanning for escape");
		};
		buf[i] = r: u8;
	};
	let s = strings::fromutf8_unsafe(buf[..n]);
	return strconv::stou32(s, strconv::base::HEX) as u32: rune;
};

fn lex_rune(lex: *lexer, loc: location) (rune | error) = {
	let r = match (next(lex)?) {
	case io::EOF =>
		return syntaxerr(loc, "unexpected EOF scanning for rune");
	case let r: (rune, location) =>
		yield r.0;
	};
	if (r != '\\') {
		return r;
	};
	r = match (next(lex)?) {
	case io::EOF =>
		return syntaxerr(loc, "unexpected EOF scanning for escape");
	case let r: (rune, location) =>
		yield r.0;
	};
	switch (r) {
	case '\\' =>
		return '\\';
	case '\'' =>
		return '\'';
	case '0' =>
		return '\0';
	case 'a' =>
		return '\a';
	case 'b' =>
		return '\b';
	case 'f' =>
		return '\f';
	case 'n' =>
		return '\n';
	case 'r' =>
		return '\r';
	case 't' =>
		return '\t';
	case 'v' =>
		return '\v';
	case '"' =>
		return '\"';
	case 'x' =>
		return lex_unicode(lex, loc, 2);
	case 'u' =>
		return lex_unicode(lex, loc, 4);
	case 'U' =>
		return lex_unicode(lex, loc, 8);
	case =>
		return syntaxerr(mkloc(lex), "unknown escape sequence");
	};
};

fn lex_string(lex: *lexer, loc: location, delim: rune) (token | error) = {
	let ret: token = (ltok::LIT_STR, "", loc);
	let buf = memio::dynamic();
	for (true) match (next(lex)?) {
	case io::EOF =>
		return syntaxerr(loc, "unexpected EOF scanning string literal");
	case let r: (rune, location) =>
		if (r.0 == delim) break
		else if (delim == '"' && r.0 == '\\') {
			unget(lex, r.0);
			let r = lex_rune(lex, loc)?;
			memio::appendrune(&buf, r)?;
		} else {
			memio::appendrune(&buf, r.0)?;
		};
	};
	for (true) match (nextw(lex)?) {
	case io::EOF =>
		break;
	case let r: (rune, location) =>
		switch (r.0) {
		case '"', '`' =>
			const tok = lex_string(lex, loc, r.0)?;
			const next = tok.1 as str;
			memio::concat(&buf, next)!;
			free(next);
			break;
		case '/' =>
			match (nextw(lex)?) {
			case io::EOF =>
				unget(lex, r.0);
			case let s: (rune, location) =>
				if (s.0 == '/') {
					lex_comment(lex)?;
					continue;
				} else {
					unget(lex, s.0);
					unget(lex, r.0);
				};
			};
			break;
		case =>
			unget(lex, r.0);
			break;
		};
	};
	return (ltok::LIT_STR, memio::string(&buf)!, loc);
};

fn lex_rn_str(lex: *lexer) (token | error) = {
	const loc = mkloc(lex);
	let r = match (next(lex)) {
	case let r: (rune, location) =>
		yield r.0;
	case (io::EOF | io::error) =>
		abort();
	};
	switch (r) {
	case '\'' => void;
	case '\"', '`' =>
		return lex_string(lex, loc, r);
	case =>
		abort(); // Invariant
	};

	// Rune literal
	let ret: token = (ltok::LIT_RCONST, lex_rune(lex, loc)?, loc);
	match (next(lex)?) {
	case io::EOF =>
		return syntaxerr(loc, "unexpected EOF");
	case let n: (rune, location) =>
		if (n.0 != '\'') {
			return syntaxerr(n.1, "expected \"\'\"");
		};
	};
	line_comment(lex)?;
	return ret;
};

fn lex_name(lex: *lexer, loc: location) (token | error) = {
	let buf = memio::dynamic();
	match (next(lex)) {
	case let r: (rune, location) =>
		assert(is_name(r.0, false));
		memio::appendrune(&buf, r.0)!;
	case (io::EOF | io::error) =>
		abort();
	};

	for (true) match (next(lex)?) {
	case io::EOF => break;
	case let r: (rune, location) =>
		if (!is_name(r.0, true)) {
			unget(lex, r.0);
			break;
		};
		memio::appendrune(&buf, r.0)?;
	};

	line_comment(lex)?;

	let n = memio::string(&buf)!;

	match (sort::search(bmap[..ltok::LAST_KEYWORD+1],
		size(str), &n, &cmp::strs)) {
	case void =>
		return (ltok::NAME, n, loc);
	case let i: size =>
		free(n);
		return (i: ltok, void, loc);
	};
};

fn line_comment(lex: *lexer) (void | error) = {
	if (lex.flags & flag::COMMENTS != flag::COMMENTS) {
		return;
	};

	let r: (rune, location) = ('\0', location { ... });
	for (true) match (try(lex, '\t', ' ', '/')?) {
	case void =>
		return;
	case let v: (rune, location) =>
		switch (v.0) {
		case '\t', ' ' => void;
		case '/' =>
			r = v;
			break;
		case => abort(); // unreachable
		};
	};

	if (try(lex, '/')? is void) {
		unget(lex, r.0);
		return;
	};

	free(lex.comment);
	lex.comment = "";
	lex_comment(lex)?;
};

fn lex_comment(lexr: *lexer) (void | error) = {
	if (lexr.flags & flag::COMMENTS != flag::COMMENTS) {
		for (true) match (next(lexr)?) {
		case io::EOF =>
			break;
		case let r: (rune, location) =>
			if (r.0 == '\n') {
				break;
			};
		};
		return;
	};

	let buf = memio::dynamic();
	defer io::close(&buf)!;
	for (true) match (next(lexr)?) {
	case io::EOF =>
		break;
	case let r: (rune, location) =>
		memio::appendrune(&buf, r.0)!;
		if (r.0 == '\n') {
			break;
		};
	};
	let bytes = strings::toutf8(lexr.comment);
	append(bytes, strings::toutf8(memio::string(&buf)!)...);
	lexr.comment = strings::fromutf8(bytes)!;
};

fn lex_literal(lex: *lexer) (token | error) = {
	const loc = mkloc(lex);
	let chars: []u8 = [];
	let r = match (next(lex)?) {
	case io::EOF =>
		return (ltok::EOF, void, loc);
	case let r: (rune, location) =>
		yield r;
	};

	let started = false;
	let base = strconv::base::DEC;
	if (r.0 == '0') {
		append(chars, utf8::encoderune(r.0)...);
		r = match (next(lex)?) {
		case io::EOF =>
			return (ltok::LIT_ICONST, 0u64, loc);
		case let r: (rune, location) =>
			yield r;
		};
		switch (r.0) {
		case 'b' =>
			base = strconv::base::BIN;
		case 'o' =>
			base = strconv::base::OCT;
		case 'x' =>
			base = strconv::base::HEX;
		case =>
			if (ascii::isdigit(r.0)) {
				return syntaxerr(loc,
					"Leading zeros in number literals aren't permitted (for octal, use the 0o prefix instead)");
			};
			started = true;
			unget(lex, r.0);
		};
	} else unget(lex, r.0);
	let basechrs = switch (base) {
	case strconv::base::BIN =>
		yield "01";
	case strconv::base::OCT =>
		yield "01234567";
	case strconv::base::DEC =>
		yield "0123456789";
	case strconv::base::HEX =>
		yield "0123456789ABCDEFabcdef";
	case => abort(); // unreachable
	};

	let suff: (size | void) = void;
	let exp: (size | void) = void;
	let end = 0z;
	let float = false;
	for (true) {
		r = match (next(lex)?) {
		case io::EOF =>
			break;
		case let r: (rune, location) =>
			yield r;
		};
		if (!strings::contains(basechrs, r.0)) switch (r.0) {
		case '.' =>
			if (!started) {
				return syntaxerr(loc,
					"Expected integer literal");
			};
			if (float || exp is size || suff is size
					|| lex.require_int) {
				unget(lex, r.0);
				break;
			} else {
				r = match (next(lex)?) {
				case io::EOF =>
					break;
				case let r: (rune, location) =>
					yield r;
				};
				if (!strings::contains(basechrs, r.0)) {
					unget(lex, r.0);
					unget(lex, '.');
					break;
				};
				unget(lex, r.0);
				float = true;
				append(chars, utf8::encoderune('.')...);
			};
		case 'e', 'E', 'p', 'P' =>
			if (!started) {
				return syntaxerr(loc,
					"Expected integer literal");
			};
			if ((r.0 == 'e' || r.0 == 'E') !=
					(base == strconv::base::DEC)) {
				unget(lex, r.0);
				break;
			};
			if (exp is size || suff is size) {
				unget(lex, r.0);
				break;
			} else {
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r.0)...);
				exp = len(chars);
				r = match (next(lex)?) {
				case io::EOF =>
					break;
				case let r: (rune, location) =>
					yield r;
				};
				switch (r.0) {
				case '+', '-' =>
					append(chars, utf8::encoderune(r.0)...);
				case =>
					unget(lex, r.0);
				};
				basechrs = "0123456789";
			};
		case 'i', 'u', 'f', 'z' =>
			if (!started) {
				return syntaxerr(loc,
					"Expected integer literal");
			};
			if (suff is size || r.0 != 'f' && float
					|| r.0 == 'f'
					&& base != strconv::base::DEC) {
				unget(lex, r.0);
				break;
			} else {
				suff = len(chars);
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r.0)...);
				basechrs = "0123456789";
			};
		case =>
			unget(lex, r.0);
			break;
		} else append(chars, utf8::encoderune(r.0)...);
		started = true;
	};
	if (!started) {
		return syntaxerr(loc, "expected integer literal");
	};
	if (end == 0) end = len(chars);
	lex.require_int = false;

	let exp = match (exp) {
	case void =>
		yield "0";
	case let exp: size =>
		let end = match (suff) {
		case void =>
			yield len(chars);
		case let suff: size =>
			yield suff;
		};
		yield strings::fromutf8(chars[exp..end])!;
	};
	let exp = match (strconv::stoi(exp)) {
	case let exp: int =>
		yield exp;
	case strconv::invalid =>
		return syntaxerr(mkloc(lex), "expected exponent");
	case strconv::overflow =>
		return syntaxerr(loc, "overflow in exponent");
	};

	let floatend = match (suff) {
	case let suff: size =>
		yield suff;
	case void =>
		yield len(chars);
	};
	let suff = match (suff) {
	case let suff: size =>
		yield strings::fromutf8(chars[suff..])!;
	case void =>
		yield "";
	};
	let (suff, signed) = if (suff == "u8") (ltok::LIT_U8, false)
		else if (suff == "u16") (ltok::LIT_U16, false)
		else if (suff == "u32") (ltok::LIT_U32, false)
		else if (suff == "u64") (ltok::LIT_U64, false)
		else if (suff == "u") (ltok::LIT_UINT, false)
		else if (suff == "z") (ltok::LIT_SIZE, false)
		else if (suff == "i8") (ltok::LIT_I8, true)
		else if (suff == "i16") (ltok::LIT_I16, true)
		else if (suff == "i32") (ltok::LIT_I32, true)
		else if (suff == "i64") (ltok::LIT_I64, true)
		else if (suff == "i") (ltok::LIT_INT, true)
		else if (suff == "" && !float && exp >= 0) (ltok::LIT_ICONST, false)
		else if (suff == "f32") (ltok::LIT_F32, false)
		else if (suff == "f64") (ltok::LIT_F64, false)
		else if (suff == "" && (float || exp < 0)) (ltok::LIT_FCONST, false)
		else return syntaxerr(loc, "invalid literal suffix");

	let exp = if (exp < 0) switch (suff) {
		case ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST =>
			yield exp: size;
		case => return syntaxerr(loc,
				"invalid negative exponent of integer");
	} else exp: size;

	let val = strings::fromutf8(chars[..end])!;
	let val = switch (suff) {
	case ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST =>
		val = strings::fromutf8(chars[..floatend])!;
		yield strconv::stof64(val, base);
	case =>
		yield strconv::stou64(val, base);
	};
	let val = match (val) {
	case let val: u64 =>
		for (let i = 0z; i < exp; i += 1) {
			let old = val;
			val *= 10;
			if (val / 10 != old) {
				return syntaxerr(loc, "overflow in exponent");
			};
		};
		if (signed && val > types::I64_MIN: u64) {
			return syntaxerr(loc, "overflow in exponent");
		};
		yield val;
	case let val: f64 =>
		yield val;
	case strconv::invalid =>
		abort(); // Shouldn't be lexed in
	case strconv::overflow =>
		return syntaxerr(loc, "literal overflow");
	};

	line_comment(lex)?;
	return (suff, val, loc);
};

fn lex2(lexr: *lexer) (token | error) = {
	let first = next(lexr)? as (rune, location);
	let tok: (ltok, [](rune, ltok)) = switch (first.0) {
	case '*' =>
		yield (ltok::TIMES, [('=', ltok::TIMESEQ)]);
	case '%' =>
		yield (ltok::MODULO, [('=', ltok::MODEQ)]);
	case '/' =>
		match (next(lexr)?) {
		case let r: (rune, location) =>
			switch (r.0) {
			case '=' =>
				line_comment(lexr)?;
				return (ltok::DIVEQ, void, first.1);
			case '/' =>
				lex_comment(lexr)?;
				return lex(lexr);
			case =>
				unget(lexr, r.0);
				return (ltok::DIV, void, first.1);
			};
		case io::EOF =>
			return (ltok::DIV, void, first.1);
		};
	case '+' =>
		yield (ltok::PLUS, [('=', ltok::PLUSEQ)]);
	case '-' =>
		yield (ltok::MINUS, [('=', ltok::MINUSEQ)]);
	case ':' =>
		yield (ltok::COLON, [(':', ltok::DOUBLE_COLON)]);
	case '!' =>
		yield (ltok::LNOT, [('=', ltok::NEQUAL)]);
	case '=' =>
		yield (ltok::EQUAL, [('=', ltok::LEQUAL), ('>', ltok::ARROW)]);
	case =>
		return syntaxerr(first.1, "unknown token sequence");
	};
	match (next(lexr)?) {
	case let r: (rune, location) =>
		for (let i = 0z; i < len(tok.1); i += 1) {
			if (tok.1[i].0 == r.0) {
				line_comment(lexr)?;
				return (tok.1[i].1, void, first.1);
			};
		};
		unget(lexr, r.0);
		line_comment(lexr)?;
	case io::EOF => void;
	};
	return (tok.0, void, first.1);
};

fn lex3(lex: *lexer) (token | error) = {
	let r = next(lex)? as (rune, location);
	let toks = switch (r.0) {
	case '.' =>
		let tok = if (try(lex, '.')? is void) {
			lex.require_int = true;
			yield ltok::DOT;
		} else if (try(lex, '.')? is void) {
			yield ltok::DOUBLE_DOT;
		} else ltok::ELLIPSIS;
		line_comment(lex)?;
		return (tok, void, r.1);
	case '<' =>
		yield [ltok::LESS, ltok::LESSEQ, ltok::LSHIFT, ltok::LSHIFTEQ];
	case '>' =>
		yield [ltok::GT, ltok::GTEQ, ltok::RSHIFT,
			ltok::RSHIFTEQ];
	case '&' =>
		yield [ltok::BAND, ltok::BANDEQ, ltok::LAND, ltok::LANDEQ];
	case '|' =>
		yield [ltok::BOR, ltok::BOREQ, ltok::LOR, ltok::LOREQ];
	case '^' =>
		yield [ltok::BXOR, ltok::BXOREQ, ltok::LXOR, ltok::LXOREQ];
	case =>
		return syntaxerr(r.1, "unknown token sequence");
	};
	let idx = match (try(lex, r.0, '=')?) {
	case void =>
		yield 0; // X
	case let n: (rune, location) =>
		yield switch (n.0) {
		case '=' =>
			yield 1; // X=
		case =>
			yield match (try(lex, '=')?) {
			case void =>
				yield 2; // XX
			case (rune, location) =>
				yield 3; // XX=
			};
		};
	};
	line_comment(lex)?;
	return (toks[idx], void, r.1);
};

// Unlex a single token. The next call to [[lex]] will return this token. Only one
// unlex is supported at a time; you must call [[lex]] before calling [[unlex]]
// again.
export fn unlex(lex: *lexer, tok: token) void = {
	assert(lex.un.0 == ltok::EOF, "attempted to unlex more than one token");
	lex.un = tok;
};

fn next(lex: *lexer) ((rune, location) | syntax | io::EOF | io::error) = {
	match (bufio::scan_rune(lex.in)) {
	case let e: (io::EOF | io::error) =>
		return e;
	case let r: rune =>
		const loc = mkloc(lex);
		lexloc(lex, r);
		return (r, loc);
	case utf8::invalid =>
		return syntaxerr(mkloc(lex), "Source file is not valid UTF-8");
	};
};

fn nextw(lex: *lexer) ((rune, location) | io::EOF | error) = {
	for (true) match (next(lex)?) {
	case io::EOF =>
		return io::EOF;
	case let r: (rune, location) =>
		if (ascii::isspace(r.0)) {
			if (r.0 == '\n') {
				free(lex.comment);
				lex.comment = "";
			};
			continue;
		};
		if (!is_name(r.0, true) && r.0 != '/') {
			free(lex.comment);
			lex.comment = "";
		};
		return r;
	};
};

fn try(
	lex: *lexer,
	want: rune...
) ((rune, location) | syntax | void | io::error) = {
	let r = match (next(lex)?) {
	case io::EOF =>
		return;
	case let r: (rune, location) =>
		yield r;
	};
	assert(len(want) > 0);
	for (let i = 0z; i < len(want); i += 1) {
		if (r.0 == want[i]) {
			return r;
		};
	};
	unget(lex, r.0);
};

fn unget(lex: *lexer, r: rune) void = {
	bufio::unreadrune(lex.in, r);

	// here, we set the current location to the previous location, then
	// subtract one from the previous location's column. this is always
	// correct, even for tabs and newlines, since a tab or newline will
	// never be ungot after a previous unget call. besides tabs and
	// newlines, the rune will always be a printable ASCII character
	assert(ascii::isprint(r) || r == '\t' || r == '\n');
	assert(r != '\n' || lex.prevrloc.0 == lex.loc.0 - 1);

	lex.loc = lex.prevrloc;
	lex.prevrloc.1 -= 1;
};

fn lexloc(lex: *lexer, r: rune) void = {
	lex.prevrloc = lex.loc;
	switch (r) {
	case '\n' =>
		lex.loc.0 += 1;
		lex.loc.1 = 1;
	case '\t' =>
		lex.loc.1 += 8 - lex.loc.1 % 8 + 1;
	case =>
		lex.loc.1 += 1;
	};
};

export fn mkloc(lex: *lexer) location = {
	const loc = if (lex.un.0 == ltok::EOF) lex.loc
		else lex.prevunlocs[1].1;
	return location {
		path = lex.path,
		line = loc.0,
		col = loc.1,
	};
};

export fn prevloc(lex: *lexer) location = {
	const loc = if (lex.un.0 == ltok::EOF) lex.prevrloc
		else lex.prevunlocs[1].0;
	return location {
		path = lex.path,
		line = loc.0,
		col = loc.1,
	};
};

export fn syntaxerr(loc: location, why: str) error = {
	static let buf = path::buffer{...};
	path::set(&buf, loc.path)!;
	loc.path = path::string(&buf);
	return (loc, why);
};
