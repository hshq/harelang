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
type list = []str;
type token = (paragraph | text | reference | sample | list);

type docstate = enum {
	PARAGRAPH,
	TEXT,
};

type parser = struct {
	src: *io::stream,
	state: docstate,
};

fn parsedoc(in: *io::stream) parser = {
	static let buf: [4096]u8 = [0...];
	return parser {
		src = bufio::buffered(in, buf[..], []),
		state = docstate::PARAGRAPH,
	};
};

fn scandoc(par: *parser) (token | void) = {
	const rn = match (bufio::scanrune(par.src)) {
		_: io::EOF => return,
		rn: rune => rn,
		* => abort(),
	};

	bufio::unreadrune(par.src, rn);
	return switch (par.state) {
		docstate::TEXT => switch (rn) {
			'[' => scanref(par),
			* => scantext(par),
		},
		docstate::PARAGRAPH => switch (rn) {
			' ', '\t' => scansample(par),
			'[' => scanref(par),
			'-' => scanlist(par),
			* => scantext(par),
		},
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
		const rn = match (bufio::scanrune(par.src)) {
			_: io::EOF => break,
			_: utf8::invalid => abort("Invalid UTF-8"),
			err: io::error => fmt::fatal(io::strerror(err)),
			rn: rune => rn,
		};
		switch (rn) {
			'[' => {
				bufio::unreadrune(par.src, rn);
				break;
			},
			'\n' => {
				strio::appendrune(buf, rn)!;
				const rn = match (bufio::scanrune(par.src)) {
					_: io::EOF => break,
					* => abort(),
					rn: rune => rn,
				};
				if (rn == '\n') {
					par.state = docstate::PARAGRAPH;
					break;
				};
				bufio::unreadrune(par.src, rn);
			},
			* => strio::appendrune(buf, rn)!,
		};
	};
	let result = strio::finish(buf);
	if (len(result) == 0) {
		return;
	};
	return result: text;
};

fn scanref(par: *parser) (token | void) = {
	match (bufio::scanrune(par.src)) {
		_: io::EOF => return,
		rn: rune => if (rn != '[') abort(),
		* => abort(),
	};
	match (bufio::scanrune(par.src)) {
		_: io::EOF => return,
		rn: rune => if (rn != '[') {
			bufio::unreadrune(par.src, rn);
			return strings::dup("["): text;
		},
		* => abort(),
	};

	const buf = strio::dynamic();
	defer io::close(buf);
	// TODO: Handle invalid syntax here
	for (true) match (bufio::scanrune(par.src)) {
		_: io::EOF => break,
		rn: rune => switch (rn) {
			']' => {
				bufio::scanrune(par.src) as rune; // ]
				break;
			},
			* => strio::appendrune(buf, rn)!,
		},
		* => abort(),
	};
	let id = parse::identstr(strio::string(buf)) as ast::ident;
	return id: reference;
};

fn scansample(par: *parser) (token | void) = {
	let nws = 0z;
	for (true) match (bufio::scanrune(par.src)) {
		_: io::EOF => return,
		rn: rune => switch (rn) {
			' ' => nws += 1,
			'\t' => nws += 8,
			* => {
				bufio::unreadrune(par.src, rn);
				break;
			},
		},
		* => abort(),
	};
	if (nws <= 1) {
		return scantext(par);
	};

	let cont = true;
	let buf = strio::dynamic();
	for (cont) {
		const rn = match (bufio::scanrune(par.src)) {
			_: io::EOF => break,
			rn: rune => rn,
			* => abort(),
		};
		switch (rn) {
			* => {
				strio::appendrune(buf, rn)!;
				continue;
			},
			'\n' => strio::appendrune(buf, rn)!,
		};

		// Consume whitespace
		for (let i = 0z; i < nws) {
			match (bufio::scanrune(par.src)) {
				_: io::EOF => break,
				* => abort(),
				rn: rune => switch (rn) {
					' '  => i += 1,
					'\t' => i += 8,
					'\n' => {
						strio::appendrune(buf, rn)!;
						i = 0;
					},
					* => {
						bufio::unreadrune(par.src, rn);
						cont = false;
						break;
					},
				},
			};
		};
	};

	let buf = strio::finish(buf);

	// Trim trailing newlines
	for (strings::has_suffix(buf, "\n")) {
		buf = strings::sub(buf, 0, len(buf) - 1);
	};

	return buf: sample;
};

fn scanlist(par: *parser) (token | void) = {
	let items: list = [];
	for (true) {
		match (bufio::scanrune(par.src)) {
			_: io::EOF => break,
			* => abort(),
			rn: rune => if (rn != '-') break,
		};
		// XXX: multi-line list items
		append(items, match (bufio::scanline(par.src)) {
			_: io::EOF => break,
			_: io::error => abort(),
			u: []u8 => strings::fromutf8(u),
		});
	};
	return items;
};
