// License: MPL-2.0
// (c) 2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use ascii;
use encoding::utf8;
use errors;
use strconv;
use strings;

// A string describing the error the occurred.
export type error = !str;

export type inst_lit = rune,
	inst_charset = struct { idx: size, is_positive: bool },
	inst_any = void,
	inst_split = size,
	inst_jump = size,
	inst_skip = void,
	inst_match = bool,
	inst_groupstart = void,
	inst_groupend = void,
	inst_repeat = struct {
		id: size,
		origin: size,
		min: (void | size),
		max: (void | size),
	};

export type inst = (inst_lit | inst_any | inst_split | inst_jump |
	inst_skip | inst_match | inst_charset |
	inst_groupstart | inst_groupend |
	inst_repeat);

// A (sub)match found as a result of matching a certain string against a regex.
export type matchgroup = struct {
	content: str,
	start: size,
	end: size,
};

type thread = struct {
	pc: size,
	start_idx: size,
	root_group: matchgroup,
	groups: []matchgroup,
	curr_group: matchgroup,
	curr_group_inited: bool,
	rep_counters: []size,
	matched: bool,
	failed: bool,
};

type newmatch = void;

export type charclass = enum {
	ALNUM, ALPHA, BLANK, CNTRL, DIGIT, GRAPH, LOWER, PRINT, PUNCT, SPACE,
	UPPER, XDIGIT,
};
export type charset = [](charset_lit_item | charset_range_item |
	charset_class_item),
	charset_lit_item = rune,
	charset_range_item = (u8, u8),
	charset_class_item = charclass;

const charclass_names: [](charclass, str) = [
	(charclass::ALNUM, ":alnum:]"),
	(charclass::ALPHA, ":alpha:]"),
	(charclass::BLANK, ":blank:]"),
	(charclass::CNTRL, ":cntrl:]"),
	(charclass::DIGIT, ":digit:]"),
	(charclass::GRAPH, ":graph:]"),
	(charclass::LOWER, ":lower:]"),
	(charclass::PRINT, ":print:]"),
	(charclass::PUNCT, ":punct:]"),
	(charclass::SPACE, ":space:]"),
	(charclass::UPPER, ":upper:]"),
	(charclass::XDIGIT, ":xdigit:]"),
];

const charclass_fns: [](charclass, *fn(c: rune) bool) = [
	(charclass::ALNUM, &ascii::isalnum),
	(charclass::ALPHA, &ascii::isalpha),
	(charclass::BLANK, &ascii::isblank),
	(charclass::CNTRL, &ascii::iscntrl),
	(charclass::DIGIT, &ascii::isdigit),
	(charclass::GRAPH, &ascii::isgraph),
	(charclass::LOWER, &ascii::islower),
	(charclass::PRINT, &ascii::isprint),
	(charclass::PUNCT, &ascii::ispunct),
	(charclass::SPACE, &ascii::isspace),
	(charclass::UPPER, &ascii::isupper),
	(charclass::XDIGIT, &ascii::isxdigit),
];
const multibyte_err: error = "Character ranges do not support characters larger than one byte.";

export type regex = struct {
	insts: []inst,
	charsets: []charset,
	n_reps: size,
};

// Frees the memory used by a regex.
export fn regex_finish(re: *regex) void = {
	free(re.insts);
	for (let i = 0z; i < len(re.charsets); i += 1) {
		free(re.charsets[i]);
	};
	free(re.charsets);
};

fn find_last_groupstart(insts: *[]inst) (size | error) = {
	for (let i = len(insts); i > 0; i -= 1) {
		if (insts[i - 1] is inst_groupstart) {
			return i - 1;
		};
	};
	return `Encountered ")" token without matching "("`: error;
};

fn handle_bracket(
	insts: *[]inst,
	r: rune,
	r_idx: *size,
	bracket_idx: *int,
	iter: *strings::iterator,
	charsets: *[]charset,
	skip_charclass_rest: *bool,
	is_charset_positive: *bool,
	in_bracket: *bool
) (void | error) = {
	const peek1 = strings::next(iter);
	const peek2 = strings::next(iter);
	const peek3 = strings::next(iter);
	if (!(peek1 is void)) {
		strings::prev(iter);
	};
	if (!(peek2 is void)) {
		strings::prev(iter);
	};
	if (!(peek3 is void)) {
		strings::prev(iter);
	};

	if (*bracket_idx == -1) {
		append(charsets, []);
	};
	*bracket_idx += 1;

	if (*skip_charclass_rest) {
		if (r == ']') {
			*skip_charclass_rest = false;
		};
		*r_idx += 1;
		return;
	};

	const is_range = peek1 is rune && peek1 as rune == '-'
		&& !(peek2 is void) && !(peek3 is void)
		&& !(peek2 as rune == ']');
	const range_end = peek2;
	const is_first_char = *bracket_idx == 0 || *bracket_idx == 1
		&& !*is_charset_positive;
	if (r == ']' && !is_first_char) {
		const newinst = inst_charset {
			idx = len(charsets) - 1,
			is_positive = *is_charset_positive,
		};
		append(insts, newinst);
		*in_bracket = false;
		*bracket_idx = -1;
		*is_charset_positive = true;
	} else if (r == '^' && *bracket_idx == 0) {
		*is_charset_positive = false;
	} else if (r == '[' && !(peek1 is void)
			&& peek1 as rune == ':') {
		const rest = strings::iterstr(iter);
		const n_cc = len(charclass_names);
		for (let cc_idx = 0z; cc_idx < n_cc; cc_idx += 1) {
			const cc = charclass_names[cc_idx];
			if (strings::hasprefix(rest, cc.1)) {
				append(charsets[len(charsets) - 1],
					cc.0: charset_class_item);
				*skip_charclass_rest = true;
				break;
			};
		};
		if (!*skip_charclass_rest) {
			return `Found "[:" in bracket expression and expected a character class such as [:alpha:], but none was found. If you did not mean to use a charclass, try ":["`: error;
		};
	} else if (is_range) {
		const start_enc = utf8::encoderune(r);
		if (len(start_enc) > 1) {
			return multibyte_err;
		};
		const start_b = start_enc[0];

		const end_enc = utf8::encoderune(range_end as rune);
		if (len(end_enc) > 1) {
			return multibyte_err;
		};
		const end_b = end_enc[0];

		if (end_b < start_b) {
			return `Found range in bracket expression where end character was before start character, e.g. "[b-a]"`: error;
		};

		append(charsets[len(charsets) - 1],
			(start_b, end_b): charset_range_item);
		strings::next(iter);
		strings::next(iter);
		*r_idx += 2;
	} else {
		append(charsets[len(charsets) - 1],
			r: charset_lit_item);
	};

	*r_idx += 1;
};

// Compiles a string containing a regular expression into a regex struct.
export fn compile(expr: str) (regex | error) = {
	let insts: []inst = [];
	let charsets: []charset = [];
	let iter = strings::iter(expr);
	let r_idx = 0z;
	let anchored = false;
	let curr_alt_jump_idx = -1;
	let in_bracket = false;
	let skip_charclass_rest = false;
	let bracket_idx = -1;
	let is_charset_positive = true;
	let n_reps = 0z;
	let n_groupstarts = 0;

	for (true) {
		const next = strings::next(&iter);

		if (r_idx == 0 && next is rune && next: rune != '^') {
				append(insts, void: inst_skip);
		};

		if (in_bracket) {
			if (next is void) {
				return `Found unterminated bracket expression, are you missing a closing "]"?`: error;
			};
			const r = next: rune;
			handle_bracket(&insts, r, &r_idx, &bracket_idx, &iter,
				&charsets, &skip_charclass_rest,
				&is_charset_positive,
				&in_bracket)?;
			continue;
		};

		const r = match (next) {
		case void =>
			if (n_groupstarts > 0) {
				return "Expression ended, but there were still unclosed groups": error;
			};
			break;
		case let r: rune => yield r;
		};
		switch (r) {
		case '\\' =>
			const peek1 = strings::next(&iter);
			if (peek1 is void) {
				return "Found an escaping backslash, but there was nothing to escape": error;
			} else {
				append(insts, (peek1 as rune): inst_lit);
				r_idx += 1;
			};
		case '^' =>
			if (r_idx != 0) {
				return `Anchor character "^" may only occur at the start of the expression`: error;
			};
		case '$' =>
			if (r_idx != len(expr) - 1) {
				return `Anchor character "$" may only occur at the end of the expression`: error;
			};
			anchored = true;
		case '[' =>
			in_bracket = true;
		case ']' =>
			if (in_bracket) {
				in_bracket = false;
			} else {
				append(insts, r: inst_lit);
			};
		case '(' =>
			append(insts, void: inst_groupstart);
			n_groupstarts += 1;
		case ')' =>
			if (n_groupstarts == 0) {
				return "Tried to close group but none was open": error;
			};
			n_groupstarts -= 1;
			append(insts, void: inst_groupend);
			if (curr_alt_jump_idx != -1) {
				assert(insts[curr_alt_jump_idx] is inst_jump);
				insts[curr_alt_jump_idx] =
					(len(insts) - 1): inst_jump;
				curr_alt_jump_idx = -1;
			};
		case '|' =>
			append(insts, 9999999: inst_jump);
			const origin = find_last_groupstart(&insts)? + 1;
			const newinst = (len(insts) + 1): inst_split;
			insert(insts[origin], newinst);
			curr_alt_jump_idx = (len(insts) - 1): int;
		case '{' =>
			let origin = len(insts) - 1;
			if (insts[origin] is inst_groupend) {
				origin = find_last_groupstart(&insts)?;
			};
			const rest = strings::iterstr(&iter);
			const rep_parts = parse_repetition(rest)?;
			const can_skip = rep_parts.0 == 0;
			const min = if (rep_parts.0 == 0) {
				yield 1z;
			} else {
				yield rep_parts.0;
			};
			if (can_skip) {
				insert(insts[origin],
					len(insts) + 2: inst_split);
				origin += 1;
			};
			const newinst = inst_repeat {
				id = n_reps,
				origin = origin,
				min = min,
				max = rep_parts.1,
			};
			for (let i = 0z; i <= rep_parts.2; i += 1) {
				strings::next(&iter);
				r_idx += 1;
			};
			append(insts, newinst);
			n_reps += 1;
		case '?' =>
			if (r_idx == 0 || len(insts) == 0) {
				return `Found "?" but there was nothing before it`: error;
			};
			let term_start_idx = len(insts) - 1;
			match (insts[term_start_idx]) {
			case (inst_lit | inst_charset | inst_any) => void;
			case inst_groupend =>
				term_start_idx = find_last_groupstart(&insts)?;
			case inst_groupstart =>
				return `Found "?" but it was in an empty group`: error;
			case =>
				return `Invalid use of "?"`: error;
			};
			const after_idx = len(insts) + 1;
			insert(insts[term_start_idx], after_idx: inst_split);
		case '*' =>
			if (r_idx == 0 || len(insts) == 0) {
				return `Found "*" but there was nothing before it`: error;
			};
			const new_inst_offset = 1z;
			const jump_idx = len(insts) + new_inst_offset;
			const after_idx = jump_idx + 1z;
			let term_start_idx = len(insts) - 1z;
			match (insts[term_start_idx]) {
			case (inst_lit | inst_charset | inst_any) => void;
			case inst_groupend =>
				term_start_idx = find_last_groupstart(&insts)?;
			case inst_groupstart =>
				return `Found "*" but it was in an empty group`: error;
			case =>
				return `Invalid use of "*"`: error;
			};
			const split_idx = term_start_idx;
			term_start_idx += new_inst_offset;
			insert(insts[split_idx], after_idx: inst_split);
			append(insts, split_idx: inst_jump);
		case '+' =>
			if (r_idx == 0 || len(insts) == 0) {
				return `Found "+" but there was nothing before it`: error;
			};
			let term_start_idx = len(insts) - 1;
			match (insts[term_start_idx]) {
			case (inst_lit | inst_charset | inst_any) => void;
			case inst_groupend =>
				term_start_idx = find_last_groupstart(&insts)?;
			case inst_groupstart =>
				return `Found "+" but it was in an empty group`: error;
			case =>
				return `Invalid use of "+"`: error;
			};
			append(insts, term_start_idx: inst_split);
		case '.' =>
			append(insts, void: inst_any);
		case =>
			append(insts, r: inst_lit);
		};
		r_idx += 1;
	};

	append(insts, anchored: inst_match);

	return regex {
		insts = insts,
		charsets = charsets,
		n_reps = n_reps,
	};
};

fn parse_repetition(
	s: str
) (((void | size), (void | size), size) | error) = {
	const first_comma = strings::index(s, ",");
	const first_endbrace = strings::index(s, "}");
	if (first_endbrace is void) {
		return "Invalid repetition value": error;
	};
	const first_endbrace = first_endbrace as size;

	let min_str = "";
	let max_str = "";
	let is_single_arg = false;
	if (first_comma is void || first_endbrace < first_comma as size) {
		const cut = strings::cut(s, "}");
		min_str = cut.0;
		max_str = cut.0;
		is_single_arg = true;
	} else {
		const cut = strings::cut(s, ",");
		min_str = cut.0;
		max_str = strings::cut(cut.1, "}").0;
	};

	let min: (void | size) = void;
	let max: (void | size) = void;

	if (len(min_str) > 0) {
		min = match (strconv::stoi(min_str)) {
		case let res: int =>
			yield if (res < 0) {
				return `Only positive integers are allowed inside "{}"`: error;
			} else {
				yield res: size;
			};
		case => return "Invalid repetition minimum value": error;
		};
	};

	if (len(max_str) > 0) {
		max = match (strconv::stoi(max_str)) {
		case let res: int =>
			yield if (res < 0) {
				return `Only positive integers are allowed inside "{}"`: error;
			} else {
				yield res: size;
			};
		case => return "Invalid repetition maximum value": error;
		};
	};

	if (len(min_str) == 0 && len(max_str) > 0) {
		return "Invalid repetition minimum value": error;
	};

	const rep_len = if (is_single_arg) {
		yield len(min_str);
	} else {
		yield len(min_str) + 1 + len(max_str);
	};
	return (min, max, rep_len);
};

fn delete_thread(i: size, threads: *[]thread) void = {
	free(threads[i].groups);
	free(threads[i].rep_counters);
	delete(threads[i]);
};

fn is_consuming_inst(a: inst) bool = {
	return a is (inst_lit | inst_any | inst_charset);
};

fn add_thread(threads: *[]thread, parent_idx: size, new_pc: size) void = {
	// Do not add this thread if there is already another thread with
	// the same PC
	for (let i = 0z; i < len(threads); i += 1) {
		if (threads[i].pc == new_pc
				&& !threads[i].matched
				&& threads[i].start_idx
				< threads[parent_idx].start_idx) {
			return;
		};
	};

	append(threads, thread {
		pc = new_pc,
		start_idx = threads[parent_idx].start_idx,
		curr_group = threads[parent_idx].curr_group,
		curr_group_inited = threads[parent_idx].curr_group_inited,
		matched = threads[parent_idx].matched,
		failed = threads[parent_idx].failed,
		groups = alloc(threads[parent_idx].groups...),
		rep_counters = alloc(threads[parent_idx].rep_counters...),
		...
	});
};

fn run_thread(
	i: size,
	re: regex,
	string: str,
	threads: *[]thread,
	r_or_end: (rune | void),
	str_idx: int
) (void | error | newmatch) = {
	if (threads[i].matched) {
		return;
	};
	for (!is_consuming_inst(re.insts[threads[i].pc])) {
		match (re.insts[threads[i].pc]) {
		case inst_lit => abort();
		case inst_any => abort();
		case inst_split =>
			const new_pc = re.insts[threads[i].pc]: inst_split: size;
			add_thread(threads, i, new_pc);
			threads[i].pc += 1;
		case inst_jump =>
			threads[i].pc = re.insts[threads[i].pc]: inst_jump: size;
		case inst_skip =>
			const new_pc = threads[i].pc + 1;
			threads[i].start_idx = str_idx: size;
			add_thread(threads, i, new_pc);
			break;
		case let anchored: inst_match =>
			// Do not match if we need an end-anchored match, but we
			// have not exhausted our string
			if (anchored && !(r_or_end is void)) {
				threads[i].failed = true;
				return;
			};
			threads[i].root_group = matchgroup {
				start = threads[i].start_idx,
				end = str_idx: size,
				// TODO: This is a perf issue for large strings
				content = strings::sub(string,
					threads[i].start_idx,
					str_idx: size),
			};
			threads[i].matched = true;
			return newmatch;
		case inst_groupstart =>
			if (threads[i].curr_group_inited) {
				return "Found nested capture groups in expression, which are not supported": error;
			};
			threads[i].curr_group.start = str_idx: size;
			threads[i].curr_group_inited = true;
			threads[i].pc += 1;
		case inst_groupend =>
			if (!threads[i].curr_group_inited) {
				return `Found a groupend token ")" without having previously seen a groupstart token "("`: error;
			};
			threads[i].curr_group.end = str_idx: size;
			// TODO: This is a perf issue for large strings
			threads[i].curr_group.content = strings::sub(string,
				threads[i].curr_group.start,
				threads[i].curr_group.end);
			append(threads[i].groups, threads[i].curr_group);
			threads[i].curr_group = matchgroup { ... };
			threads[i].curr_group_inited = false;
			threads[i].pc += 1;
		case let ir: inst_repeat =>
			assert(ir.id < len(threads[i].rep_counters));
			threads[i].rep_counters[ir.id] += 1;
			if (ir.max is size
					&& threads[i].rep_counters[ir.id]
					> ir.max as size) {
				threads[i].failed = true;
				return;
			};
			const new_pc = threads[i].pc + 1;
			threads[i].pc = ir.origin;
			if (ir.min is void
					|| threads[i].rep_counters[ir.id]
					>= ir.min as size) {
				add_thread(threads, i, new_pc);
			};
		};
	};

	// From now on, we're only matching consuming instructions, and these
	// can't do anything without another rune.
	if (r_or_end is void) {
		threads[i].failed = true;
		return;
	};

	const r = r_or_end as rune;

	match (re.insts[threads[i].pc]) {
	case inst_skip => return;
	case let lit: inst_lit =>
		if (r != lit) {
			threads[i].failed = true;
		};
	case inst_any => void;
	case let cs: inst_charset =>
		const charset = re.charsets[cs.idx];
		// Disprove the match if we're looking for a negative match
		// Prove the match if we're looking for a positive match
		let matched = !cs.is_positive;
		for (let i = 0z; i < len(charset); i += 1) match (charset[i]) {
		case let lit: charset_lit_item =>
			if (r == lit) {
				// Succeeded if positive match
				// Failed if negative match
				matched = cs.is_positive;
				break;
			};
		case let range: charset_range_item =>
			const r_enc = utf8::encoderune(r);
			if (len(r_enc) > 1) {
				return multibyte_err;
			};
			const r_b = r_enc[0];
			if (r_b >= range.0 && r_b <= range.1) {
				// Succeeded if positive match
				// Failed if negative match
				matched = cs.is_positive;
				break;
			};
		case let class: charset_class_item =>
			const n_cc = len(charclass_fns);
			for (let cc_idx = 0z; cc_idx < n_cc; cc_idx += 1) {
				const cc = charclass_fns[cc_idx];
				if (cc.0 == class: charclass && cc.1(r)) {
					// Succeeded if positive match
					// Failed if negative match
					matched = cs.is_positive;
					break;
				};
			};
		};
		if (!matched) {
			threads[i].failed = true;
		};
	};

	threads[i].pc += 1;
};

// Attempts to match a regular expression against a string and returns the
// either the longest leftmost match or all matches.
fn search(
	re: regex,
	string: str,
	str_iter: *strings::iterator,
	str_idx: *int
) (void | []matchgroup | error) = {
	let threads: []thread = alloc([
		thread { groups = [], ... }
	]);
	if (re.n_reps > 0) {
		threads[0].rep_counters = alloc([0...], re.n_reps);
	};
	defer {
		for (let i = 0z; i < len(threads); i += 1) {
			free(threads[i].groups);
			free(threads[i].rep_counters);
		};
		free(threads);
	};

	let first_match_idx: (void | size) = void;

	for (true) {
		if (len(threads) == 0) {
			return void;
		};

		let all_matched = true;
		for (let i = 0z; i < len(threads); i += 1) {
			if (!threads[i].matched) {
				all_matched = false;
				break;
			};
		};

		if (all_matched) {
			let best_len = 0z;
			let best_n_groups = 0z;
			let best_idx = 0z;
			for (let i = 0z; i < len(threads); i += 1) {
				let match_len = threads[i].root_group.end
					- threads[i].root_group.start;
				const is_better = match_len > best_len
					|| match_len == best_len
					&& len(threads[i].groups)
					> best_n_groups;
				if (is_better) {
					best_len = match_len;
					best_idx = i;
					best_n_groups = len(threads[i].groups);
				};
			};
			let res: []matchgroup = alloc([],
				len(threads[best_idx].groups) + 1);
			append(res, threads[best_idx].root_group);
			append(res, threads[best_idx].groups...);
			return res;
		};

		const r_or_end = strings::next(str_iter);
		*str_idx += 1;

		for (let i = 0z; i < len(threads); i += 1) {
			const res = run_thread(i, re, string, &threads,
				r_or_end, *str_idx)?;
			const matchlen = threads[i].root_group.end
				- threads[i].root_group.start;
			const is_better = res is newmatch && matchlen > 0
				&& (first_match_idx is void
					|| threads[i].start_idx
						< first_match_idx as size);
			if (is_better) {
				first_match_idx = threads[i].start_idx;
			};
		};

		// When we only want the leftmost match, delete all threads that
		// start after the earliest non-zero-length matched thread
		if (first_match_idx is size) {
			for (let i = 0z; i < len(threads); i += 1) {
				if (threads[i].start_idx
						> first_match_idx as size) {
					threads[i].failed = true;
				};
			};
		};

		// Delete threads that have a PC that has already been
		// encountered in previous threads. Prioritise threads that
		// have an earlier start_idx, and threads that were added
		// earlier.
		for (let i = 0i64; i < len(threads): i64 - 1; i += 1) {
			for (let j = i + 1; j < len(threads): i64; j += 1) {
				const same_pc = threads[i].pc == threads[j].pc;
				const none_matched = !threads[j].matched
					&& !threads[i].matched;
				if (same_pc && none_matched) {
					if (threads[i].start_idx
							<= threads[j].start_idx) {
						delete_thread(j: size, &threads);
						j -= 1;
					} else {
						delete_thread(i: size, &threads);
						i -= 1;
						break;
					};
				};
			};
		};

		for (let i = 0z; i < len(threads); i += 1) {
			if (threads[i].failed) {
				delete_thread(i, &threads);
				i -= 1;
			};
		};
	};

	return void;
};


// Attempts to match a regular expression against a string and returns the
// longest leftmost match, or void if there is no match.
export fn find(re: regex, string: str) (void | []matchgroup | error) = {
	let str_idx = -1;
	let str_iter = strings::iter(string);
	return search(re, string, &str_iter, &str_idx);
};

// Attempts to match a regular expression against a string and returns all
// non-overlapping matches, or void if there are no matches.
export fn findall(re: regex, string: str) (void | [][]matchgroup | error) = {
	let res: [][]matchgroup = [];
	let str_idx = -1;
	let str_iter = strings::iter(string);
	for (true) {
		const findres = search(re, string, &str_iter, &str_idx)?;
		match (findres) {
		case let m: []matchgroup =>
			append(res, m);
			assert(str_idx: size >= m[0].end);
			for (str_idx: size > m[0].end) {
				strings::prev(&str_iter);
				str_idx -= 1;
			};
			if (str_idx: size >= len(string)) {
				break;
			};
		case void => break;
		};
	};
	if (len(res) == 0) {
		return void;
	};
	return res;
};

// Frees all the matches in a slice and the slice itself.
export fn freeall(s: [][]matchgroup) void = {
	for (let i = 0z; i < len(s); i += 1) {
		free(s[i]);
	};
	free(s);
};
