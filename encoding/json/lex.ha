// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use ascii;
use bufio;
use encoding::utf8;
use io;
use os;
use strconv;
use strings;
use strio;

export type lexer = struct {
	src: io::handle,
	buffer: []u8,
	strbuf: strio::stream,
	un: (token | void),
	rb: (rune | void),
	loc: (uint, uint),
	prevloc: (uint, uint),
	nextloc: (uint, uint),
	prevrloc: (uint, uint),
};

// Creates a new JSON lexer. The caller may obtain tokens with [[lex]] and
// should pass the result to [[close]] when they're done with it.
export fn newlexer(src: io::handle) lexer = {
	let buf: []u8 = alloc([0...], os::BUFSIZ);
	return lexer {
		src = src,
		buffer = buf,
		strbuf = strio::dynamic(),
		un = void,
		rb = void,
		loc = (1, 0),
		...
	};
};

// Frees state associated with a JSON lexer.
export fn close(lex: *lexer) void = {
	free(lex.buffer);
};

// Returns the next token from a JSON lexer. The return value is borrowed from
// the lexer and will be overwritten on subsequent calls.
export fn lex(lex: *lexer) (token | io::EOF | error) = {
	match (lex.un) {
	case void =>
		lex.prevloc = lex.loc;
	case let tok: token =>
		lex.un = void;
		lex.prevloc = lex.loc;
		lex.loc = lex.nextloc;
		return tok;
	};

	const rn = match (nextrunews(lex)?) {
	case io::EOF =>
		return io::EOF;
	case let rn: rune =>
		yield rn;
	};

	switch (rn) {
	case '[' =>
		return arraystart;
	case ']' =>
		return arrayend;
	case '{' =>
		return objstart;
	case '}' =>
		return objend;
	case ',' =>
		return comma;
	case ':' =>
		return colon;
	case '"' =>
		return scan_str(lex)?;
	case =>
		yield;
	};

	if (ascii::isdigit(rn) || rn == '-') {
		unget(lex, rn);
		return scan_number(lex)?;
	};

	if (!ascii::isalpha(rn)) {
		return lex.loc: invalid;
	};

	unget(lex, rn);
	const word = scan_word(lex)?;
	switch (word) {
	case "true" =>
		return true;
	case "false" =>
		return false;
	case "null" =>
		return _null;
	case =>
		return lex.loc: invalid;
	};
};

// "Unlexes" a token from the lexer, such that the next call to [[lex]] will
// return that token again. Only one token can be unlexed at a time, otherwise
// the program will abort.
export fn unlex(lex: *lexer, tok: token) void = {
	assert(lex.un is void, "encoding::json::unlex called twice in a row");
	lex.un = tok;
	lex.nextloc = lex.loc;
	lex.loc = lex.prevloc;
};

// Scans until encountering a non-alphabetical character, returning the
// resulting word.
fn scan_word(lex: *lexer) (str | error) = {
	strio::reset(&lex.strbuf);

	for (true) {
		const rn = match (nextrune(lex)?) {
		case let rn: rune =>
			yield rn;
		case io::EOF =>
			break;
		};
		if (!ascii::isalpha(rn)) {
			unget(lex, rn);
			break;
		};
		strio::appendrune(&lex.strbuf, rn)!;
	};

	return strio::string(&lex.strbuf);
};

type numstate = enum {
	SIGN,
	START,
	ZERO,
	INTEGER,
	FRACSTART,
	FRACTION,
	EXPSIGN,
	EXPSTART,
	EXPONENT,
};

fn scan_number(lex: *lexer) (token | error) = {
	strio::reset(&lex.strbuf);

	let state = numstate::SIGN;
	for (true) {
		const rn = match (nextrune(lex)?) {
		case let rn: rune =>
			yield rn;
		case io::EOF =>
			break;
		};

		switch (state) {
		case numstate::SIGN =>
			state = numstate::START;
			if (rn != '-') {
				unget(lex, rn);
				continue;
			};
		case numstate::START =>
			switch (rn) {
			case '0' =>
				state = numstate::ZERO;
			case =>
				if (!ascii::isdigit(rn)) {
					return lex.loc: invalid;
				};
				state = numstate::INTEGER;
			};
		case numstate::ZERO =>
			switch (rn) {
			case '.' =>
				state = numstate::FRACSTART;
			case 'e', 'E' =>
				state = numstate::EXPSIGN;
			case =>
				if (ascii::isdigit(rn)) {
					return lex.loc: invalid;
				};
				unget(lex, rn);
				break;
			};
		case numstate::INTEGER =>
			switch (rn) {
			case '.' =>
				state = numstate::FRACSTART;
			case 'e', 'E' =>
				state = numstate::EXPSIGN;
			case =>
				if (!ascii::isdigit(rn)) {
					unget(lex, rn);
					break;
				};
			};
		case numstate::FRACSTART =>
			if (!ascii::isdigit(rn)) {
				return lex.loc: invalid;
			};
			state = numstate::FRACTION;
		case numstate::FRACTION =>
			switch (rn) {
			case 'e', 'E' =>
				state = numstate::EXPSIGN;
			case =>
				if (!ascii::isdigit(rn)) {
					unget(lex, rn);
					break;
				};
			};
		case numstate::EXPSIGN =>
			state = numstate::EXPSTART;
			if (rn != '+' && rn != '-') {
				unget(lex, rn);
				continue;
			};
		case numstate::EXPSTART =>
			if (!ascii::isdigit(rn)) {
				return lex.loc: invalid;
			};
			state = numstate::EXPONENT;
		case numstate::EXPONENT =>
			if (!ascii::isdigit(rn)) {
				unget(lex, rn);
				break;
			};
		};

		strio::appendrune(&lex.strbuf, rn)!;
	};

	match (strconv::stof64(strio::string(&lex.strbuf))) {
	case let f: f64 =>
		return f;
	case =>
		return lex.loc: invalid;
	};
};

fn scan_str(lex: *lexer) (token | error) = {
	strio::reset(&lex.strbuf);

	for (true) {
		const rn = match (nextrune(lex)?) {
		case let rn: rune =>
			yield rn;
		case io::EOF =>
			lex.loc.1 += 1;
			return lex.loc: invalid;
		};

		switch (rn) {
		case '"' =>
			break;
		case '\\' =>
			const rn = scan_escape(lex)?;
			strio::appendrune(&lex.strbuf, rn)!;
		case =>
			if (iscntrl(rn)) {
				return lex.loc: invalid;
			};
			strio::appendrune(&lex.strbuf, rn)!;
		};
	};

	return strio::string(&lex.strbuf);
};

fn scan_escape(lex: *lexer) (rune | error) = {
	const rn = match (nextrune(lex)?) {
	case let rn: rune =>
		yield rn;
	case io::EOF =>
		return lex.loc: invalid;
	};

	switch (rn) {
	case '\"' =>
		return '\"';
	case '\\' =>
		return '\\';
	case '/' =>
		return '/';
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
	case 'u' =>
		let buf: [4]u8 = [0...];
		match (io::readall(lex.src, buf)?) {
		case io::EOF =>
			return lex.loc: invalid;
		case size =>
			yield;
		};
		const s = match (strings::fromutf8(buf)) {
		case let s: str =>
			yield s;
		case =>
			return lex.loc: invalid;
		};
		match (strconv::stou32b(s, strconv::base::HEX)) {
		case let u: u32 =>
			lex.loc.1 += 4;
			return u: rune;
		case =>
			return lex.loc: invalid;
		};
	case =>
		return lex.loc: invalid;
	};
};

// Gets the next rune from the lexer.
fn nextrune(lex: *lexer) (rune | io::EOF | error) = {
	if (lex.rb is rune) {
		lex.prevrloc = lex.loc;
		const r = lex.rb as rune;
		lex.rb = void;
		if (r == '\n') {
			lex.loc = (lex.loc.0 + 1, 0);
		} else {
			lex.loc.1 += 1;
		};
		return r;
	};
	match (bufio::scanrune(lex.src)) {
	case let err: io::error =>
		return err;
	case utf8::invalid =>
		return lex.loc: invalid;
	case io::EOF =>
		return io::EOF;
	case let rn: rune =>
		lex.prevrloc = lex.loc;
		if (rn == '\n') {
			lex.loc = (lex.loc.0 + 1, 0);
		} else {
			lex.loc.1 += 1;
		};
		return rn;
	};
};

// Like nextrune but skips whitespace.
fn nextrunews(lex: *lexer) (rune | io::EOF | error) = {
	for (true) {
		match (nextrune(lex)?) {
		case let rn: rune =>
			if (isspace(rn)) {
				continue;
			};
			return rn;
		case io::EOF =>
			return io::EOF;
		};
	};
	abort(); // Unreachable
};

fn unget(lex: *lexer, r: rune) void = {
	assert(lex.rb is void);
	lex.rb = r;
	lex.loc = lex.prevrloc;
};

fn iscntrl(r: rune) bool = r: u32 < 0x20;

fn isspace(r: rune) bool = ascii::isspace(r) && r != '\f';
