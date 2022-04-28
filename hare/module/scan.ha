// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Kiëd Llaentenn <kiedtl@tilde.team>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use ascii;
use crypto::sha256;
use fs;
use hare::ast;
use hare::lex;
use hare::parse;
use hash;
use io;
use path;
use sort;
use strings;
use strio;

def ABI_VERSION: u8 = 4;

// Scans the files in a directory for eligible build inputs and returns a
// [[version]] which includes all applicable files and their dependencies.
export fn scan(ctx: *context, path: str) (version | error) = {
	// TODO: Incorporate defines into the hash
	let sha = sha256::sha256();
	let found = false;
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		if (ctx.tags[i].mode == tag_mode::INCLUSIVE
				&& ctx.tags[i].name == "test") {
			found = true;
			break;
		};
	};
	hash::write(&sha, [if (found) 1 else 0]);
	let iter = match (fs::iter(ctx.fs, path)) {
	case fs::wrongtype =>
		// Single file case
		let inputs: []input = [];
		let deps: []ast::ident = [];
		let ft = match (type_for_ext(path)) {
		case void =>
			return notfound;
		case let ft: filetype =>
			yield ft;
		};
		let path = fs::resolve(ctx.fs, path);
		let st = fs::stat(ctx.fs, path)?;
		let in = input {
			path = strings::dup(path),
			stat = st,
			ft = ft,
			hash = scan_file(ctx, path, ft, &deps)?,
			...
		};
		append(inputs, in);

		let sumbuf: [sha256::SIZE]u8 = [0...];
		hash::write(&sha, in.hash);
		hash::sum(&sha, sumbuf);

		return version {
			hash = sumbuf,
			basedir = strings::dup(path::dirname(path)),
			depends = deps,
			inputs = inputs,
			...
		};
	case let err: fs::error =>
		return err;
	case let iter: *fs::iterator =>
		yield iter;
	};
	defer fs::finish(iter);
	let ver = version {
		basedir = strings::dup(path),
		...
	};
	scan_directory(ctx, &ver, &sha, path, iter)?;

	let readme = path::join(path, "README");
	defer free(readme);
	if (len(ver.inputs) == 0 && !fs::exists(ctx.fs, readme)) {
		// TODO: HACK: README is a workaround for haredoc issues
		return notfound;
	};

	let tmp: [sha256::SIZE]u8 = [0...];
	hash::sum(&sha, tmp);
	ver.hash = alloc([], sha.sz);
	append(ver.hash, tmp...);
	return ver;
};

// Given a file or directory name, parses it into the basename, extension, and
// tag set.
export fn parse_name(name: str) (str, str, []tag) = {
	let ext = path::extension(name);
	let base = ext.0, ext = ext.1;

	let p = strings::index(base, '+');
	let m = strings::index(base, '-');
	if (p is void && m is void) {
		return (base, ext, []);
	};
	let i: size =
		if (p is void && m is size) m: size
		else if (m is void && p is size) p: size
		else if (m: size < p: size) m: size
		else p: size;
	let tags = strings::sub(base, i, strings::end);
	let tags = match (parsetags(tags)) {
	case void =>
		return (base, ext, []);
	case let t: []tag =>
		yield t;
	};
	let base = strings::sub(base, 0, i);
	return (base, ext, tags);
};

fn scan_directory(
	ctx: *context,
	ver: *version,
	sha: *hash::hash,
	path: str,
	iter: *fs::iterator,
) (void | error) = {
	let files: []str = [], dirs: []str = [];
	defer {
		for (let i = 0z; i < len(files); i += 1) {
			free(files[i]);
		};
		free(files);

		for (let i = 0z; i < len(dirs); i += 1) {
			free(dirs[i]);
		};
		free(dirs);
	};

	let pathbuf = path::init();
	for (true) {
		const ent = match (fs::next(iter)) {
		case void =>
			break;
		case let ent: fs::dirent =>
			yield ent;
		};

		switch (ent.ftype) {
		case fs::mode::LINK =>
			let linkpath = path::set(&pathbuf, path, ent.name)!;
			linkpath = fs::readlink(ctx.fs, linkpath)?;
			if (!path::abs(linkpath)) {
				linkpath = path::set(&pathbuf, path, linkpath)!;
			};

			const st = fs::stat(ctx.fs, linkpath)?;
			if (fs::isfile(st.mode)) {
				append(files, strings::dup(ent.name));
			} else if (fs::isdir(st.mode)) {
				append(dirs, strings::dup(ent.name));
			} else if (fs::islink(st.mode)) {
				abort(); // TODO: Resolve recursively
			};
		case fs::mode::DIR =>
			append(dirs, strings::dup(ent.name));
		case fs::mode::REG =>
			append(files, strings::dup(ent.name));
		case => abort();
		};
	};

	// Sorted to keep the hash consistent
	sort::strings(dirs);
	sort::strings(files);

	// Tuple of is_directory, basename, tags, and path to a candidate input.
	let inputs: [](bool, str, []tag, str) = [];
	defer for (let i = 0z; i < len(inputs); i += 1) {
		// For file paths, these are assigned to the input, which
		// assumes ownership over them.
		if (inputs[i].0) {
			free(inputs[i].1);
			tags_free(inputs[i].2);
			free(inputs[i].3);
		};
	};

	// For a given basename, only the most specific path (i.e. with the most
	// tags) is used.
	//
	// foo.ha
	// foo+linux.ha
	// foo+linux+x86_64/
	// 	bar.ha
	// 	baz.ha
	//
	// In this case, foo+linux+x86_64 is the most specific, and so its used
	// as the build input and the other two files are discarded.

	for (let i = 0z; i < len(dirs); i += 1) {
		let name = dirs[i];
		let parsed = parse_name(name);
		let base = parsed.0, tags = parsed.2;

		let d = strings::toutf8(name);
		if (len(d) == 0 || (
			!strings::hasprefix(name, "+") &&
			!strings::hasprefix(name, "-"))) {
			if (!strings::hasprefix(name, ".")) {
				append(ver.subdirs, strings::dup(name));
			};
			continue;
		};
		if (!tagcompat(ctx.tags, tags)) {
			continue;
		};

		let path = path::join(path, name);
		let tuple = (true, strings::dup(base), tags, path);
		let superceeded = false;
		for (let j = 0z; j < len(inputs); j += 1) {
			if (inputs[j].1 != base) {
				continue;
			};
			let theirs = inputs[j].2;
			if (len(theirs) < len(tags)) {
				free(inputs[j].1);
				tags_free(inputs[j].2);
				free(inputs[j].3);
				inputs[j] = tuple;
				superceeded = true;
				break;
			} else if (len(theirs) > len(tags)) {
				// They are more specific
				superceeded = true;
				break;
			} else if (len(base) != 0) {
				return (path, inputs[j].3): ambiguous;
			};
		};
		if (!superceeded) {
			append(inputs, tuple);
		};
	};

	for (let i = 0z; i < len(files); i += 1) {
		let name = files[i];
		let parsed = parse_name(name);
		let base = parsed.0, ext = parsed.1, tags = parsed.2;

		let eligible = false;
		static const exts = [".ha", ".s"];
		for (let i = 0z; i < len(exts); i += 1) {
			if (exts[i] == ext) {
				eligible = true;
				break;
			};
		};
		if (!eligible || !tagcompat(ctx.tags, tags)) {
			tags_free(tags);
			continue;
		};

		let path = path::join(path, name);
		let tuple = (false, base, tags, path);
		let superceeded = false;
		for (let j = 0z; j < len(inputs); j += 1) {
			if (inputs[j].1 != base) {
				continue;
			};
			let theirs = inputs[j].2;
			if (len(theirs) < len(tags)) {
				// We are more specific
				free(inputs[j].1);
				tags_free(inputs[j].2);
				free(inputs[j].3);
				inputs[j] = tuple;
				superceeded = true;
				break;
			} else if (len(theirs) > len(tags)) {
				// They are more specific
				superceeded = true;
				break;
			} else if (len(base) != 0) {
				return (path, inputs[j].3): ambiguous;
			};
		};
		if (!superceeded) {
			append(inputs, tuple);
		};
	};

	for (let i = 0z; i < len(inputs); i += 1) {
		let isdir = inputs[i].0, path = inputs[i].3;
		if (isdir) {
			let iter = fs::iter(ctx.fs, path)?;
			scan_directory(ctx, ver, sha, path, iter)?;
		} else {
			let path = fs::resolve(ctx.fs, path);
			let st = fs::stat(ctx.fs, path)?;
			let ftype = type_for_ext(path) as filetype;
			let in = input {
				path = strings::dup(path),
				stat = st,
				ft = ftype,
				hash = scan_file(ctx, path, ftype, &ver.depends)?,
				basename = inputs[i].1,
				tags = inputs[i].2,
				...
			};
			append(ver.inputs, in);
			hash::write(sha, in.hash);
		};
	};
};

// Looks up a module by its identifier from HAREPATH, and returns a [[version]]
// which includes all eligible build inputs.
export fn lookup(ctx: *context, name: ast::ident) (version | error) = {
	let ipath = identpath(name);
	defer free(ipath);
	for (let i = len(ctx.paths); i > 0; i -= 1) {
		let cand = path::join(ctx.paths[i - 1], ipath);
		defer free(cand);
		match (scan(ctx, cand)) {
		case let v: version =>
			return v;
		case error => void;
		};
	};
	return notfound;
};

fn type_for_ext(name: str) (filetype | void) = {
	const ext = path::extension(name).1;
	return
		if (ext == ".ha") filetype::HARE
		else if (ext == ".s") filetype::ASSEMBLY
		else void;
};

fn scan_file(
	ctx: *context,
	path: str,
	ftype: filetype,
	deps: *[]ast::ident,
) ([]u8 | error) = {
	let f = fs::open(ctx.fs, path)?;
	let sha = sha256::sha256();
	hash::write(&sha, strings::toutf8(path));
	hash::write(&sha, [ABI_VERSION]);

	if (ftype == filetype::HARE) {
		let tee = io::tee(f, &sha);
		let lexer = lex::init(&tee, path);
		let imports = match (parse::imports(&lexer)) {
		case let im: []ast::import =>
			yield im;
		case let err: parse::error =>
			io::close(f): void;
			return err;
		};
		for (let i = 0z; i < len(imports); i += 1) {
			if (!have_ident(deps, imports[i].ident)) {
				append(deps, imports[i].ident);
			};
		};
		// Finish spooling out the file for the SHA
		match (io::copy(io::empty, &tee)) {
		case size => void;
		case let err: io::error =>
			io::close(f): void;
			return err;
		};
	} else {
		match (io::copy(&sha, f)) {
		case size => void;
		case let err: io::error =>
			io::close(f): void;
			return err;
		};
	};
	io::close(f)?;

	let tmp: [sha256::SIZE]u8 = [0...];
	hash::sum(&sha, tmp);

	let checksum: []u8 = alloc([], sha.sz);
	append(checksum, tmp...);
	return checksum;
};

fn have_ident(sl: *[]ast::ident, id: ast::ident) bool = {
	for (let i = 0z; i < len(sl); i += 1) {
		if (ast::ident_eq(sl[i], id)) {
			return true;
		};
	};
	return false;
};

// Parses a set of build tags, returning void if the string is an invalid tag
// set. The caller must free the return value with [[tags_free]].
export fn parsetags(in: str) ([]tag | void) = {
	let tags: []tag = [];
	let iter = strings::iter(in);
	for (true) {
		let t = tag { ... };
		let m = match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			yield r;
		};
		t.mode = switch (m) {
		case =>
			tags_free(tags);
			return;
		case '+' =>
			yield tag_mode::INCLUSIVE;
		case '-' =>
			yield tag_mode::EXCLUSIVE;
		};
		let buf = strio::dynamic();
		for (true) match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			if (ascii::isalnum(r) || r == '_') {
				strio::appendrune(&buf, r)!;
			} else {
				strings::push(&iter, r);
				break;
			};
		};
		t.name = strio::string(&buf);
		append(tags, t);
	};
	return tags;
};

// Frees a set of tags.
export fn tags_free(tags: []tag) void = {
	for (let i = 0z; i < len(tags); i += 1) {
		free(tags[i].name);
	};
	free(tags);
};

// Compares two tag sets and tells you if they are compatible.
export fn tagcompat(have: []tag, want: []tag) bool = {
	// XXX: O(n²), lame
	for (let i = 0z; i < len(want); i += 1) {
		let present = false;
		for (let j = 0z; j < len(have); j += 1) {
			if (have[j].name == want[i].name) {
				present = have[j].mode == tag_mode::INCLUSIVE;
				break;
			};
		};
		switch (want[i].mode) {
		case tag_mode::INCLUSIVE =>
			if (!present) return false;
		case tag_mode::EXCLUSIVE =>
			if (present) return false;
		};
	};
	return true;
};
