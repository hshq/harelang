// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use errors;
use strings;

// A set of flags that alter the matching behavior of [[fnmatch]]
export type flag = enum uint {
	NONE = 0,

	// If this flag is set, slashes in the string will only be matched by
	// literal slashes in the pattern
	PATHNAME = 1u << 0,
	// If this flag is set, backslash will be treated as an ordinary
	// character
	NOESCAPE = 1u << 1,
	// If this flag is set, a '.' at the beginning of the string can only
	// be matched by a literal '.' in the pattern. If [[flag::PATHNAME]] is
	// set simultaneously, this behavior also apply to any periods
	// immediately following a slash.
	PERIOD = 1u << 2,
};

type bracket = void;
type star = void;
type question = void;
type end = void;
type token = (rune | bracket | star | question | end);

// Check whether the 'string' matches the 'pattern', which is a shell wildcard
// pattern with the following matching rules:
//
// - '?' matches any single character
// - '*' matches any string, including the empty string
// - '[' and ']' enclose a bracket expression. Matching rules for bracket
//   expressions are identical to those of bracket subexpressions in regular
//   expressions, except that '!' takes the role of '^' when placed right after
//   the opening '['.
// - '\' escapes the following character, e. g. "\*" only matches literal '*'
//   and has no special meaning
// - all other characters only match themselves
//
// A set of flags that alter the matching behavior may be passed to
// [[fnmatch]]. For an explanation of their meaning, see [[flag]].
export fn fnmatch(pattern: str, string: str, flags: flag = flag::NONE) bool = {
	let b = if (flags & flag::PATHNAME != 0) {
		yield fnmatch_pathname(pattern, string, flags);
	} else {
		yield fnmatch_internal(pattern, string, flags);
	};
	return b is bool && b: bool;
};

// Split the pattern and the string on every '/' and process each part
// separately
fn fnmatch_pathname(
	pattern: str,
	string: str,
	fl: flag,
) (bool | errors::unsupported | errors::invalid) = {
	let tok = strings::tokenize(string, "/");
	let p_iter = strings::iter(pattern);
	let start = p_iter;
	for :outer (true) {
		start = p_iter;
		for (true) match (pat_next(&p_iter, fl)?) {
		case end =>
			break :outer;
		case let r: rune =>
			if (r == '/') break;
		case bracket =>
			match_bracket(&p_iter, '\0')?;
		case (question | star) => void;
		};
		let s = match (strings::next_token(&tok)) {
		case done =>
			return false;
		case let s: str =>
			yield s;
		};
		strings::prev(&p_iter);
		let p = strings::slice(&start, &p_iter);
		strings::next(&p_iter);
		if (!fnmatch_internal(p, s, fl)?) {
			return false;
		};
	};
	let s = match(strings::next_token(&tok)) {
	case done =>
		return false;
	case let s: str =>
		yield s;
	};
	let p = strings::iterstr(&start);
	return fnmatch_internal(p, s, fl)? && strings::next_token(&tok) is done;
};

// Core fnmatch function, implementing the "Sea of stars" algorithm that is also
// used in Musl libc. First we make sure the parts before the first star and
// after the last star produce exact matches and then proceed to greedily match
// everything in between. Because of the greedy property this algorithm does not
// have exponential corner cases.
fn fnmatch_internal(
	pattern: str,
	string: str,
	fl: flag,
) (bool | errors::invalid | errors::unsupported) = {
	if (fl & flag::PERIOD != 0) {
		if (strings::hasprefix(string, ".")
				&& !strings::hasprefix(pattern, ".")) {
			return false;
		};
	};

	let p = strings::iter(pattern);
	let s = strings::iter(string);

	// match up to the first *
	for (true) {
		let copy = s;
		let rn = strings::next(&copy);
		let t = match (pat_next(&p, fl)?) {
		case star =>
			break;
		case end =>
			return rn is done;
		case question =>
			yield rn is rune;
		case bracket =>
			yield rn is rune && match_bracket(&p, rn: rune)?;
		case let r: rune =>
			yield rn is rune && rn: rune == r;
		};
		if (!t) {
			return false;
		};
		s = copy;
	};

	// find the tail of the pattern
	let p_copy = p, p_last = (p, 0z);
	let cnt = 0z;
	for (true; cnt += 1) {
		match (pat_next(&p, fl)?) {
		case end =>
			break;
		case star =>
			p_last = (p, cnt + 1);
		case bracket =>
			match_bracket(&p, '\0')?;
		case (question | rune) => void;
		};
	};
	p = p_last.0;
	cnt = cnt - p_last.1;
	let s_copy = s;
	s = strings::riter(string);
	for (let i = 0z; i < cnt; i += 1) {
		strings::next(&s);
	};

	// match the tail
	let s_last = s;
	for (true) {
		let rn = strings::prev(&s);
		let matches = match (pat_next(&p, fl)?) {
		case end =>
			if (rn is done) {
				break;
			} else {
				return false;
			};
		case question =>
			yield rn is rune;
		case bracket =>
			yield rn is rune && match_bracket(&p, rn: rune)?;
		case let r: rune =>
			yield rn is rune && rn: rune == r;
		case star =>
			abort();
		};
		if (!matches) {
			return false;
		};
	};

	// match the "sea of stars" in the middle
	s_copy = strings::iter(strings::slice(&s_copy, &s_last));
	p_copy = strings::iter(strings::slice(&p_copy, &p_last.0));
	for :outer (true) {
		p = p_copy;
		if (len(strings::iterstr(&p)) == 0) {
			return true;
		};
		s = s_copy;
		for (true) {
			let copy = s;
			let rn = strings::next(&copy);
			let matched = match (pat_next(&p, fl)?) {
			case end =>
				abort();
			case question =>
				yield rn is rune;
			case bracket =>
				yield rn is rune && match_bracket(&p, rn: rune)?;
			case let r: rune =>
				yield rn is rune && r == rn: rune;
			case star =>
				p_copy = p;
				s_copy = s;
				continue :outer;
			};
			if (!matched) {
				break;
			};
			s = copy;
		};
		match (strings::next(&s_copy)) {
		case done =>
			return false;
		case rune => void;
		};
	};
};

fn match_bracket(
	it: *strings::iterator,
	c: rune,
) (bool | errors::invalid | errors::unsupported) = {
	let old = *it;
	let first = advance_or_err(it)?;
	let inv = false;
	if (first == '^') {
		return errors::invalid;
	};
	if (first == '!') {
		inv = true;
		first = advance_or_err(it)?;
	};
	let found = (first != '[' && first == c);
	let last: (rune | void) = first;
	if (first == ']') {
		first = advance_or_err(it)?;
	};

	for (let r = first; true; r = advance_or_err(it)?) {
		switch (r) {
		case ']' =>
			break;
		case '-' =>
			let end = advance_or_err(it)?;
			if (end == ']') {
				// '-' at the end matches itself
				strings::prev(it);
				last = '-';
				found ||= (c == '-');
				continue;
			};
			match (last) {
			case void =>
				return errors::invalid;
			case let l: rune =>
				found ||= (l: u32 <= c: u32 && c: u32 <= end: u32);
				last = void; // forbid 'a-f-n'
			};
		case '[' =>
			let next_rune = advance_or_err(it)?;
			switch (next_rune) { // TODO localization
			case '=', '.' =>
				return errors::unsupported;
			case ':' =>
				let t = match_ctype(it, c)?;
				found ||= t;
			case =>
				strings::prev(it);
				found ||= (c == '[');
			};
			last = '[';
		case =>
			found ||= (c == r);
			last = r;
		};
	};

	let cnt = len(strings::iterstr(&old)) - len(strings::iterstr(it));
	if (last is rune && first == last: rune && cnt >= 4
			&& (first == '=' || first == '.' || first == ':')) {
		return errors::invalid;
	};
	return found ^^ inv;
};

fn match_ctype(it: *strings::iterator, c: rune) (bool | errors::invalid) = {
	let s = strings::iterstr(it);
	let i = 0z;
	for (let r = '\0'; r != ':'; i += 1) {
		r = advance_or_err(it)?;
		if (!ascii::valid(r)) {
			return errors::invalid;
		};
	};
	if (advance_or_err(it)? != ']') {
		return errors::invalid;
	};
	let name = strings::sub(s, 0, i - 1);
	const map: [_](str, *fn(rune) bool) = [
		("alnum", &ascii::isalnum), ("alpha", &ascii::isalpha),
		("blank", &ascii::isblank), ("cntrl", &ascii::iscntrl),
		("digit", &ascii::isdigit), ("graph", &ascii::isgraph),
		("lower", &ascii::islower), ("print", &ascii::isprint),
		("punct", &ascii::ispunct), ("space", &ascii::isspace),
		("upper", &ascii::isupper), ("xdigit",&ascii::isxdigit),
	];
	for (let i = 0z; i < len(map); i += 1) {
		if (map[i].0 == name) {
			return map[i].1(c);
		};
	};
	return errors::invalid;
};

fn pat_next(pat: *strings::iterator, fl: flag) (token | errors::invalid) = {
	let r = match (strings::next(pat)) {
	case done =>
		return end;
	case let r: rune =>
		yield r;
	};
	switch (r) {
	case '*' =>
		return star;
	case '?' =>
		return question;
	case '[' =>
		return bracket;
	case '\\' =>
		// TODO: remove ? (harec bug workaround)
		return if (fl & flag::NOESCAPE == 0) advance_or_err(pat)?
			else '\\';
	case =>
		return r;
	};
};

fn advance_or_err(it: *strings::iterator) (rune | errors::invalid) = {
	match (strings::next(it)) {
	case let r: rune =>
		return r;
	case done =>
		return errors::invalid;
	};
};
