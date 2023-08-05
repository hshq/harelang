// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use io;
use memio;
use strings;

// Invalid shell syntax.
export type syntaxerr = !void;

// Splits a string of arguments according to shell quoting. The result must be
// freed using [[strings::freeall]] when the caller is done processing it.
export fn split(in: const str) ([]str | syntaxerr) = {
	let iter = strings::iter(in);

	let s = memio::dynamic();
	let slice: []str = [];
	let first = true;
	let dirty = false;

	for (true) {
		const r = match (strings::next(&iter)) {
		case let r: rune =>
			yield r;
		case void =>
			break;
		};

		dirty = true;
		switch (r) {
		case ' ', '\t', '\n' =>
			for (true) match (strings::next(&iter)) {
			case let r: rune =>
				if (r != ' ' && r != '\t' && r != '\n') {
					strings::prev(&iter); // Unget
					break;
				};
			case void =>
				break;
			};
			if (!first) {
				append(slice, memio::string(&s)!);
				s = memio::dynamic();
			};
			dirty = false;
		case '\\' =>
			scan_backslash(&s, &iter)?;
		case '"' =>
			scan_double(&s, &iter)?;
		case '\'' =>
			scan_single(&s, &iter)?;
		case =>
			memio::appendrune(&s, r)!;
		};

		if (first) {
			first = false;
		};
	};

	if (dirty) {
		append(slice, memio::string(&s)!);
	};

	return slice;
};

fn scan_backslash(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	const r = match (strings::next(in)) {
	case let r: rune =>
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

	memio::appendrune(out, r)!;
};

fn scan_double(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	for (true) {
		const r = match (strings::next(in)) {
		case let r: rune =>
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
			memio::appendrune(out, r)!;
		};
	};
};

fn scan_single(out: io::handle, in: *strings::iterator) (void | syntaxerr) = {
	for (true) {
		const r = match (strings::next(in)) {
		case let r: rune =>
			yield r;
		case void =>
			return syntaxerr;
		};

		if (r == '\'') {
			break;
		};
		memio::appendrune(out, r)!;
	};
};
