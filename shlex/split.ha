use io;
use strings;
use strio;

// Invalid shell syntax.
export type syntaxerr = !void;

// Splits a string of arguments according to shell quoting. The result must be
// freed using [[strings::freeall]] when the caller is done processing it.
export fn split(in: const str) ([]str | syntaxerr) = {
	let iter = strings::iter(in);

	let s = strio::dynamic();
	let slice: []str = [];
	let dirty = false;

	for (true) {
		const r = match (strings::next(&iter)) {
		case r: rune =>
			yield r;
		case void =>
			break;
		};

		dirty = true;
		switch (r) {
		case ' ', '\t', '\n' =>
			for (true) match (strings::next(&iter)) {
			case r: rune =>
				if (r != ' ' && r != '\t' && r != '\n') {
					strings::prev(&iter); // Unget
					break;
				};
			case void =>
				break;
			};
			append(slice, strio::finish(s));
			s = strio::dynamic();
			dirty = false;
		case '\\' =>
			scan_backslash(s, &iter)?;
		case '"' =>
			scan_double(s, &iter)?;
		case '\'' =>
			scan_single(s, &iter)?;
		case =>
			strio::appendrune(s, r)!;
		};
	};

	if (dirty) {
		append(slice, strio::finish(s));
	};

	return slice;
};

fn scan_backslash(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	const r = match (strings::next(in)) {
	case r: rune =>
		yield r;
	case void =>
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

fn scan_double(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	for (true) {
		const r = match (strings::next(in)) {
		case r: rune =>
			yield r;
		case void =>
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

fn scan_single(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	for (true) {
		const r = match (strings::next(in)) {
		case r: rune =>
			yield r;
		case void =>
			return syntaxerr;
		};

		if (r == '\'') {
			break;
		};
		strio::appendrune(out, r)!;
	};
};
