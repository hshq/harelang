use ascii;
use errors;
use strings;
use sort;

// A set of flags that alter the matching behavior of [[fnmatch::fnmatch]]
export type flags = enum uint {
	NONE = 0,

	// If this flag is set, slashes in the string will only be matched by
	// literal slashes in the pattern
	PATHNAME = 1u << 0,
	// If this flag is set, backslash will be treated as an ordinary
	// character
	NOESCAPE = 1u << 1,
	// If this flag is set, a '.' at the beginning of the string can only
	// be matched by a literal '.' in the pattern. If
	// [[fnmatch::flags::PATHNAME]] is set simultaneously, this behavior also
	// apply to any periods immediately following a slash.
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
// - '[' and ']' enclose a bracket expression. Matching rules for bracket expressions are identical to those of bracket subexpressions in regular expressions, except that '!' takes the role of '^' when placed right after the opening '['.
// - '\' escapes the following character, e. g. "\*" only matches literal '*' and has no special meaning
// - all other characters only match themselves
//
// A set of flags that alter the matching behavior may be passed to
// [[fnmatch::fnmatch]]. For an explanation of their meaning, see
// [[fnmatch::flags]].
export fn fnmatch(pattern: str, string: str, flag: flags...) bool = {
	let fl: flags = 0;
	for (let i = 0z; i < len(flag); i += 1) {
		fl |= flag[i];
	};
	if (fl & flags::PATHNAME != 0) {
		match (fnmatch_pathname(pattern, string, fl)) {
		case b: bool =>
			return b;
		case =>
			return false;
		};
	} else {
		match (fnmatch_internal(pattern, string, fl)) {
		case b: bool =>
			return b;
		case =>
			return false;
		};
	};
};

// Split the pattern and the string on every '/' and process each part
// separately
fn fnmatch_pathname(
	pattern: str,
	string: str,
	fl: flags,
) (bool | errors::unsupported | errors::invalid) = {
	let tok = strings::tokenize(string, "/");
	let p_iter = strings::iter(pattern);
	let start = p_iter;
	for (true) :outer {
		start = p_iter;
		for (true) match (pat_next(&p_iter, fl)?) {
		case end =>
			break :outer;
		case r: rune =>
			if (r == '/') break;
		case bracket =>
			match_bracket(&p_iter, '\0')?;
		case (question | star) => void;
		};
		let s = match (strings::next_token(&tok)) {
		case void =>
			return false;
		case s: str =>
			yield s;
		};
		strings::prev(&p_iter);
		let p = cut_tail(strings::iter_str(&start), &p_iter);
		strings::next(&p_iter);
		if (!fnmatch_internal(p, s, fl)?) {
			return false;
		};
	};
	let s = match(strings::next_token(&tok)) {
	case void =>
		return false;
	case s: str =>
		yield s;
	};
	let p = strings::iter_str(&start);
	return fnmatch_internal(p, s, fl)? && strings::next_token(&tok) is void;
};

// Core fnmatch function, implementing the "Sea of stars" algorithm that is also
// used in Musl libc. First we make sure the parts before the first star and
// after the last star produce exact matches and then proceed to greedily match
// everything in between. Because of the greedy property this algorithm does not
// have exponential corner cases.
fn fnmatch_internal(
	pattern: str,
	string: str,
	fl: flags,
) (bool | errors::invalid | errors::unsupported) = {
	if (fl & flags::PERIOD != 0) {
		if (strings::has_prefix(string, ".")
				&& !strings::has_prefix(pattern, ".")) {
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
			return rn is void;
		case question =>
			yield rn is rune;
		case bracket =>
			yield rn is rune && match_bracket(&p, rn: rune)?;
		case r: rune =>
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
		strings::prev(&s);
	};

	// match the tail
	let s_last = s;
	for (true) {
		let rn = strings::next(&s);
		let matches = match (pat_next(&p, fl)?) {
		case end =>
			if (rn is void) {
				break;
			} else {
				return false;
			};
		case question =>
			yield rn is rune;
		case bracket =>
			yield rn is rune && match_bracket(&p, rn: rune)?;
		case r: rune =>
			yield rn is rune && rn: rune == r;
		case star =>
			abort();
		};
		if (!matches) {
			return false;
		};
	};

	// match the "sea of stars" in the middle
	s_copy = strings::iter(cut_tail(strings::iter_str(&s_copy), &s_last));
	p_copy = strings::iter(cut_tail(strings::iter_str(&p_copy), &p_last.0));
	for (true) :outer {
		p = p_copy;
		if (len(strings::iter_str(&p)) == 0) {
			return true;
		};
		s = s_copy;
		for (true) :inner {
			let copy = s;
			let rn = strings::next(&copy);
			let matched = match (pat_next(&p, fl)?) {
			case end =>
				abort();
			case question =>
				yield rn is rune;
			case bracket =>
				yield rn is rune && match_bracket(&p, rn: rune)?;
			case r: rune =>
				yield rn is rune && r == rn: rune;
			case star =>
				p_copy = p;
				s_copy = s;
				continue :outer;
			};
			if (!matched) {
				break :inner;
			};
			s = copy;
		};
		match (strings::next(&s_copy)) {
		case void =>
			return false;
		case rune => void;
		};
	};
	abort();
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
	let found = (first == c);
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
				strings::push(it, ']');
				last = '-';
				found ||= (c == '-');
				continue;
			};
			if (last is void) {
				return errors::invalid;
			};
			let l = last: rune;
			found ||= (l: u32 <= c: u32 && c: u32 <= end: u32);
			last = void; // forbid 'a-f-n'
		case '[' =>
			let next_rune = advance_or_err(it)?;
			switch (next_rune) { // TODO localization
			case '=', '.' =>
				return errors::unsupported;
			case ':' =>
				let t = match_ctype(it, c)?;
				found ||= t;
			case =>
				strings::push(it, next_rune);
				found ||= (c == '[');
			};
			last = '[';
		case =>
			found ||= (c == r);
			last = r;
		};
	};

	let cnt = len(strings::iter_str(&old)) - len(strings::iter_str(it));
	if (last is rune && first == last: rune && cnt >= 4) {
		switch (first) {
		case '=', '.', ':' =>
			return errors::invalid;
		case => void;
		};
	};
	return found ^^ inv;
};

fn match_ctype(it: *strings::iterator, c: rune) (bool | errors::invalid) = {
	let s = strings::iter_str(it);
	let i = 0z;
	for (let r = '\0'; r != ':'; i+= 1) {
		r = advance_or_err(it)?;
		if (!ascii::isascii(r)) {
			return errors::invalid;
		};
	};
	if (advance_or_err(it)? != ']') {
		return errors::invalid;
	};
	let name = strings::sub(s, 0, i - 1);
	match (ctype_name_to_func(name)) {
	case null =>
		return errors::invalid;
	case f: *fn(c: rune) bool =>
		return f(c);
	};
};

type funcmap = (str, *fn(c: rune) bool);

fn cmp(a: const *void, b: const *void) int = {
	return ascii::strcmp((a: *funcmap).0, *(b: const *str)): int;
};

fn ctype_name_to_func(name: str) nullable *fn(c: rune) bool = {
	const map: [_]funcmap = [
		("alnum", &ascii::isalnum), ("alpha", &ascii::isalpha),
		("blank", &ascii::isblank), ("cntrl", &ascii::iscntrl),
		("digit", &ascii::isdigit), ("graph", &ascii::isgraph),
		("lower", &ascii::islower), ("print", &ascii::isprint),
		("punct", &ascii::ispunct), ("space", &ascii::isspace),
		("upper", &ascii::isupper), ("xdigit",&ascii::isxdigit),
	];
	match (sort::search(map, size(funcmap), &name, &cmp)) {
	case null =>
		return null: nullable *fn(c: rune) bool;
	case p: *void =>
		return (p: *funcmap).1;
	};
};

fn pat_next(pat: *strings::iterator, fl: flags) (token | errors::invalid) = {
	let r = match (strings::next(pat)) {
	case void =>
		return end;
	case r: rune =>
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
		return if (fl & flags::NOESCAPE == 0) advance_or_err(pat)?
			else '\\': token; // TODO: remove cast (harec bug workaround)
	case =>
		return r;
	};
};

fn advance_or_err(it: *strings::iterator) (rune | errors::invalid) = {
	match (strings::next(it)) {
	case r: rune =>
		return r;
	case void =>
		return errors::invalid;
	};
};

fn cut_tail(s: str, it: *strings::iterator) str = {
	let s_len = len(s), t_len = len(strings::iter_str(it));
	let b = strings::toutf8(s);
	return strings::fromutf8(b[..s_len - t_len]);
};

