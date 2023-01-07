// License: GPL-3.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
// (c) 2022 Umar Getagazov <umar@handlerug.me>
use ascii;
use bufio;
use encoding::utf8;
use fmt;
use hare::ast;
use hare::parse;
use io;
use strings;
use strio;

type paragraph = void;
type text = str;
type reference = ast::ident;
type sample = str;
type listitem = void;
type token = (paragraph | text | reference | sample | listitem);

type docstate = enum {
	PARAGRAPH,
	TEXT,
	LIST,
};

type parser = struct {
	src: bufio::bufstream,
	state: docstate,
};

fn parsedoc(in: io::handle) parser = {
	static let buf: [4096]u8 = [0...];
	return parser {
		src = bufio::buffered(in, buf[..], []),
		state = docstate::PARAGRAPH,
	};
};

fn scandoc(par: *parser) (token | void) = {
	const rn = match (bufio::scanrune(&par.src)!) {
	case let rn: rune =>
		yield rn;
	case io::EOF =>
		return;
	};

	bufio::unreadrune(&par.src, rn);
	switch (par.state) {
	case docstate::TEXT =>
		switch (rn) {
		case '[' =>
			return scanref(par);
		case =>
			return scantext(par);
		};
	case docstate::LIST =>
		switch (rn) {
		case '[' =>
			return scanref(par);
		case '-' =>
			return scanlist(par);
		case =>
			return scantext(par);
		};
	case docstate::PARAGRAPH =>
		switch (rn) {
		case ' ', '\t' =>
			return scansample(par);
		case '-' =>
			return scanlist(par);
		case =>
			return scantext(par);
		};
	};
};

fn scantext(par: *parser) (token | void) = {
	if (par.state == docstate::PARAGRAPH) {
		par.state = docstate::TEXT;
		return paragraph;
	};
	// TODO: Collapse whitespace
	const buf = strio::dynamic();
	for (true) {
		const rn = match (bufio::scanrune(&par.src)!) {
		case io::EOF => break;
		case let rn: rune =>
			yield rn;
		};
		switch (rn) {
		case '[' =>
			bufio::unreadrune(&par.src, rn);
			break;
		case '\n' =>
			strio::appendrune(&buf, rn)!;
			const rn = match (bufio::scanrune(&par.src)!) {
			case io::EOF => break;
			case let rn: rune =>
				yield rn;
			};
			if (rn == '\n') {
				par.state = docstate::PARAGRAPH;
				break;
			};
			bufio::unreadrune(&par.src, rn);
			if (rn == '-' && par.state == docstate::LIST) {
				break;
			};
		case =>
			strio::appendrune(&buf, rn)!;
		};
	};
	let result = strio::string(&buf);
	if (len(result) == 0) {
		return;
	};
	return result: text;
};

fn scanref(par: *parser) (token | void) = {
	match (bufio::scanrune(&par.src)!) {
	case io::EOF =>
		return;
	case let rn: rune =>
		if (rn != '[') {
			abort();
		};
	};
	match (bufio::scanrune(&par.src)!) {
	case io::EOF =>
		return;
	case let rn: rune =>
		if (rn != '[') {
			bufio::unreadrune(&par.src, rn);
			return strings::dup("["): text;
		};
	};

	const buf = strio::dynamic();
	defer io::close(&buf)!;
	// TODO: Handle invalid syntax here
	for (true) {
		match (bufio::scanrune(&par.src)!) {
		case let rn: rune =>
			switch (rn) {
			case ']' =>
				bufio::scanrune(&par.src) as rune; // ]
				break;
			case =>
				strio::appendrune(&buf, rn)!;
			};
		case io::EOF => break;
		};
	};
	let id = parse::identstr(strio::string(&buf)) as ast::ident;
	return id: reference;
};

fn scansample(par: *parser) (token | void) = {
	let nws = 0z;
	for (true) {
		match (bufio::scanrune(&par.src)!) {
		case io::EOF =>
			return;
		case let rn: rune =>
			switch (rn) {
			case ' ' =>
				nws += 1;
			case '\t' =>
				nws += 8;
			case =>
				bufio::unreadrune(&par.src, rn);
				break;
			};
		};
	};
	if (nws <= 1) {
		return scantext(par);
	};

	let cont = true;
	let buf = strio::dynamic();
	for (cont) {
		const rn = match (bufio::scanrune(&par.src)!) {
		case io::EOF => break;
		case let rn: rune =>
			yield rn;
		};
		switch (rn) {
		case '\n' =>
			strio::appendrune(&buf, rn)!;
		case =>
			strio::appendrune(&buf, rn)!;
			continue;
		};

		// Consume whitespace
		for (let i = 0z; i < nws) {
			match (bufio::scanrune(&par.src)!) {
			case io::EOF => break;
			case let rn: rune =>
				switch (rn) {
				case ' ' =>
					i += 1;
				case '\t' =>
					i += 8;
				case '\n' =>
					strio::appendrune(&buf, rn)!;
					i = 0;
				case =>
					bufio::unreadrune(&par.src, rn);
					cont = false;
					break;
				};
			};
		};
	};

	let buf = strio::string(&buf);
	// Trim trailing newlines
	buf = strings::rtrim(buf, '\n');
	return buf: sample;
};

fn scanlist(par: *parser) (token | void) = {
	match (bufio::scanrune(&par.src)!) {
	case io::EOF => return void;
	case let rn: rune =>
		if (rn != '-') {
			abort();
		};
	};
	const rn = match (bufio::scanrune(&par.src)!) {
	case io::EOF => return void;
	case let rn: rune =>
		yield rn;
	};
	if (rn != ' ') {
		bufio::unreadrune(&par.src, rn);
		return strings::dup("-"): text;
	};
	par.state = docstate::LIST;
	return listitem;
};
