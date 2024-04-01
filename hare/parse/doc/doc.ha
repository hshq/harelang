// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use memio;
use strings;

// A representation of a complete haredoc document.
export type doc = [](paragraph | list | code_sample);

// A paragraph of text.
export type paragraph = [](str | decl_ref | mod_ref);

// A bulleted list.
export type list = []paragraph;

// A code sample.
export type code_sample = str;

// A reference to a declaration.
export type decl_ref = ast::ident;

// A reference to a module.
export type mod_ref = ast::ident;

// All possible error types.
export type error = !lex::error;

// Converts an error into a human-friendly string. The result may be statically
// allocated.
export fn strerror(err: error) const str = lex::strerror(err);

// Parses a haredoc document from an [[io::handle]]. 'start' is the location of
// the top-left corner of the document, for accurate locations in error messages
// (e.g. declaration documentation starts at col=3; READMEs start at col=1).
export fn parse(in: io::handle, start: lex::location) (doc | error) = {
	let sc = bufio::newscanner(in);
	defer bufio::finish(&sc);

	match (_parse(&sc)) {
	case let doc: doc =>
		return doc;
	case let err: lex::syntax =>
		err.0.path = start.path;
		err.0.line += start.line;
		err.0.col += start.col;
		return err;
	case let err: io::error =>
		return err;
	case utf8::invalid =>
		// XXX: the location for this error is inaccurate
		return lex::syntaxerr(start, "Invalid UTF-8");
	};
};

fn _parse(sc: *bufio::scanner) (doc | ...error | utf8::invalid) = {
	let loc = lex::location { ... };
	let doc: doc = [];

	for (let r => bufio::scan_rune(sc)?) {
		if (r == ' ') {
			r = match (bufio::scan_rune(sc)?) {
			case io::EOF =>
				break;
			case let r: rune =>
				loc.col = 1;
				yield r;
			};
		};

		switch (r) {
		case '\t' =>
			loc.col = 8;
			append(doc, scan_code_sample(sc, &loc)?);
		case '\n' =>
			loc.line += 1;
			loc.col = 0;
		case '-' =>
			loc.col += 1;
			append(doc, scan_list(sc, &loc)?);
		case =>
			bufio::unreadrune(sc, r);
			append(doc, scan_paragraph(sc, &loc)?);
		};
	};

	return doc;
};

fn scan_code_sample(
	sc: *bufio::scanner,
	loc: *lex::location,
) (code_sample | ...error | utf8::invalid) = {
	let s = memio::dynamic();
	for (let r => bufio::scan_rune(sc)?) {
		switch (r) {
		case '\t' =>
			loc.col += 8 - loc.col % 8;
			memio::appendrune(&s, r)!;
		case '\n' =>
			loc.line += 1;
			loc.col = 0;

			let (r, space) = match (bufio::scan_rune(sc)?) {
			case io::EOF =>
				break;
			case let r: rune =>
				if (r != ' ') yield (r, false);
				yield match (bufio::scan_rune(sc)?) {
				case io::EOF =>
					break;
				case let r: rune =>
					yield (r, true);
				};
			};

			switch (r) {
			case '\t' =>
				loc.col = 8;
				memio::appendrune(&s, '\n')!;
			case '\n' =>
				memio::appendrune(&s, '\n')!;
				bufio::unreadrune(sc, '\n');
			case =>
				bufio::unreadrune(sc, r);
				if (space) {
					bufio::unreadrune(sc, ' ');
				};
				break;
			};
		case =>
			loc.col += 1;
			memio::appendrune(&s, r)!;
		};
	};

	return memio::string(&s)!;
};

fn scan_list(
	sc: *bufio::scanner,
	loc: *lex::location,
) (list | ...error | utf8::invalid) = {
	let li: list = [];
	for (true) {
		match (bufio::scan_rune(sc)?) {
		case io::EOF =>
			append(li, []);
			break;
		case let r: rune =>
			if (r != ' ') {
				bufio::unreadrune(sc, r);
			};
		};

		append(li, scan_paragraph(sc, loc)?);

		match (bufio::scan_rune(sc)?) {
		case io::EOF =>
			break;
		case let r: rune =>
			if (r != '-') {
				bufio::unreadrune(sc, r);
				break;
			};
		};
	};

	return li;
};

// XXX: should be local to scan_paragraph, once that's possible
type state = enum {
	NORMAL,
	SPACE,
	NEWLINE,
};

fn scan_paragraph(
	sc: *bufio::scanner,
	loc: *lex::location,
) (paragraph | ...error | utf8::invalid) = {
	let p: paragraph = [];
	let s = memio::dynamic();
	defer io::close(&s)!;
	let state = state::NORMAL;

	for (let r => bufio::scan_rune(sc)?) {
		switch (r) {
		case '\t' =>
			if (state == state::NEWLINE && loc.col <= 1) {
				bufio::unreadrune(sc, r);
				break;
			};
			loc.col += 8 - loc.col % 8;
			if (state == state::NORMAL) {
				state = state::SPACE;
			};
			continue;
		case '\n' =>
			loc.line += 1;
			loc.col = 0;
			if (state == state::NEWLINE) {
				break;
			};
			state = state::NEWLINE;
			continue;
		case ' ' =>
			loc.col += 1;
			if (state == state::NORMAL) {
				state = state::SPACE;
			};
			continue;
		case '-' =>
			if (state != state::NEWLINE || loc.col > 1) yield;
			// XXX: we may want to reconsider if recognizing '-'
			// here is too lenient (what if a line begins with a
			// negative number?)
			bufio::unreadrune(sc, r);
			break;
		case => void;
		};

		if (state != state::NORMAL) {
			memio::appendrune(&s, ' ')!;
		};
		state = state::NORMAL;
		loc.col += 1;

		if (r != '[') {
			memio::appendrune(&s, r)!;
			continue;
		};

		r = match (bufio::scan_rune(sc)?) {
		case io::EOF =>
			memio::appendrune(&s, '[')!;
			break;
		case let r: rune =>
			yield r;
		};
		if (r != '[') {
			memio::appendrune(&s, '[')!;
			bufio::unreadrune(sc, r);
			continue;
		};

		loc.col += 1;
		const part = memio::string(&s)!;
		if (part != "") {
			append(p, strings::dup(part));
			memio::reset(&s);
		};

		let lexer = lex::init(sc, loc.path);
		const (ident, mod) = match (parse::ident_trailing(&lexer)) {
		case let id: (ast::ident, bool) =>
			yield id;
		case let err: lex::syntax =>
			if (err.0.line == 1) {
				err.0.col += loc.col - 1;
			};
			err.0.line += loc.line - 1;
			return err;
		case let err: io::error =>
			return err;
		};

		// intentionally not using lex::mkloc, so whitespace is
		// accounted for
		if (lexer.loc.0 == 1) {
			loc.col += lexer.loc.1 - 1;
		} else {
			loc.col = 0;
		};
		loc.line += lexer.loc.0 - 1;

		append(p, if (mod) ident: mod_ref else ident: decl_ref);

		if (lexer.un.0 == lex::ltok::RBRACKET) {
			match (bufio::scan_rune(sc)?) {
			case io::EOF => void;
			case let r: rune =>
				if (r == ']') {
					loc.col += 1;
					continue;
				};
			};
		};
		return lex::syntaxerr(*loc, "Unterminated reference");
	};

	const part = memio::string(&s)!;
	if (part != "") {
		append(p, strings::dup(part));
	};
	return p;
};

// Frees resources associated with a [[doc]].
export fn freeall(doc: doc) void = {
	for (let d .. doc) {
		match (d) {
		case let p: paragraph =>
			free_paragraph(p);
		case let l: list =>
			for (let p .. l) {
				free_paragraph(p);
			};
			free(l);
		case let c: code_sample =>
			free(c);
		};
	};
	free(doc);
};

fn free_paragraph(p: paragraph) void = {
	for (let entry .. p) {
		match (entry) {
		case let s: str =>
			free(s);
		case let d: decl_ref =>
			ast::ident_free(d);
		case let m: mod_ref =>
			ast::ident_free(m);
		};
	};
	free(p);
};
