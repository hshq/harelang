// Are you an intrepid programmer seeking to fork this module to create a more
// sophisticated XML parser supporting a broader set of features? Good news: all
// of the features you need to implement are annotated throughout with
// "XXX: Deliberate ommission" comments.
use ascii;
use bufio;
use encoding::utf8;
use io;
use strconv;
use strings;
use strio;

// Returns an XML parser which reads from a stream. The caller must call
// [[parser_free]] when they are finished with it.
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
		namebuf = strio::dynamic(),
		entbuf = strio::dynamic(),
		textbuf = strio::dynamic(),
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
	io::close(par.namebuf);
	io::close(par.entbuf);
	io::close(par.textbuf);
	for (let i = 0z; i < len(par.tags); i += 1) {
		free(par.tags[i]);
	};
	free(par.tags);
	free(par);
};

// Scans for and returns the next [[token]]. Tokens are borrowed from the parser
// and are not valid on subsequent calls to [[scan]]; use [[token_dup]] to extend
// their lifetime.
export fn scan(par: *parser) (token | void | error) = {
	switch (par.state) {
		state::ROOT, state::ATTRS => want(par, OPTWS)?,
		* => void,
	};
	let rn: rune = match (bufio::scanrune(par.in)?) {
		_: io::EOF => if (par.state == state::ROOT) {
			return syntaxerr;
		} else return void,
		rn: rune => rn,
	};
	return switch (par.state) {
		state::ROOT, state::ELEMENT => switch (rn) {
			'<' => {
				const next = match (bufio::scanrune(par.in)?) {
					_: io::EOF => return syntaxerr,
					rn: rune => {
						bufio::unreadrune(par.in, rn);
						rn;
					},
				};
				bufio::unreadrune(par.in, rn);
				switch (next) {
					'!' => return scan_comment(par),
					'?' => return scan_pi(par),
					* => void,
				};
				let el = scan_element(par)?;
				par.state = state::ATTRS;
				el;
			},
			* => {
				if (par.state == state::ROOT) {
					return syntaxerr;
				};
				bufio::unreadrune(par.in, rn);
				scan_content(par)?;
			},
		},
		state::ATTRS => {
			if (rn == '/') {
				want(par, '>')?;
				par.state = state::ELEMENT;
				return poptag(par, "")?: elementend;
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

fn poptag(par: *parser, expect: str) (str | error) = {
	if (len(par.tags) == 0) {
		return syntaxerr;
	};
	let pop = par.tags[len(par.tags) - 1];
	delete(par.tags[len(par.tags) - 1]);
	defer free(pop);
	if (expect != "" && expect != pop) {
		return syntaxerr;
	};
	strio::reset(par.namebuf);
	strio::concat(par.namebuf, pop);
	return strio::string(par.namebuf);
};

fn scan_attr(par: *parser) (token | error) = {
	let name = scan_name(par, par.namebuf)?;
	want(par, OPTWS, '=', OPTWS);
	let quot = quote(par)?;
	strio::reset(par.textbuf);
	for (true) match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => {
			rn = switch (rn) {
				'<' => return syntaxerr,
				'&' => {
					bufio::unreadrune(par.in, rn);
					scan_entity(par)?;
				},
				* => rn,
			};
			if (rn == quot) break;
			strio::appendrune(par.textbuf, rn);
		},
	};
	return (name, strio::string(par.textbuf)): attribute;
};

fn scan_comment(par: *parser) (token | void | error) = {
	want(par, "<!")?;
	match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => switch (rn) {
			'-' => { // Comments
				want(par, '-')?;
			},
			'[' => {
				want(par, "CDATA[")?;
				if (par.state != state::ELEMENT) {
					return syntaxerr;
				};
				return scan_cdata(par)?;
			},
			* => return syntaxerr,
		},
	};
	for (true) {
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn != '-') continue;
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn != '-') continue;
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn == '>') break;
	};
	return scan(par);
};

fn scan_cdata(par: *parser) (text | error) = {
	strio::reset(par.textbuf);
	for (true) {
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn != ']') {
			strio::appendrune(par.textbuf, rn);
			continue;
		};
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn != ']') {
			strio::appendrune(par.textbuf, rn);
			continue;
		};
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (rn == '>') break;
		strio::appendrune(par.textbuf, rn);
	};
	return strio::string(par.textbuf): text;
};

fn scan_content(par: *parser) (text | error) = {
	strio::reset(par.textbuf);
	for (true) match (bufio::scanrune(par.in)?) {
		_: io::EOF => break,
		rn: rune => {
			rn = switch (rn) {
				'<' => {
					bufio::unreadrune(par.in, rn);
					break;
				},
				'&', '%' => {
					bufio::unreadrune(par.in, rn);
					scan_entity(par)?;
				},
			};
			strio::appendrune(par.textbuf, rn);
		},
	};
	return strio::string(par.textbuf);
};

fn scan_element(par: *parser) (token | error) = {
	want(par, '<')?;
	let close = false;
	match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => switch (rn) {
			'/' => close = true,
			* => bufio::unreadrune(par.in, rn),
		},
	};
	let name = scan_name(par, par.namebuf)?;
	if (close) {
		poptag(par, name)?;
		return name: elementend;
	} else {
		append(par.tags, strings::dup(name));
		return name: elementstart;
	};
};

fn scan_entity(par: *parser) (rune | error) = {
	want(par, '&')?;
	let rn = match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => rn,
	};
	return switch (rn) {
		'#' => scan_charref(par),
		'%' => syntaxerr, // XXX: Deliberate omission: PEReference
		*   => {
			bufio::unreadrune(par.in, rn);
			scan_namedent(par);
		},
	};
};

fn scan_charref(par: *parser) (rune | error) = {
	let base = strconv::base::DEC;
	match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => if (rn == 'x') {
			base = strconv::base::HEX;
		} else bufio::unreadrune(par.in, rn),
	};

	strio::reset(par.entbuf);
	for (true) {
		let rn = match (bufio::scanrune(par.in)?) {
			_: io::EOF => return syntaxerr,
			rn: rune => rn,
		};
		if (ascii::isdigit(rn)) {
			strio::appendrune(par.entbuf, rn);
		} else if (rn == ';') {
			break;
		} else {
			return syntaxerr;
		};
	};
	if (len(strio::string(par.entbuf)) == 0) {
		return syntaxerr;
	};
	return match (strconv::stou32b(strio::string(par.entbuf), base)) {
		u: u32 => u: rune,
		_: (strconv::invalid | strconv::overflow) => syntaxerr,
	};
};

fn scan_namedent(par: *parser) (rune | error) = {
	let name = scan_name(par, par.entbuf)?;
	want(par, ';')?;
	let map = [
		("lt", '<'),
		("gt", '>'),
		("amp", '&'),
		("apos", '\''),
		("quot", '"'),
	];
	for (let i = 0z; i < len(map); i += 1) {
		if (map[i].0 == name) {
			return map[i].1;
		};
	};
	// XXX: Deliberate ommission: this only supports the pre-defined
	// entities as defined by XML 1.0 (Fifth Edition) section 4.6.
	return syntaxerr;
};

fn scan_name(par: *parser, buf: *io::stream) (str | error) = {
	strio::reset(buf);

	const rn = match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => rn,
	};
	if (!isnamestart(rn)) {
		return syntaxerr;
	};
	strio::appendrune(buf, rn);

	for (true) match (bufio::scanrune(par.in)?) {
		_: io::EOF => return syntaxerr,
		rn: rune => if (isname(rn)) {
			strio::appendrune(buf, rn);
		} else {
			bufio::unreadrune(par.in, rn);
			break;
		},
	};

	return strio::string(buf);
};

fn scan_pi(par: *parser) (void | error) = {
	abort(); // TODO: Processor instructions
};

fn prolog(par: *parser) (void | error) = {
	// XXX: Deliberate omission(s):
	// - UTF-8 BOM detection
	// - UTF-16 support
	want(par, "<?xml", WS)?;

	want(par, "version", OPTWS, '=', OPTWS)?;
	let quot = quote(par)?;
	want(par, OPTWS, "1.")?;
	for (true) match (bufio::scanrune(par.in)?) {
		_: io::EOF => break,
		rn: rune => if (!ascii::isdigit(rn)) {
			bufio::unreadrune(par.in, rn);
			break;
		},
	};
	want(par, quot)?;

	let hadws = want(par, OPTWS)?;
	let encoding = match (bufio::scanrune(par.in)) {
		_: io::EOF => false,
		rn: rune => {
			bufio::unreadrune(par.in, rn);
			hadws && rn == 'e';
		},
	};
	if (encoding) {
		let attr = scan_attr(par)? as attribute;
		if (attr.0 != "encoding") {
			return syntaxerr;
		};
		// XXX: Deliberate omission: all values other than utf-8
		match (ascii::strcasecmp(attr.1, "utf-8")) {
			_: void => return utf8::invalid,
			n: int => if (n != 0) return utf8::invalid,
		};
	};

	let hadws = want(par, OPTWS)?;
	let standalone = match (bufio::scanrune(par.in)) {
		_: io::EOF => false,
		rn: rune => {
			bufio::unreadrune(par.in, rn);
			hadws && rn == 's';
		},
	};
	if (standalone) {
		let attr = scan_attr(par)? as attribute;
		if (attr.0 != "standalone") {
			return syntaxerr;
		};
		// XXX: Deliberate omission: non-standalone documents
		match (ascii::strcasecmp(attr.1, "yes")) {
			_: void => return syntaxerr,
			n: int => if (n != 0) return syntaxerr,
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
				_: io::EOF => return syntaxerr,
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
				_: void => break,
			};
		},
		ws: whitespace => {
			let n = 0;
			for (true; n += 1) match (bufio::scanrune(par.in)?) {
				_: io::EOF => break,
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
