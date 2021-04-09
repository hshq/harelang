// encoding::xml provides a simple parser of the useful subset of the XML 1.0
// (Fifth Edition) specification as defined by the W3C. Features omitted are:
//
// - Support for user-defined entities
// - Support for UTF-16 inputs or a UTF-8 BOM
//
// Attempting to parse an input file which does not conform to the supported
// subset of XML will return a syntax error. The purpose of this module is to
// support most XML files found in the wild, without supporting the lesser-used
// features that lead to problems like "billion laughs" vulnerabilities. If a
// fully conformant XML parser is required for your application, you will need
// to use a third-party XML implementation. Such an implementation should be
// able to shadow the standard library version and present a compatible API.
use ascii;
use bufio;
use encoding::utf8;
use io;
use strings;
use strio;

// Returns an XML parser which reads from a stream. The caller must call
// [parser_free] when they are finished with it.
//
// Hare's XML parser only supports UTF-8 encoded input files.
//
// This function will attempt to read the XML prologue before returning, and
// will return an error if it is not valid.
export fn parse(in: *io::stream) (*parser | error) = {
	// XXX: The main reason we allocate this instead of returning it on the
	// stack is so that we have a consistent address for the bufio buffer.
	// This is kind of lame, maybe we can avoid that.
	let par = alloc(parser {
		orig = in,
		in = in,
		...
	});
	if (!bufio::isbuffered(in)) {
		par.in = bufio::buffered(par.in, par.buf[..], []);
	};
	prolog(par)?;
	return par;
};

// Frees the resources associated with this parser. Does not close the
// underlying stream.
export fn parser_free(par: *parser) void = {
	if (par.in != par.orig) {
		io::close(par.in);
	};
	free(par);
};

// Scans for and returns the next [token]. The caller must pass the returned
// token to [token_free] when they're done with it.
export fn scan(par: *parser) (token | void | error) = {
	switch (par.state) {
		state::ROOT, state::ATTRS => want(par, OPTWS)?,
		* => void,
	};
	let rn: rune = match (bufio::scanrune(par.in)?) {
		io::EOF => if (par.state == state::ROOT) {
			return syntaxerr;
		} else return void,
		rn: rune => rn,
	};
	// TODO:
	// - Comments
	// - Entities/references
	// - CDATA
	// - Processing Instructions
	return switch (par.state) {
		state::ROOT => switch (rn) {
			'<' => {
				bufio::unreadrune(par.in, rn);
				let el = scan_element(par)?;
				par.state = state::ATTRS;
				el;
			},
			* => return syntaxerr,
		},
		state::ELEMENT => switch (rn) {
			'<' => {
				bufio::unreadrune(par.in, rn);
				let el = scan_element(par);
				par.state = state::ATTRS;
				el;
			},
			* => {
				bufio::unreadrune(par.in, rn);
				scan_content(par)?;
			},
		},
		state::ATTRS => {
			if (rn == '/') {
				want(par, '>')?;
				par.state = state::ELEMENT;
				return elementend;
			} else if (rn == '>') {
				par.state = state::ELEMENT;
				return scan(par)?;
			} else if (!isnamestart(rn)) {
				return syntaxerr;
			};
			bufio::unreadrune(par.in, rn);
			scan_attr(par)?;
		},
	};
};

fn scan_element(par: *parser) (token | error) = {
	want(par, '<')?;
	let close = false;
	match (bufio::scanrune(par.in)?) {
		io::EOF => return syntaxerr,
		rn: rune => switch (rn) {
			'/' => close = true,
			* => bufio::unreadrune(par.in, rn),
		},
	};
	let name = scan_name(par)?;
	if (close) {
		free(name);
		return elementend;
	} else {
		return name: elementstart;
	};
};

fn scan_attr(par: *parser) (token | error) = {
	let name = scan_name(par)?;
	want(par, OPTWS, '=', OPTWS);
	let quot = quote(par)?;
	let val = strio::dynamic();
	for (true) match (bufio::scanrune(par.in)?) {
		io::EOF => return syntaxerr,
		rn: rune => {
			switch (rn) {
				'<' => abort(), // TODO
				'&' => abort(), // TODO
				* => void,
			};
			if (rn == quot) break;
			strio::appendrune(val, rn);
		},
	};
	return (name, strio::finish(val)): attribute;
};

fn scan_name(par: *parser) (str | error) = {
	let buf = strio::dynamic();

	const rn = match (bufio::scanrune(par.in)?) {
		io::EOF => return syntaxerr,
		rn: rune => rn,
	};
	if (!isnamestart(rn)) {
		return syntaxerr;
	};
	strio::appendrune(buf, rn);

	for (true) match (bufio::scanrune(par.in)?) {
		io::EOF => return syntaxerr,
		rn: rune => if (isname(rn)) {
			strio::appendrune(buf, rn);
		} else {
			bufio::unreadrune(par.in, rn);
			break;
		},
	};

	return strio::finish(buf);
};

fn scan_content(par: *parser) (text | error) = {
	let content = strio::dynamic();
	for (true) match (bufio::scanrune(par.in)?) {
		io::EOF => break,
		rn: rune => {
			switch (rn) {
				'<' => {
					bufio::unreadrune(par.in, rn);
					break;
				},
				'&' => {
					bufio::unreadrune(par.in, rn);
					abort(); // TODO
				},
				'%' => {
					bufio::unreadrune(par.in, rn);
					abort(); // TODO
				},
			};
			strio::appendrune(content, rn);
		},
	};
	return strio::finish(content);
};

fn prolog(par: *parser) (void | error) = {
	want(par, "<?xml", WS)?;

	want(par, "version", OPTWS, '=', OPTWS)?;
	let quot = quote(par)?;
	want(par, OPTWS, "1.")?;
	for (true) match (bufio::scanrune(par.in)?) {
		io::EOF => break,
		rn: rune => if (!ascii::isdigit(rn)) {
			bufio::unreadrune(par.in, rn);
			break;
		},
	};
	want(par, quot)?;

	let hadws = want(par, OPTWS)?;
	let encoding = match (bufio::scanrune(par.in)) {
		io::EOF => false,
		rn: rune => {
			bufio::unreadrune(par.in, rn);
			hadws && rn == 'e';
		},
	};
	if (encoding) {
		let attr = scan_attr(par)? as attribute;
		defer token_free(attr);
		if (attr.0 != "encoding") {
			return syntaxerr;
		};
		match (ascii::strcasecmp(attr.1, "utf-8")) {
			void => return utf8::invalid,
			n: int => if (n != 0) return utf8::invalid,
		};
	};

	let hadws = want(par, OPTWS)?;
	let standalone = match (bufio::scanrune(par.in)) {
		io::EOF => false,
		rn: rune => {
			bufio::unreadrune(par.in, rn);
			hadws && rn == 's';
		},
	};
	if (standalone) {
		let attr = scan_attr(par)? as attribute;
		defer token_free(attr);
		if (attr.0 != "standalone") {
			return syntaxerr;
		};
		match (ascii::strcasecmp(attr.1, "yes")) {
			void => return syntaxerr,
			n: int => if (n != 0) return syntaxerr, // TODO?
		};
	};

	want(par, OPTWS, "?>", OPTWS)?;
	// TODO: Parse doctypedecl & misc
	return;
};

// Mandatory if true
type whitespace = bool;
def WS: whitespace = true;
def OPTWS: whitespace = false;

fn quote(par: *parser) (rune | error) = {
	return match (bufio::scanrune(par.in)?) {
		* => return syntaxerr,
		rn: rune => switch (rn) {
			'"', '\'' => rn,
			* => return syntaxerr,
		},
	};
};

fn want(par: *parser, tok: (rune | str | whitespace)...) (bool | error) = {
	let hadws = false;
	for (let i = 0z; i < len(tok); i += 1) match (tok[i]) {
		x: rune => {
			let have = match (bufio::scanrune(par.in)?) {
				io::EOF => return syntaxerr,
				rn: rune => rn,
			};
			if (have != x) {
				return syntaxerr;
			};
		},
		x: str => {
			let iter = strings::iter(x);
			for (true) match (strings::next(&iter)) {
				rn: rune => want(par, rn)?,
				void => break,
			};
		},
		ws: whitespace => {
			let n = 0;
			for (true; n += 1) match (bufio::scanrune(par.in)?) {
				io::EOF => break,
				rn: rune => if (!ascii::isspace(rn)) {
					bufio::unreadrune(par.in, rn);
					break;
				},
			};
			if (ws && n < 1) {
				return syntaxerr;
			};
			hadws = n >= 1;
		},
	};
	return hadws;
};
