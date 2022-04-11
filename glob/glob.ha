// License: MPL-2.0
// (c) 2022 Yasumasa Tada <ytada@spartan.dev>
use fnmatch;
use fs;
use io;
use os;
use sort;
use strings;
use strio;

// MARK is currently not supported.
export type flags = enum uint {
	NONE = 0,
	MARK = 1 << 1,
	// If the pattern does not match any pathname, the pattern string is
	// returned.
	NOCHECK = 1 << 2,
	// Backslash escaping is disabled. A backslash character is treated as 
	// an ordinary character.
	NOESCAPE = 1 << 3,
	// Pathname sorting is disabled. The order of pathnames returned is
	// unspecified.
	NOSORT = 1 << 4,
};

export type generator = struct {
	pats: strstack,
	matc: size,
	flgs: flags,
	tmps: strio::dynamic_stream,
};

export type strstack = struct {
	bufv: []strio::dynamic_stream,
	bufc: size,
};

// Information about an unsuccessful search.
export type failure = struct {
	// The path that cannot be opened or read.
	path: str,
	// The actual filesystem error.
	error: fs::error,
};

// Returns a generator of pathnames matching a pattern. The result must be
// freed using [[globfree]].
export fn glob(pattern: str, flags: flags...) generator = {
	let ss = strstack_init();
	strstack_push(&ss, pattern);
	let bs = flags::NONE;
	for (let i = 0z; i < len(flags); i += 1) {
		bs |= flags[i];
	};
	return generator {
		pats = ss,
		matc = 0,
		flgs = bs,
		tmps = strio::dynamic(),
	};
};

// Frees all memory allocated by the generator.
export fn globfree(gen: *generator) void = {
	strstack_free(&gen.pats);
	io::close(&gen.tmps);
};

// Returns a generated pathname. The returned string is valid until [[next]]
// is called again. If, during the search, a directory is encountered that
// cannot be opened or read, a [[failure]] object is returned instead.
// [[next]] can be repeatedly called until void is returned.
export fn next(gen: *generator) (str | void | failure) = {
	const init = strstack_size(&gen.pats) == 1
		&& len(strio::string(&gen.tmps)) == 0;
	return match (next_match(os::cwd, gen)) {
	case void =>
		if (init && gen.flgs & flags::NOCHECK != 0) {
			return strio::string(&gen.tmps);
		};
		return void;
	case let f: failure =>
		return f;
	case let s: str =>
		return s;
	};
};

fn next_match(fs: *fs::fs, gen: *generator) (str | void | failure) = {
	const p = match (strstack_pop(&gen.pats)) {
	case void =>
		return;
	case let s: str =>
		if (gen.matc > 0) {
			gen.matc -= 1;
			return s;
		};
		// Avoids copying overlapping memory area.
		strio::reset(&gen.tmps);
		strio::concat(&gen.tmps, s)!;
		yield strio::string(&gen.tmps);
	};
	const l = strstack_size(&gen.pats);

	const ends = split_pattern(p);
	const dir = strings::sub(p, 0, ends.0);
	let pat = strings::sub(p, ends.0, ends.1);
	if (strings::hassuffix(pat, '/')) {
		pat = strings::sub(pat, 0, len(pat) - 1);
	};
	let rem = "";
	if (ends.1 < len(p)) {
		rem = strings::sub(p, ends.1, strings::end);
	};

	let flgs = fnmatch::flags::PERIOD;
	if (gen.flgs & flags::NOESCAPE != 0) {
		flgs |= fnmatch::flags::NOESCAPE;
	};
	let it = match(fs::iter(fs, if (len(dir) > 0) dir else ".")) {
	case let i: *fs::iterator =>
		yield i;
	case let e: fs::error =>
		return failure {
			path = dir,
			error = e,
		};
	};
	for (true) match (fs::next(it)) {
	case void =>
		break;
	case let de: fs::dirent =>
		if (!fnmatch::fnmatch(pat, de.name, flgs)) {
			continue;
		};
		if (len(rem) == 0) {
			strstack_push(&gen.pats, dir, de.name);
			gen.matc += 1;
			continue;
		};
		strstack_push(&gen.pats, dir, de.name, "/", rem);
	};
	if (gen.flgs & flags::NOSORT == 0) {
		strstack_sort(&gen.pats, l);
	};

	return next_match(fs, gen);
};

fn split_pattern(p: str) (size, size) = {
	let pos = (strings::iter(p), 0z);

	// TODO: Handle '\' in brackets correctly.
	// TODO: Handle escaped '/' correctly.

	// p[0..dirend] is path components which contain no special
	// characters.
	let dirend = 0z;
	for (let brk = false; true) match (strings::next(&pos.0)) {
	case void =>
		break;
	case let r: rune =>
		pos.1 += 1;
		switch (r) {
		case '*', '?' =>
			break;
		case '[' =>
			brk = true;
		case ']' =>
			if (brk) {
				break;
			};
		case '/' =>
			dirend = pos.1;
		case => void;
		};
	};
	
	// p[dirend..patend] is the first path component which contains
	// special characters.
	let patend = len(p);
	for (true) match (strings::next(&pos.0)) {
	case void =>
		break;
	case let r: rune =>
		pos.1 += 1;
		switch (r) {
		case '/' =>
			patend = pos.1;
			break;
		case => void;
		};
	};

	return (dirend, patend);
};

fn strstack_init() strstack = strstack {
	bufv = [],
	bufc = 0,
};

fn strstack_free(ss: *strstack) void = {
	for (let i = 0z; i < len(ss.bufv); i += 1) {
		io::close(&ss.bufv[i]);
	};
};

fn strstack_size(ss: *strstack) size = ss.bufc;

fn strstack_push(ss: *strstack, strs: str...) void = {
	if (ss.bufc == len(ss.bufv)) {
		append(ss.bufv, strio::dynamic());
	};
	strio::reset(&ss.bufv[ss.bufc]);
	strio::concat(&ss.bufv[ss.bufc], strs...)!;
	ss.bufc += 1;
};

fn strstack_pop(ss: *strstack) (str | void) = {
	if (ss.bufc == 0) {
		return;
	};
	ss.bufc -= 1;
	return strio::string(&ss.bufv[ss.bufc]);
};

fn strstack_sort(ss: *strstack, pos: size) void = {
	if (pos > ss.bufc) {
		return;
	};
	let s = ss.bufv[pos..ss.bufc];
	sort::sort(s, size(strio::dynamic_stream), &bufcmp);
};

fn bufcmp(a: const *void, b: const *void) int =
	strings::strcmp(
		strio::string(b: *strio::dynamic_stream),
		strio::string(a: *strio::dynamic_stream),
	);
