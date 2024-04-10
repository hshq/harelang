// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use fnmatch;
use fs;
use io;
use memio;
use os;
use path;
use sort;
use strings;

// Flags used to control the behavior of [[next]].
export type flag = enum uint {
	NONE = 0,
	// Slash appending is enabled. A slash character is appended to each
	// pathname that is a directory that matches the pattern.
	MARK = 1,
	// If the pattern does not match any pathname, the pattern string is
	// returned.
	NOCHECK = 1 << 1,
	// Backslash escaping is disabled. A backslash character is treated as
	// an ordinary character.
	NOESCAPE = 1 << 2,
	// Pathname sorting is disabled. The order of pathnames returned is
	// unspecified.
	NOSORT = 1 << 3,
};

export type generator = struct {
	pats: strstack,
	matc: size,
	flgs: flag,
	tmpp: pattern,
};

export type strstack = struct {
	bufv: []memio::stream,
	bufc: size,
};

export type pattern = struct {
	// TODO: look into working with a couple of string iterators instead
	dir: memio::stream,
	pat: memio::stream,
	rem: memio::stream,
};

// Information about an unsuccessful search.
export type failure = !struct {
	// The path that cannot be opened or read.
	path: str,
	// The actual filesystem error.
	error: fs::error,
};

// Converts an error info a human-friendly string. The result is statically
// allocated.
export fn strerror(err: failure) str = {
	static let buf: [path::MAX + 1024]u8 = [0...];
	return fmt::bsprintf(buf, "{}: {}", err.path, fs::strerror(err.error));
};

// Returns a generator of pathnames matching a pattern. The result must be
// freed using [[finish]].
export fn glob(pattern: str, flags: flag = flag::NONE) generator = {
	let ss = strstack_init();
	memio::concat(strstack_push(&ss), pattern)!;
	return generator {
		pats = ss,
		matc = 0,
		flgs = flags,
		tmpp = pattern_init(),
	};
};

// Frees all memory allocated by the generator.
export fn finish(gen: *generator) void = {
	strstack_free(&gen.pats);
	pattern_free(&gen.tmpp);
};

// Returns a generated pathname. The returned string is valid until [[next]]
// is called again. If, during the search, a directory is encountered that
// cannot be opened or read, a [[failure]] object is returned instead.
// [[next]] can be repeatedly called until void is returned.
export fn next(gen: *generator) (str | done | failure) = {
	const init = strstack_size(&gen.pats) == 1
		&& len(memio::string(&gen.tmpp.dir)!) == 0
		&& len(memio::string(&gen.tmpp.pat)!) == 0
		&& len(memio::string(&gen.tmpp.rem)!) == 0;
	match (next_match(gen)?) {
	case let s: str =>
		return s;
	case void => void;
	};
	if (init && gen.flgs & flag::NOCHECK != 0) {
		return memio::string(&gen.pats.bufv[0])!;
	};
	return done;
};

fn next_match(gen: *generator) (str | void | failure) = {
	match (strstack_pop(&gen.pats)) {
	case void =>
		return;
	case let s: str =>
		if (gen.matc > 0) {
			gen.matc -= 1;
			return s;
		};
		pattern_parse(&gen.tmpp, s, gen.flgs & flag::NOESCAPE != 0);
	};
	const l = strstack_size(&gen.pats);

	const dir = pattern_dir(&gen.tmpp);
	let pat = pattern_pat(&gen.tmpp);
	if (pat == "") {
		assert(pattern_rem(&gen.tmpp) == "");
		return if (os::exists(dir)) dir else void;
	};
	const patm = strings::hassuffix(pat, '/');
	if (patm) {
		pat = strings::sub(pat, 0, len(pat) - 1);
	};
	const rem = pattern_rem(&gen.tmpp);

	let flgs = fnmatch::flag::PERIOD;
	if (gen.flgs & flag::NOESCAPE != 0) {
		flgs |= fnmatch::flag::NOESCAPE;
	};
	let it = match(os::iter(if (len(dir) > 0) dir else ".")) {
	case let i: *fs::iterator =>
		yield i;
	case let e: fs::error =>
		return failure {
			path = dir,
			error = e,
		};
	};
	defer fs::finish(it);

	for (true) match (fs::next(it)) {
	case done =>
		break;
	case let de: fs::dirent =>
		if (patm && !fs::isdir(de.ftype) && !fs::islink(de.ftype)) {
			continue;
		};
		if (!fnmatch::fnmatch(pat, de.name, flgs)) {
			continue;
		};

		let b = strstack_push(&gen.pats);
		if (len(rem) > 0) {
			memio::concat(b, dir, de.name, "/", rem)!;
			continue;
		};
		memio::concat(b, dir, de.name)!;
		if (patm || gen.flgs & flag::MARK != 0) {
			let m = fs::isdir(de.ftype);
			// POSIX does not specify the behavior when a pathname
			// that matches the pattern is a symlink to a
			// directory. But in major implementation a slash
			// character is appended in this case.
			if (fs::islink(de.ftype)) {
				match (os::realpath(memio::string(b)!)) {
				case let r: str =>
					match (os::stat(r)) {
					case let s: fs::filestat =>
						m = fs::isdir(s.mode);
					case fs::error => void;
					};
				case fs::error => void;
				};
			};
			if (m) {
				memio::concat(b, "/")!;
			} else if (patm) {
				strstack_pop(&gen.pats);
				continue;
			};
		};
		gen.matc += 1;
	case let e: fs::error =>
		return failure {
			path = dir,
			error = e,
		};
	};
	if (gen.flgs & flag::NOSORT == 0) {
		strstack_sort(&gen.pats, l);
	};

	return next_match(gen);
};

fn pattern_init() pattern = pattern {
	dir = memio::dynamic(),
	pat = memio::dynamic(),
	rem = memio::dynamic(),
};

fn pattern_free(p: *pattern) void = {
	io::close(&p.dir)!;
	io::close(&p.pat)!;
	io::close(&p.rem)!;
};

fn pattern_reset(p: *pattern) void = {
	memio::reset(&p.dir);
	memio::reset(&p.pat);
	memio::reset(&p.rem);
};

fn pattern_dir(p: *pattern) str = memio::string(&p.dir)!;

fn pattern_pat(p: *pattern) str = memio::string(&p.pat)!;

fn pattern_rem(p: *pattern) str = memio::string(&p.rem)!;

fn pattern_parse(p: *pattern, pstr: str, noesc: bool) void = {
	pattern_reset(p);

	let itdir = strings::iter(pstr);
	let itpat = itdir;

	// p.dir is the longest directory name which contains no special
	// characters.
	for (let brk = false, esc = false; true) {
		const r = match (strings::next(&itdir)) {
		case done =>
			memio::concat(&p.dir, memio::string(&p.pat)!)!;
			memio::reset(&p.pat);
			return;
		case let r: rune =>
			yield r;
		};

		if (!esc) switch (r) {
		case '*', '?' =>
			break;
		case '[' =>
			brk = true;
		case ']' =>
			if (brk) {
				break;
			};
		case '\\' =>
			if (!noesc) {
				esc = true;
				continue;
			};
		case => void;
		};

		memio::appendrune(&p.pat, r)!;
		if (r == '/') {
			memio::concat(&p.dir, memio::string(&p.pat)!)!;
			memio::reset(&p.pat);
			itpat = itdir;
		};
		esc = false;
	};

	// p.pat is the first path component which contains special
	// characters.
	memio::reset(&p.pat);

	let esc = false;
	for (let r => strings::next(&itpat)) {
		if (!esc && r == '\\' && !noesc) {
			esc = true;
			continue;
		};

		if (esc && r != '/') {
			memio::appendrune(&p.pat, '\\')!;
		};
		memio::appendrune(&p.pat, r)!;
		if (r == '/') {
			break;
		};
		esc = false;
	};

	memio::concat(&p.rem, strings::iterstr(&itpat))!;
};

fn strstack_init() strstack = strstack {
	bufv = [],
	bufc = 0,
};

fn strstack_free(ss: *strstack) void = {
	for (let stream &.. ss.bufv) {
		io::close(stream)!;
	};
	free(ss.bufv);
};

fn strstack_size(ss: *strstack) size = ss.bufc;

fn strstack_push(ss: *strstack) *memio::stream = {
	if (ss.bufc == len(ss.bufv)) {
		append(ss.bufv, memio::dynamic());
	};
	let b = &ss.bufv[ss.bufc];
	memio::reset(b);
	ss.bufc += 1;
	return b;
};

fn strstack_pop(ss: *strstack) (str | void) = {
	if (ss.bufc == 0) {
		return;
	};
	ss.bufc -= 1;
	return memio::string(&ss.bufv[ss.bufc])!;
};

fn strstack_sort(ss: *strstack, pos: size) void = {
	if (pos > ss.bufc) {
		return;
	};
	let s = ss.bufv[pos..ss.bufc];
	sort::sort(s, size(memio::stream), &bufcmp);
};

fn bufcmp(a: const *opaque, b: const *opaque) int =
	strings::compare(
		memio::string(b: *memio::stream)!,
		memio::string(a: *memio::stream)!,
	);
