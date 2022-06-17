// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Sudipto Mallick <smlckz@disroot.org>
use ascii;
use bufio;
use encoding::utf8;
use fmt;
use io;
use sort;
use strconv;
use strings;
use strio;

export type lexer = struct {
	in: io::handle,
	path: str,
	loc: (uint, uint),
	un: (token | void),
	rb: [2]((rune, location) | io::EOF | void),
	// 1 more than the size of un and rb respectively
	prevunlocs: [2](location, location),
	prevrlocs: [3]location,
	flags: flags,
	comment: str,
	require_int: bool,
};

// Flags which apply to this lexer
export type flags = enum uint {
	NONE = 0,
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
	match (err) {
	case let err: io::error =>
		return io::strerror(err);
	case let s: syntax =>
		return fmt::bsprintf(buf, "{}:{},{}: Syntax error: {}",
			s.0.path, s.0.line, s.0.col, s.1);
	};
};

// Initializes a new lexer for the given input. The path is borrowed.
export fn init(in: io::handle, path: str, flags: flags...) lexer = {
	let f = flags::NONE;
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
		...
	};
};

// Returns the current value of the comment buffer, or empty string if unset (or
// if [[flags::COMMENTS]] was not enabled for this lexer).
export fn comment(lex: *lexer) str = lex.comment;

// Returns the next token from the lexer.
export fn lex(lex: *lexer) (token | error) = {
	match (lex.un) {
	case let tok: token =>
		lex.un = void;
		return tok;
	case void => void;
	};

	defer {
		lex.prevunlocs[1] = lex.prevunlocs[0];
		lex.prevunlocs[0] = (prevloc(lex), mkloc(lex));
	};

	let r = match (nextw(lex)?) {
	case io::EOF =>
		return (ltok::EOF, void, mkloc(lex));
	case let r: (rune, location) =>
		yield r;
	};

	if (ascii::isdigit(r.0)) {
		unget(lex, r);
		return lex_literal(lex);
	};

	lex.require_int = false;
	if (is_name(r.0, false)) {
		unget(lex, r);
		return lex_name(lex, r.1);
	};

	let tok = switch (r.0) {
	case '"', '\'', '`' =>
		unget(lex, r);
		return lex_rn_str(lex);
	case '.', '<', '>', '&', '|', '^' =>
		unget(lex, r);
		return lex3(lex);
	case '*', '%', '/', '+', '-', ':', '!', '=' =>
		unget(lex, r);
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
		buf[i] = r: u32: u8;
	};
	let s = strings::fromutf8_unsafe(buf[..n]);
	return strconv::stou32b(s, strconv::base::HEX) as u32: rune;
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
	};
};

fn lex_string(lex: *lexer, loc: location, delim: rune) (token | error) = {
	let ret: token = (ltok::LIT_STR, "", loc);
	let buf = strio::dynamic();
	for (true) match (next(lex)?) {
	case io::EOF =>
		return syntaxerr(loc, "unexpected EOF scanning string literal");
	case let r: (rune, location) =>
		if (r.0 == delim) break
		else if (delim == '"') {
			unget(lex, r);
			let r = lex_rune(lex, loc)?;
			strio::appendrune(&buf, r)?;
		} else {
			strio::appendrune(&buf, r.0)?;
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
			strio::concat(&buf, next)!;
			free(next);
			break;
		case '/' =>
			match (nextw(lex)?) {
			case io::EOF =>
				unget(lex, r);
			case let s: (rune, location) =>
				if (s.0 == '/') {
					lex_comment(lex)?;
					continue;
				} else {
					unget(lex, s);
					unget(lex, r);
				};
			};
			break;
		case =>
			unget(lex, r);
			break;
		};
	};
	return (ltok::LIT_STR, strio::string(&buf), loc);
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
	let ret: token = (ltok::LIT_RUNE, lex_rune(lex, loc)?, loc);
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
	let buf = strio::dynamic();
	match (next(lex)) {
	case let r: (rune, location) =>
		assert(is_name(r.0, false));
		strio::appendrune(&buf, r.0)!;
	case (io::EOF | io::error) =>
		abort();
	};

	for (true) match (next(lex)?) {
	case io::EOF => break;
	case let r: (rune, location) =>
		if (!is_name(r.0, true)) {
			unget(lex, r);
			break;
		};
		strio::appendrune(&buf, r.0)?;
	};

	line_comment(lex)?;

	let n = strio::string(&buf);

	match (sort::searchstrings(bmap[..ltok::LAST_KEYWORD+1], n)) {
	case void =>
		return (ltok::NAME, n, loc);
	case let i: size =>
		free(n);
		return (i: ltok, void, loc);
	};
};

fn line_comment(lex: *lexer) (void | error) = {
	if (lex.flags & flags::COMMENTS != flags::COMMENTS) {
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
		};
	};

	if (try(lex, '/')? is void) {
		unget(lex, r);
		return;
	};

	free(lex.comment);
	lex.comment = "";
	lex_comment(lex)?;
};

fn lex_comment(lexr: *lexer) (void | error) = {
	if (lexr.flags & flags::COMMENTS != flags::COMMENTS) {
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

	let buf = strio::dynamic();
	defer io::close(&buf)!;
	for (true) match (next(lexr)?) {
	case io::EOF =>
		break;
	case let r: (rune, location) =>
		strio::appendrune(&buf, r.0)!;
		if (r.0 == '\n') {
			break;
		};
	};
	let bytes = strings::toutf8(lexr.comment);
	append(bytes, strings::toutf8(strio::string(&buf))...);
	lexr.comment = strings::fromutf8(bytes);
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
	let base = 10u;
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
			base = 2;
		case 'o' =>
			base = 8;
		case 'x' =>
			base = 16;
		case =>
			started = true;
			unget(lex, r);
		};
	} else unget(lex, r);
	let basechrs = switch (base) {
	case 2 =>
		yield "01";
	case 8 =>
		yield "01234567";
	case 10 =>
		yield "0123456789";
	case 16 =>
		yield "0123456789ABCDEFabcdef";
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
					|| base != 10 || lex.require_int) {
				unget(lex, r);
				break;
			} else {
				r = match (next(lex)?) {
				case io::EOF =>
					break;
				case let r: (rune, location) =>
					yield r;
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
			};
		case 'e', 'E' =>
			if (!started) {
				return syntaxerr(loc,
					"Expected integer literal");
			};
			if (exp is size || suff is size || base != 10) {
				unget(lex, r);
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
					unget(lex, r);
				};
				basechrs = "0123456789";
			};
		case 'i', 'u', 'f', 'z' =>
			if (!started) {
				return syntaxerr(loc,
					"Expected integer literal");
			};
			if (suff is size || r.0 != 'f' && float
					|| r.0 == 'f' && base != 10) {
				unget(lex, r);
				break;
			} else {
				suff = len(chars);
				if (end == 0) end = len(chars);
				append(chars, utf8::encoderune(r.0)...);
				basechrs = "0123456789";
			};
		case =>
			unget(lex, r);
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
		yield strings::fromutf8(chars[exp..end]);
	};
	let exp = match (strconv::stoi(exp)) {
	case let exp: int =>
		yield exp;
	case strconv::invalid =>
		abort(); // Shouldn't be lexed in
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
		yield strings::fromutf8(chars[suff..]);
	case void =>
		yield "";
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
		else if (suff == "" && !float && exp >= 0) ltok::LIT_ICONST
		else if (suff == "f32") ltok::LIT_F32
		else if (suff == "f64") ltok::LIT_F64
		else if (suff == "" && (float || exp < 0)) ltok::LIT_FCONST
		else return syntaxerr(loc, "invalid literal suffix");

	let exp = if (exp < 0) switch (suff) {
		case ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST =>
			yield exp: size;
		case => return syntaxerr(loc,
				"invalid negative exponent of integer");
	} else exp: size;

	let val = strings::fromutf8(chars[..end]);
	let val = switch (suff) {
	case ltok::LIT_F32, ltok::LIT_F64, ltok::LIT_FCONST =>
		val = strings::fromutf8(chars[..floatend]);
		yield strconv::stof64(val);
	case =>
		yield strconv::stou64b(val, base);
	};
	let val = match (val) {
	case let val: u64 =>
		for (let i = 0z; i < exp; i += 1) {
			val *= 10;
		};
		yield val;
	case let val: f64 =>
		yield val;
	case strconv::invalid =>
		abort(); // Shouldn't be lexed in
	case strconv::overflow =>
		return syntaxerr(loc, "overflow in exponent");
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
				unget(lexr, r);
				return (ltok::DIV, void, first.1);
			};
		case io::EOF =>
			return (ltok::DIV, void, first.1);
		};
	case '+' =>
		yield (ltok::PLUS, [('=', ltok::PLUSEQ)]);
	case '-' =>
		match (next(lexr)?) {
		case let r: (rune, location) =>
			switch (r.0) {
			case '=' =>
				line_comment(lexr)?;
				return (ltok::MINUSEQ, void, first.1);
			case =>
				unget(lexr, r);
				line_comment(lexr)?;
				return (ltok::MINUS, void, first.1);
			};
		case io::EOF =>
			return (ltok::MINUS, void, first.1);
		};
	case ':' =>
		match (next(lexr)?) {
		case let r: (rune, location) =>
			switch (r.0) {
			case ':' =>
				line_comment(lexr)?;
				return (ltok::DOUBLE_COLON, void, first.1);
			case =>
				unget(lexr, r);
				line_comment(lexr)?;
				return (ltok::COLON, void, first.1);
			};
		case io::EOF =>
			return (ltok::COLON, void, first.1);
		};
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
		unget(lexr, r);
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
			yield ltok::SLICE;
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
	assert(lex.un is void, "attempted to unlex more than one token");
	lex.un = tok;
};

fn next(lex: *lexer) ((rune, location) | syntax | io::EOF | io::error) = {
	match (lex.rb[0]) {
	case void => void;
	case let r: ((rune, location) | io::EOF) =>
		lex.rb[0] = lex.rb[1];
		lex.rb[1] = void;
		return r;
	};

	match (bufio::scanrune(lex.in)) {
	case let e: (io::EOF | io::error) =>
		return e;
	case let r: rune =>
		const loc = mkloc(lex);
		let tmp = lex.prevrlocs;
		lex.prevrlocs[1..] = tmp[..len(tmp) - 1];
		lex.prevrlocs[0] = loc;
		lexloc(lex, r);
		return (r, loc);
	case utf8::invalid =>
		return syntaxerr(mkloc(lex), "Source file is not valid UTF-8");
	};
};

fn nextw(lex: *lexer) ((rune, location) | io::EOF | io::error) = {
	for (true) match (next(lex)) {
	case let e: (io::error | io::EOF) =>
		return e;
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
	abort();
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
	unget(lex, r);
};

fn lexloc(lex: *lexer, r: rune) void = {
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

fn unget(lex: *lexer, r: ((rune, location) | io::EOF)) void = {
	if (!(lex.rb[0] is void)) {
		assert(lex.rb[1] is void, "ungot too many runes");
		lex.rb[1] = lex.rb[0];
	};
	lex.rb[0] = r;
};

export fn mkloc(lex: *lexer) location = {
	match (lex.un) {
	case let t: token =>
		return lex.prevunlocs[1].1;
	case void =>
		match (lex.rb[0]) {
		case let r: (rune, location) =>
			return r.1;
		case void =>
			return location {
				path = lex.path,
				line = lex.loc.0,
				col = lex.loc.1,
			};
		};
	};
};

export fn prevloc(lex: *lexer) location = {
	match (lex.un) {
	case let t: token =>
		return lex.prevunlocs[1].0;
	case void =>
		let i = 0z;
		for (i < len(lex.rb); i += 1) if (lex.rb[i] is void) break;
		return lex.prevrlocs[i];
	};
};

fn syntaxerr(loc: location, why: str) error = (loc, why);
