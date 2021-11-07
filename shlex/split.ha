use bufio;
use io;
use strings;
use strio;

// Invalid shell syntax.
export type syntaxerr = !void;

// Splits a string of arguments according to shell quoting. The result must be
// freed using [[splitfree]] when the caller is done processing it.
export fn split(in: const str) ([]str | syntaxerr) = {
	let in = bufio::fixed(strings::toutf8(in), io::mode::READ);
	defer io::close(in);

	let s = strio::dynamic();
	let slice: []str = [];

	for (true) {
		const r = match (bufio::scanrune(in)!) {
		case r: rune =>
			yield r;
		case io::EOF =>
			break;
		};

		switch (r) {
		case '\\' =>
			scan_backslash(s, in)?;
		case '"' =>
			scan_double(s, in)?;
		case '\'' =>
			scan_single(s, in)?;
		case ' ', '\t', '\n' =>
			if (len(strio::string(s)) > 0) {
				append(slice, strio::finish(s));
				s = strio::dynamic();
			};
		case =>
			strio::appendrune(s, r)!;
		};
	};

	const buf = strio::finish(s);
	if (len(buf) > 0) {
		append(slice, buf);
	};

	return slice;
};

fn scan_backslash(out: io::handle, in: io::handle) (void | syntaxerr) = {
	const r = match (bufio::scanrune(in)!) {
	case r: rune =>
		yield r;
	case io::EOF =>
		return syntaxerr;
	};

	// The <backslash> and <newline> shall be removed before splitting the
	// input into tokens. Since the escaped <newline> is removed entirely
	// from the input and is not replaced by any white space, it cannot
	// serve as a token separator
	if (r == '\n') {
		return;
	};

	strio::appendrune(out, r)!;
};

fn scan_double(out: io::handle, in: io::handle) (void | syntaxerr) = {
	for (true) {
		const r = match (bufio::scanrune(in)!) {
		case r: rune =>
			yield r;
		case io::EOF =>
			return syntaxerr;
		};

		switch (r) {
		case '"' =>
			break;
		case '\\' =>
			scan_backslash(out, in)?;
		case =>
			strio::appendrune(out, r)!;
		};
	};
};

fn scan_single(out: io::handle, in: io::handle) (void | syntaxerr) = {
	for (true) {
		const r = match (bufio::scanrune(in)!) {
		case r: rune =>
			yield r;
		case io::EOF =>
			return syntaxerr;
		};

		if (r == '\'') {
			break;
		};
		strio::appendrune(out, r)!;
	};
};

// TODO: rehome a more generic version into strings/?

// Frees a slice of allocated strings returned from [[split]].
export fn splitfree(s: const []str) void = {
	for (let i = 0z; i < len(s); i += 1) {
		free(s[i]);
	};
	free(s);
};
