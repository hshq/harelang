// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use encoding::utf8;
use io;
use memio;
use strconv;
use strings;
use types;

// An error string describing a compilation error.
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

// The resulting match of a [[regex]] applied to a string.
//
// The first [[capture]] corresponds to the implicit zeroth capture group,
// i.e. the whole expression.
//
// The rest of the [[capture]]s correspond to the rest of the capture groups,
// i.e. the sub-expressions.
export type result = []capture;

// A (sub)match corresponding to a regular expression's capture group.
export type capture = struct {
	content: str,
	start: size,
	start_bytesize: size,
	end: size,
	end_bytesize: size
};

type thread = struct {
	pc: size,
	start_idx: size,
	start_bytesize: size,
	root_capture: capture,
	captures: []capture,
	curr_capture: capture,
	curr_capture_inited: bool,
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
	charset_range_item = (u32, u32),
	charset_class_item = *fn(c: rune) bool;

const charclass_map: [](str, *fn(c: rune) bool) = [
	(":alnum:]", &ascii::isalnum),
	(":alpha:]", &ascii::isalpha),
	(":blank:]", &ascii::isblank),
	(":cntrl:]", &ascii::iscntrl),
	(":digit:]", &ascii::isdigit),
	(":graph:]", &ascii::isgraph),
	(":lower:]", &ascii::islower),
	(":print:]", &ascii::isprint),
	(":punct:]", &ascii::ispunct),
	(":space:]", &ascii::isspace),
	(":upper:]", &ascii::isupper),
	(":xdigit:]", &ascii::isxdigit),
];

export type regex = struct {
	insts: []inst,
	charsets: []charset,
	n_reps: size,
};

// Frees resources associated with a [[regex]].
export fn finish(re: *regex) void = {
	free(re.insts);
	for (let charset .. re.charsets) {
		free(charset);
	};
	free(re.charsets);
};

fn find_last_groupstart(insts: *[]inst) (size | error) = {
	for (let i = len(insts); i > 0; i -= 1) {
		if (insts[i - 1] is inst_groupstart) {
			return i - 1;
		};
	};
	return `Unmatched ')'`: error;
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
	if (!(peek1 is done)) {
		strings::prev(iter);
	};
	if (!(peek2 is done)) {
		strings::prev(iter);
	};
	if (!(peek3 is done)) {
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
		&& !(peek2 is done) && !(peek3 is done)
		&& !(peek2 as rune == ']');
	const range_end = peek2;
	const is_first_char = *bracket_idx == 0 || *bracket_idx == 1
		&& !*is_charset_positive;

	if (r == '\\') {
		if (peek1 is done) {
			return `Trailing backslash '\'`: error;
		} else {
			append(charsets[len(charsets) - 1],
				peek1: charset_lit_item);
			strings::next(iter);
			*r_idx += 1;
		};
	} else if (r == ']' && !is_first_char) {
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
	} else if (r == '[' && !(peek1 is done)
			&& peek1 as rune == ':') {
		const rest = strings::iterstr(iter);
		const n_cc = len(charclass_map);
		for (let cc_idx = 0z; cc_idx < n_cc; cc_idx += 1) {
			if (strings::hasprefix(rest, charclass_map[cc_idx].0)) {
				append(charsets[len(charsets) - 1],
					charclass_map[cc_idx].1);
				*skip_charclass_rest = true;
				break;
			};
		};
		if (!*skip_charclass_rest) {
			return `No character class after '[:'`: error;
		};
	} else if (is_range) {
		const start_b = r: u32;
		const end_b = range_end as rune: u32;

		if (end_b < start_b) {
			return `Descending bracket expression range '[z-a]'`: error;
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

// Compiles a regular expression string into a [[regex]].
export fn compile(expr: str) (regex | error) = {
	let insts: []inst = [];
	let charsets: []charset = [];
	let iter = strings::iter(expr);
	let r_idx = 0z;
	let anchored = false;
	let jump_idxs: []size = [];
	let in_bracket = false;
	let skip_charclass_rest = false;
	let bracket_idx = -1;
	let is_charset_positive = true;
	let n_reps = 0z;
	let n_groupstarts = 0;

	for (true) {
		const next = strings::next(&iter);

		if (r_idx == 0 && next is rune && next: rune != '^') {
			append(insts, inst_skip);
		};

		if (in_bracket) {
			if (next is done) {
				return `Unmatched '['`: error;
			};
			const r = next: rune;
			handle_bracket(&insts, r, &r_idx, &bracket_idx, &iter,
				&charsets, &skip_charclass_rest,
				&is_charset_positive,
				&in_bracket)?;
			continue;
		};

		const r = match (next) {
		case done =>
			if (n_groupstarts > 0) {
				return `Unmatched '('`: error;
			};
			break;
		case let r: rune => yield r;
		};
		switch (r) {
		case '\\' =>
			const peek1 = strings::next(&iter);
			if (peek1 is done) {
				return `Trailing backslash '\'`: error;
			} else {
				append(insts, (peek1 as rune): inst_lit);
				r_idx += 1;
			};
		case '^' =>
			if (r_idx != 0) {
				return `Anchor '^' not at start`: error;
			};
		case '$' =>
			if (r_idx != len(expr) - 1) {
				return `Anchor '$' not at end`: error;
			};
			anchored = true;
		case '[' =>
			in_bracket = true;
		case ']' =>
			append(insts, r: inst_lit);
		case '(' =>
			if (n_groupstarts > 0) {
				return `Nested capture groups are unsupported`: error;
			};
			append(insts, inst_groupstart);
			n_groupstarts += 1;
		case ')' =>
			if (n_groupstarts == 0) {
				return `Unmatched ')'`: error;
			};
			n_groupstarts -= 1;
			append(insts, inst_groupend);
			for (let jump_idx .. jump_idxs) {
				assert(insts[jump_idx] is inst_jump);
				insts[jump_idx] = (len(insts) - 1): inst_jump;
			};
			jump_idxs = [];
		case '|' =>
			append(insts, types::SIZE_MAX: inst_jump);
			const origin = match (find_last_groupstart(&insts)) {
			case error =>
				yield 0z;
			case let sz: size =>
				yield sz + 1;
			};
			const newinst = (len(insts) + 1): inst_split;
			// add split after last jump (if any) or at origin
			const split_idx = if (len(jump_idxs) > 0)
				jump_idxs[len(jump_idxs) - 1] + 1 else origin;
			insert(insts[split_idx], newinst);
			append(jump_idxs, len(insts) - 1);
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
				return `Unused '?'`: error;
			};
			let term_start_idx = len(insts) - 1;
			match (insts[term_start_idx]) {
			case (inst_lit | inst_charset | inst_any) => void;
			case inst_groupend =>
				term_start_idx = find_last_groupstart(&insts)?;
			case inst_groupstart =>
				return `Unused '?'`: error;
			case =>
				return `Misused '?'`: error;
			};
			const after_idx = len(insts) + 1;
			insert(insts[term_start_idx], after_idx: inst_split);
		case '*' =>
			if (r_idx == 0 || len(insts) == 0) {
				return `Unused '*'`: error;
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
				return `Unused '*'`: error;
			case =>
				return `Misused '*'`: error;
			};
			const split_idx = term_start_idx;
			term_start_idx += new_inst_offset;
			insert(insts[split_idx], after_idx: inst_split);
			append(insts, split_idx: inst_jump);
		case '+' =>
			if (r_idx == 0 || len(insts) == 0) {
				return `Unused '+'`: error;
			};
			let term_start_idx = len(insts) - 1;
			match (insts[term_start_idx]) {
			case (inst_lit | inst_charset | inst_any) => void;
			case inst_groupend =>
				term_start_idx = find_last_groupstart(&insts)?;
			case inst_groupstart =>
				return `Unused '+'`: error;
			case =>
				return `Misused '+'`: error;
			};
			append(insts, term_start_idx: inst_split);
		case '.' =>
			append(insts, inst_any);
		case =>
			append(insts, r: inst_lit);
		};
		r_idx += 1;
	};

	// handle whole expression alternation
	for (let jump_idx .. jump_idxs) {
		assert(insts[jump_idx] is inst_jump);
		insts[jump_idx] = len(insts): inst_jump;
	};
	jump_idxs = [];

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
		return `Repetition expression syntax error '{n}'`: error;
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
				return `Negative repetition count '{-n}'`: error;
			} else {
				yield res: size;
			};
		case => return `Repetition expression syntax error '{n}'`: error;
		};
	} else {
		min = 0;
	};

	if (len(max_str) > 0) {
		max = match (strconv::stoi(max_str)) {
		case let res: int =>
			yield if (res < 0) {
				return `Negative repetition count '{-n}'`: error;
			} else {
				yield res: size;
			};
		case => return `Repetition expression syntax error '{n}'`: error;
		};
	};

	const rep_len = if (is_single_arg) {
		yield len(min_str);
	} else {
		yield len(min_str) + 1 + len(max_str);
	};
	return (min, max, rep_len);
};

fn delete_thread(i: size, threads: *[]thread) void = {
	free(threads[i].captures);
	free(threads[i].rep_counters);
	delete(threads[i]);
};

fn is_consuming_inst(a: inst) bool = {
	return a is (inst_lit | inst_any | inst_charset);
};

fn add_thread(threads: *[]thread, parent_idx: size, new_pc: size) void = {
	// Do not add this thread if there is already another thread with
	// the same PC
	for (let thread &.. *threads) {
		if (thread.pc == new_pc	&& !thread.matched
				&& thread.start_idx
				< threads[parent_idx].start_idx) {
			return;
		};
	};

	append(threads, thread {
		pc = new_pc,
		start_idx = threads[parent_idx].start_idx,
		start_bytesize = threads[parent_idx].start_bytesize,
		curr_capture = threads[parent_idx].curr_capture,
		curr_capture_inited = threads[parent_idx].curr_capture_inited,
		matched = threads[parent_idx].matched,
		failed = threads[parent_idx].failed,
		captures = alloc(threads[parent_idx].captures...),
		rep_counters = alloc(threads[parent_idx].rep_counters...),
		...
	});
};

fn run_thread(
	i: size,
	re: *regex,
	string: str,
	threads: *[]thread,
	r_or_end: (rune | io::EOF),
	str_idx: size,
	str_bytesize: size
) (void | newmatch) = {
	const str_bytes = strings::toutf8(string);
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
			threads[i].start_idx = str_idx;
			threads[i].start_bytesize = str_bytesize;
			add_thread(threads, i, new_pc);
			break;
		case let anchored: inst_match =>
			// Do not match if we need an end-anchored match, but we
			// have not exhausted our string
			if (anchored && !(r_or_end is io::EOF)) {
				threads[i].failed = true;
				return;
			};
			const content = strings::fromutf8_unsafe(str_bytes[
				threads[i].start_bytesize..str_bytesize]);
			threads[i].root_capture = capture {
				start = threads[i].start_idx,
				start_bytesize = threads[i].start_bytesize,
				end = str_idx,
				end_bytesize = str_bytesize,
				content = content,
			};
			threads[i].matched = true;
			return newmatch;
		case inst_groupstart =>
			assert(!threads[i].curr_capture_inited, "Found nested capture groups in expression, which are not supported");
			threads[i].curr_capture.start = str_idx;
			threads[i].curr_capture.start_bytesize = str_bytesize;
			threads[i].curr_capture_inited = true;
			threads[i].pc += 1;
		case inst_groupend =>
			assert(threads[i].curr_capture_inited, `Found a groupend token ")" without having previously seen a groupstart token "(". Please report this as a bug`);
			threads[i].curr_capture.end = str_idx;
			threads[i].curr_capture.end_bytesize = str_bytesize;
			threads[i].curr_capture.content =
				strings::fromutf8_unsafe(str_bytes[
					threads[i].curr_capture.start_bytesize..
					threads[i].curr_capture.end_bytesize]);
			append(threads[i].captures, threads[i].curr_capture);
			threads[i].curr_capture = capture { ... };
			threads[i].curr_capture_inited = false;
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
	if (r_or_end is io::EOF) {
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
			const r_b = r: u32;

			if (r_b >= range.0 && r_b <= range.1) {
				// Succeeded if positive match
				// Failed if negative match
				matched = cs.is_positive;
				break;
			};
		case let classfn: charset_class_item =>
			if (classfn(r)) {
				// Succeeded if positive match
				// Failed if negative match
				matched = cs.is_positive;
				break;
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
	re: *regex,
	string: str,
	handle: io::handle,
	need_captures: bool
) (void | []capture) = {
	let threads: []thread = alloc([
		thread { captures = [], ... }
	]);
	if (re.n_reps > 0) {
		threads[0].rep_counters = alloc([0...], re.n_reps);
	};
	defer {
		for (let i = 0z; i < len(threads); i += 1) {
			free(threads[i].captures);
			free(threads[i].rep_counters);
		};
		free(threads);
	};

	let str_idx = 0z;
	let first_match_idx: (void | size) = void;
	let str_bytesize = 0z;
	let last_bytesize = 0z;

	for (true) {
		str_bytesize += last_bytesize;

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
			let best_n_captures = 0z;
			let best_idx = 0z;
			for (let i = 0z; i < len(threads); i += 1) {
				let match_len = threads[i].root_capture.end
					- threads[i].root_capture.start;
				const is_better = match_len > best_len
					|| match_len == best_len
					&& len(threads[i].captures)
					> best_n_captures;
				if (is_better) {
					best_len = match_len;
					best_idx = i;
					best_n_captures = len(threads[i].captures);
				};
			};
			let res: []capture = alloc([],
				len(threads[best_idx].captures) + 1);
			append(res, threads[best_idx].root_capture);
			append(res, threads[best_idx].captures...);
			return res;
		};

		const r_or_end = bufio::read_rune(handle)!;
		if (r_or_end is rune) {
			last_bytesize = utf8::runesz(r_or_end as rune);
		};

		for (let i = 0z; i < len(threads); i += 1) {
			const res = run_thread(i, re, string, &threads,
				r_or_end, str_idx, str_bytesize);
			const matchlen = threads[i].root_capture.end
				- threads[i].root_capture.start;
			if (res is newmatch && matchlen > 0 && !need_captures) {
				return [];
			};
			const is_better = res is newmatch && matchlen > 0
				&& (first_match_idx is void
					|| threads[i].start_idx
						< first_match_idx as size);
			if (is_better) {
				first_match_idx = threads[i].start_idx;
			};
		};
		str_idx += 1;

		// When we only want the leftmost match, delete all threads that
		// start after the earliest non-zero-length matched thread
		if (first_match_idx is size) {
			for (let thread &.. threads) {
				if (thread.start_idx > first_match_idx as size) {
					thread.failed = true;
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
};

// Returns whether or not a [[regex]] matches any part of a given string.
export fn test(re: *regex, string: str) bool = {
	let strm = memio::fixed(strings::toutf8(string));
	return search(re, string, &strm, false) is []capture;
};


// Attempts to match a [[regex]] against a string and returns the longest
// leftmost match as a [[result]]. The caller must free the return value with
// [[result_free]].
export fn find(re: *regex, string: str) result = {
	let strm = memio::fixed(strings::toutf8(string));
	match (search(re, string, &strm, true)) {
	case let m: []capture =>
		return m;
	case void =>
		return [];
	};
};

// Attempts to match a [[regex]] against a string and returns all
// non-overlapping matches as a slice of [[result]]s. The caller must free the
// return value with [[result_freeall]].
export fn findall(re: *regex, string: str) []result = {
	let res: []result = [];
	let str_idx = 0z, str_bytesize = 0z;
	let strm = memio::fixed(strings::toutf8(string));
	const str_bytes = strings::toutf8(string);
	for (true) {
		let substring = strings::fromutf8_unsafe(
			str_bytes[str_bytesize..]);
		match (search(re, substring, &strm, true)) {
		case let m: []capture =>
			append(res, m);
			m[0].start += str_idx;
			m[0].end += str_idx;
			m[0].start_bytesize += str_bytesize;
			m[0].end_bytesize += str_bytesize;
			str_idx = m[0].end;
			str_bytesize = m[0].end_bytesize;
			if (m[0].start_bytesize == len(str_bytes)) {
				// end-of-string reached
				break;
			};
			if (m[0].start_bytesize == m[0].end_bytesize) {
				// zero-length match
				// forward rune and byte indices
				str_idx += 1;
				str_bytesize += encoding::utf8::utf8sz(
					str_bytes[str_bytesize])!;
			};
			io::seek(&strm, str_bytesize: io::off,
				io::whence::SET)!;
		case void => break;
		};
	};
	return res;
};

// Replaces all non-overlapping matches of a regular expression against a string
// with 'targetstr'.
//
// A backslash followed by a single decimal number within 'targetstr' is
// replaced by the capture at that index (starting at 1), or an empty string if
// no such capture exists. For example, `\1` is replaced with the first capture,
// `\2` with the second, etc. `\0` is substituted with the entire substring that
// was matched. `\\` is replaced with a literal backslash. The caller must free
// the return value.
//
// An error is only returned if 'targetstr' isn't formatted correctly.
export fn replace(re: *regex, string: str, targetstr: str) (str | error) = {
	return replacen(re, string, targetstr, types::SIZE_MAX);
};

// Replaces up to 'n' non-overlapping matches of a regular expression against a
// string with 'targetstr', in the same manner as [[replace]]. The caller must
// free the return value.
export fn replacen(
	re: *regex,
	string: str,
	targetstr: str,
	n: size,
) (str | error) = {
	const target = parse_replace_target(targetstr)?;
	defer free(target);
	// Check if n == 0 after parse_replace_target so errors are propagated
	if (n == 0) {
		return strings::dup(string);
	};

	const matches = findall(re, string);
	if (len(matches) == 0) {
		return strings::dup(string);
	};
	defer result_freeall(matches);

	const bytes = strings::toutf8(string);
	let buf = alloc(bytes[..matches[0][0].start_bytesize]...);

	const n = if (len(matches) > n) n else len(matches);
	for (let i = 0z; i < n; i += 1) {
		for (let j = 0z; j < len(target); j += 1) {
			match (target[j]) {
			case let b: []u8 =>
				append(buf, b...);
			case let z: size =>
				if (z >= len(matches[i])) yield;
				const b = strings::toutf8(matches[i][z].content);
				append(buf, b...);
			};
		};
		const start = matches[i][0].end_bytesize;
		const end = if (i == n - 1) len(bytes)
			else matches[i + 1][0].start_bytesize;
		append(buf, bytes[start..end]...);
	};

	return strings::fromutf8(buf)!;
};

fn parse_replace_target(targetstr: str) ([]([]u8 | size) | error) = {
	const bytes = strings::toutf8(targetstr);
	let target: []([]u8 | size) = alloc([], 1);
	let iter = strings::iter(targetstr);
	let start = 0z, end = 0z;
	for (true) match (strings::next(&iter)) {
	case done =>
		if (start != end) {
			append(target, bytes[start..]);
		};
		break;
	case let r: rune =>
		if (r == '\\') {
			if (start != end) {
				append(target, bytes[start..end]);
			};

			const r = match (strings::next(&iter)) {
			case done =>
				return "Trailing backslash": error;
			case let r: rune =>
				yield r;
			};

			if (r == '\\') {
				append(target, '\\');
			} else if (ascii::isdigit(r)) {
				append(target, r: u32: size - 0x30);
			} else {
				return "Backslash must be followed by positive decimal number or a backslash": error;
			};

			end += 2;
			start = end;
		} else {
			end += utf8::runesz(r);
		};
	};

	return target;
};

// Replaces all non-overlapping matches of a regular expression against a string
// with 'targetstr'. 'targetstr' is isn't interpreted in any special way; all
// backslashes are treated literally. The caller must free the return value.
export fn rawreplace(re: *regex, string: str, targetstr: str) str = {
	return rawreplacen(re, string, targetstr, types::SIZE_MAX);
};

// Replaces up to 'n' non-overlapping matches of a regular expression against a
// string with 'targetstr', in the same manner as [[rawreplace]]. The caller
// must free the return value.
export fn rawreplacen(re: *regex, string: str, targetstr: str, n: size) str = {
	if (n == 0) {
		return strings::dup(string);
	};

	const matches = findall(re, string);
	if (len(matches) == 0) {
		return strings::dup(string);
	};
	defer result_freeall(matches);

	const target = strings::toutf8(targetstr);
	const bytes = strings::toutf8(string);
	let buf: []u8 = [];

	append(buf, bytes[..matches[0][0].start_bytesize]...);
	const n = if (len(matches) > n) n else len(matches);
	for (let i = 1z; i < n; i += 1) {
		append(buf, target...);
		const start = matches[i - 1][0].end_bytesize;
		const end = matches[i][0].start_bytesize;
		append(buf, bytes[start..end]...);
	};
	append(buf, target...);
	append(buf, bytes[matches[n - 1][0].end_bytesize..]...);

	return strings::fromutf8(buf)!;
};

// Frees a [[result]].
export fn result_free(s: result) void = {
	free(s);
};

// Frees a slice of [[result]]s.
export fn result_freeall(s: []result) void = {
	for (let res .. s) {
		result_free(res);
	};
	free(s);
};

// Converts an [[error]] into a user-friendly string.
export fn strerror(err: error) str = err;
