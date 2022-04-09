// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>

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

// Creates an XML parser. The caller must call [[parser_free]] when they are
// finished with it.
//
// Hare's XML parser only supports UTF-8 encoded input files.
//
// This function will attempt to read the XML prologue before returning, and
// will return an error if it is not valid.
export fn parse(in: io::handle) (*parser | error) = {
	// XXX: The main reason we allocate this instead of returning it on the
	// stack is so that we have a consistent address for the bufio buffer.
	// This is kind of lame, maybe we can avoid that.
	let par = alloc(parser {
		in = null: *bufio::bufstream,
		close = false,
		namebuf = strio::dynamic(),
		entbuf = strio::dynamic(),
		textbuf = strio::dynamic(),
		line = 1,
		...
	});
	if (bufio::isbuffered(in)) {
		par.in = in as *io::stream: *bufio::bufstream;
	} else {
		par.in = alloc(bufio::buffered(in, par.buf[..], []));
		par.close = true;
	};
	match (prolog(par)) {
	case void => void;
	case let err: error =>
		parser_free(par);
		return err;
	};
	return par;
};

// Frees the resources associated with this parser. Does not close the
// underlying I/O handle.
export fn parser_free(par: *parser) void = {
	if (par.close) {
		free(par.in);
	};
	io::close(&par.namebuf);
	io::close(&par.entbuf);
	io::close(&par.textbuf);
	for (let i = 0z; i < len(par.tags); i += 1) {
		free(par.tags[i]);
	};
	free(par.tags);
	free(par);
};

// Scans for and returns the next [[token]]. Tokens are borrowed from the parser
// and are not valid on subsequent calls to [[scan]]; use [[token_dup]] to
// extend their lifetime.
export fn scan(par: *parser) (token | void | error) = {
	switch (par.state) {
	case state::ROOT, state::ATTRS => want(par, OPTWS)?;
	case => void;
	};
	let rn: rune = match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		if (par.state == state::ROOT) {
			return par.line: syntaxerr;
		} else {
			return;
		};
	case let rn: rune =>
		yield rn;
	};
	switch (par.state) {
	case state::ROOT, state::ELEMENT =>
		switch (rn) {
		case '<' =>
			const next = match (bufio::scanrune(par.in)?) {
			case io::EOF =>
				return par.line: syntaxerr;
			case let rn: rune =>
				bufio::unreadrune(par.in, rn);
				yield rn;
			};
			bufio::unreadrune(par.in, rn);
			switch (next) {
			case '!' =>
				return scan_comment(par);
			case '?' =>
				return scan_pi(par);
			case => void;
			};
			let el = scan_element(par)?;
			par.state = state::ATTRS;
			return el;
		case =>
			if (par.state == state::ROOT) {
				return par.line: syntaxerr;
			};
			bufio::unreadrune(par.in, rn);
			return scan_content(par)?;
		};
	case state::ATTRS =>
		if (rn == '/') {
			want(par, '>')?;
			par.state = state::ELEMENT;
			return poptag(par, "")?: elementend;
		} else if (rn == '>') {
			par.state = state::ELEMENT;
			return scan(par)?;
		} else if (!isnamestart(rn)) {
			return par.line: syntaxerr;
		};
		bufio::unreadrune(par.in, rn);
		return scan_attr(par)?;
	};
};

fn poptag(par: *parser, expect: str) (str | error) = {
	if (len(par.tags) == 0) {
		return par.line: syntaxerr;
	};
	let pop = par.tags[len(par.tags) - 1];
	delete(par.tags[len(par.tags) - 1]);
	defer free(pop);
	if (expect != "" && expect != pop) {
		return par.line: syntaxerr;
	};
	strio::reset(&par.namebuf);
	strio::concat(&par.namebuf, pop)!;
	return strio::string(&par.namebuf);
};

fn scan_attr(par: *parser) (token | error) = {
	let name = scan_name(par, &par.namebuf)?;
	want(par, OPTWS, '=', OPTWS)?;
	let quot = quote(par)?;
	strio::reset(&par.textbuf);
	for (true) match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		rn = switch (rn) {
		case '<' =>
			return par.line: syntaxerr;
		case '&' =>
			bufio::unreadrune(par.in, rn);
			yield scan_entity(par)?;
		case '\n' =>
			par.line += 1;
			yield rn;
		case =>
			yield rn;
		};
		if (rn == quot) break;
		strio::appendrune(&par.textbuf, rn)?;
	};
	return (name, strio::string(&par.textbuf)): attribute;
};

fn scan_comment(par: *parser) (token | void | error) = {
	want(par, "<!")?;
	match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		switch (rn) {
		case '-' => // Comments
			want(par, '-')?;
		case '[' =>
			want(par, "CDATA[")?;
			if (par.state != state::ELEMENT) {
				return par.line: syntaxerr;
			};
			return scan_cdata(par)?;
		case =>
			return par.line: syntaxerr;
		};
	};
	for (true) {
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			if (rn == '\n') par.line += 1;
			yield rn;
		};
		if (rn != '-') continue;
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			if (rn == '\n') par.line += 1;
			yield rn;
		};
		if (rn != '-') continue;
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		switch (rn) {
		case '>' =>
			break;
		case '\n' =>
			par.line += 1;
		case => void;
		};
	};
	return scan(par);
};

fn scan_cdata(par: *parser) (text | error) = {
	strio::reset(&par.textbuf);
	for (true) {
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		if (rn != ']') {
			if (rn == '\n') par.line += 1;
			strio::appendrune(&par.textbuf, rn)!;
			continue;
		};
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		if (rn != ']') {
			if (rn == '\n') par.line += 1;
			strio::appendrune(&par.textbuf, rn)!;
			continue;
		};
		const rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		switch (rn) {
		case '>' =>
			break;
		case '\n' =>
			par.line += 1;
		case => void;
		};
		strio::appendrune(&par.textbuf, rn)!;
	};
	return strio::string(&par.textbuf): text;
};

fn scan_content(par: *parser) (text | error) = {
	strio::reset(&par.textbuf);
	for (true) match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		break;
	case let rn: rune =>
		rn = switch (rn) {
		case '<' =>
			bufio::unreadrune(par.in, rn);
			break;
		case '&', '%' =>
			bufio::unreadrune(par.in, rn);
			yield scan_entity(par)?;
		case '\n' =>
			par.line += 1;
			yield rn;
		case =>
			yield rn;
		};
		strio::appendrune(&par.textbuf, rn)?;
	};
	return strio::string(&par.textbuf);
};

fn scan_element(par: *parser) (token | error) = {
	want(par, '<')?;
	let close = false;
	match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		switch (rn) {
		case '/' =>
			close = true;
		case '\n' =>
			par.line += 1;
			bufio::unreadrune(par.in, rn);
		case =>
			bufio::unreadrune(par.in, rn);
		};
	};
	let name = scan_name(par, &par.namebuf)?;
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
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		yield rn;
	};
	switch (rn) {
	case '#' =>
		return scan_charref(par);
	case '%' =>
		return par.line: syntaxerr; // XXX: Deliberate omission: PEReference
	case '\n' =>
		return par.line: syntaxerr;
	case =>
		bufio::unreadrune(par.in, rn);
		return scan_namedent(par);
	};
};

fn scan_charref(par: *parser) (rune | error) = {
	let base = strconv::base::DEC;
	match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		if (rn == 'x') {
			base = strconv::base::HEX;
		} else {
			bufio::unreadrune(par.in, rn);
		};
	};

	strio::reset(&par.entbuf);
	for (true) {
		let rn = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		if (ascii::isdigit(rn)) {
			strio::appendrune(&par.entbuf, rn)?;
		} else if (rn == ';') {
			break;
		} else {
			return par.line: syntaxerr;
		};
	};
	if (len(strio::string(&par.entbuf)) == 0) {
		return par.line: syntaxerr;
	};
	match (strconv::stou32b(strio::string(&par.entbuf), base)) {
	case let u: u32 =>
		return u: rune;
	case (strconv::invalid | strconv::overflow) =>
		return par.line: syntaxerr;
	};
};

fn scan_namedent(par: *parser) (rune | error) = {
	const name = scan_name(par, &par.entbuf)?;
	want(par, ';')?;
	const map = [
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
	return par.line: syntaxerr;
};

fn scan_name(par: *parser, buf: *strio::dynamic_stream) (str | error) = {
	strio::reset(buf);

	const rn = match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		yield rn;
	};
	if (!isnamestart(rn)) {
		return par.line: syntaxerr;
	};
	strio::appendrune(buf, rn)!;

	for (true) match (bufio::scanrune(par.in)?) {
	case io::EOF =>
		return par.line: syntaxerr;
	case let rn: rune =>
		if (isname(rn)) {
			strio::appendrune(buf, rn)!;
		} else {
			bufio::unreadrune(par.in, rn);
			break;
		};
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
	case io::EOF =>
		break;
	case let rn: rune =>
		if (!ascii::isdigit(rn)) {
			bufio::unreadrune(par.in, rn);
			break;
		};
	};
	want(par, quot)?;

	let hadws = want(par, OPTWS)?;
	let encoding = match (bufio::scanrune(par.in)) {
	case io::EOF =>
		yield false;
	case let rn: rune =>
		bufio::unreadrune(par.in, rn);
		yield hadws && rn == 'e';
	};
	if (encoding) {
		let attr = scan_attr(par)? as attribute;
		if (attr.0 != "encoding") {
			return par.line: syntaxerr;
		};
		// XXX: Deliberate omission: all values other than utf-8
		match (ascii::strcasecmp(attr.1, "utf-8")) {
		case void =>
			return utf8::invalid;
		case let n: int =>
			if (n != 0) {
				return utf8::invalid;
			};
		};
	};

	let hadws = want(par, OPTWS)?;
	let standalone = match (bufio::scanrune(par.in)) {
	case io::EOF =>
		yield false;
	case let rn: rune =>
		bufio::unreadrune(par.in, rn);
		yield hadws && rn == 's';
	};
	if (standalone) {
		let attr = scan_attr(par)? as attribute;
		if (attr.0 != "standalone") {
			return par.line: syntaxerr;
		};
		// XXX: Deliberate omission: non-standalone documents
		match (ascii::strcasecmp(attr.1, "yes")) {
		case void =>
			return par.line: syntaxerr;
		case let n: int =>
			if (n != 0) {
				return par.line: syntaxerr;
			};
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
	match (bufio::scanrune(par.in)?) {
	case let rn: rune =>
		switch (rn) {
		case '"', '\'' =>
			return rn;
		case =>
			return par.line: syntaxerr;
		};
	case =>
		return par.line: syntaxerr;
	};
};

fn want(par: *parser, tok: (rune | str | whitespace)...) (bool | error) = {
	let hadws = false;
	for (let i = 0z; i < len(tok); i += 1) match (tok[i]) {
	case let x: rune =>
		let have = match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			return par.line: syntaxerr;
		case let rn: rune =>
			yield rn;
		};
		if (have != x) {
			return par.line: syntaxerr;
		};
		if (x == '\n') {
			par.line += 1;
		};
	case let x: str =>
		let iter = strings::iter(x);
		for (true) match (strings::next(&iter)) {
		case let rn: rune =>
			want(par, rn)?;
		case void =>
			break;
		};
	case let ws: whitespace =>
		let n = 0;
		for (true; n += 1) match (bufio::scanrune(par.in)?) {
		case io::EOF =>
			break;
		case let rn: rune =>
			if (!ascii::isspace(rn)) {
				bufio::unreadrune(par.in, rn);
				break;
			};
			if (rn == '\n') {
				par.line += 1;
			};
		};
		if (ws && n < 1) {
			return par.line: syntaxerr;
		};
		hadws = n >= 1;
	};
	return hadws;
};
