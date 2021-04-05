use ascii;
use bufio;
use encoding::utf8;
use io;
use strings;

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

fn prolog(par: *parser) (void | error) = {
	want(par, "<?xml", WS);

	want(par, "version", OPTWS, '=', OPTWS);
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

	// TODO: Replace this with attribute() when it's written
	let hadws = want(par, OPTWS)?;
	let encoding = match (bufio::scanrune(par.in)) {
		io::EOF => false,
		rn: rune => {
			bufio::unreadrune(par.in, rn);
			hadws && rn == 'e';
		},
	};
	if (encoding) {
		want(par, "encoding", OPTWS, '=', OPTWS)?;
		let quot = quote(par)?;
		match (want(par, "UTF-8")) {
			syntaxerr => return utf8::invalid,
			err: error => return err,
			bool => void,
		};
		want(par, quot)?;
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
		want(par, "standalone", OPTWS, '=', OPTWS)?;
		let quot = quote(par)?;
		// TODO: Should we support standalone="no"?
		want(par, "yes", quot)?;
	};

	want(par, OPTWS, "?>")?;
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
				* => return syntaxerr,
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
