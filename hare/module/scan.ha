use ascii;
use bytes;
use crypto::sha256;
use encoding::utf8;
use fs;
use hare::ast;
use hare::lex;
use hare::parse;
use hash;
use io;
use path;
use slice;
use strings;
use strio;

// Scans the files in a directory for eligible build inputs and returns a
// [version] which includes all applicable files and their dependencies.
export fn scan(ctx: *context, path: str) (version | error) = {
	// TODO: Incorporate defines into the hash
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let iter = match (fs::iter(ctx.fs, path)) {
		fs::wrongtype => {
			// Single file case
			let inputs: []input = [];
			let deps: []ast::ident = [];
			let ft = match (type_for_ext(path)) {
				void => return module_not_found,
				ft: filetype => ft,
			};
			let st = fs::stat(ctx.fs, path)?;
			let in = input {
				path = fs::resolve(ctx.fs, path),
				stat = st,
				ft = ft,
				hash = scan_file(ctx, path, &deps)?,
				...
			};
			append(inputs, in);
			hash::write(sha, in.hash);
			return version {
				hash = hash::finish(sha),
				basedir = path::dirname(fs::resolve(ctx.fs, path)),
				depends = deps,
				inputs = inputs,
			};
		},
		err: fs::error => return err,
		iter: *fs::iterator => iter,
	};
	let ver = version {
		basedir = strings::dup(path),
		...
	};
	scan_directory(ctx, &ver, sha, path, iter)?;
	ver.hash = hash::finish(sha);
	return ver;
};

// Given a name and whether or not it represents a directory, parses it into the
// basename, extension, and tag set.
fn parse_name(name: str) (str, str, []tag) = {
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
	let tags = match (parse_tags(tags)) {
		void => return (base, ext, []),
		t: []tag => t,
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

	for (true) {
		let ent = match (fs::next(iter)) {
			void => break,
			ent: fs::dirent => ent,
		};

		switch (ent.ftype) {
			fs::mode::LINK => abort(), // TODO
			fs::mode::DIR => append(dirs, strings::dup(ent.name)),
			fs::mode::REG => append(files, strings::dup(ent.name)),
		};
	};

	// TODO:
	// - sort entries (for a consistent module hash)
	// - filter out less specific tag sets for a given basename
	for (let i = 0z; i < len(dirs); i += 1) {
		let name = dirs[i];
		let tags = parse_name(name).2;
		defer tags_free(tags);

		let d = strings::to_utf8(name);
		if (len(d) == 0 || (
			!strings::has_prefix(name, "+") &&
			!strings::has_prefix(name, "-"))) {
			continue;
		};
		if (!tags_compat(ctx.tags, tags)) {
			continue;
		};

		let p = path::join(path, name);
		let iter = fs::iter(ctx.fs, p)?;
		scan_directory(ctx, ver, sha, p, iter)?;
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
		if (!eligible || !tags_compat(ctx.tags, tags)) {
			tags_free(tags);
			continue;
		};

		let p = path::join(path, name);
		let st = fs::stat(ctx.fs, p)?;
		let in = input {
			path = fs::resolve(ctx.fs, p),
			stat = st,
			ft = type_for_ext(name) as filetype,
			hash = scan_file(ctx, p, &ver.depends)?,
			basename = base,
			tags = tags,
			...
		};
		append(ver.inputs, in);
		hash::write(sha, in.hash);
	};
};

// Looks up a module by its identifier from HAREPATH, and returns a [version]
// which includes all eligible build inputs.
export fn lookup(ctx: *context, name: ast::ident) (version | error) = {
	let ipath = ident_path(name);
	for (let i = len(ctx.paths); i > 0; i -= 1) {
		let cand = path::join(ctx.paths[i - 1], ipath);
		defer free(cand);
		match (scan(ctx, cand)) {
			v: version => return v,
			e: error => void,
		};
	};
	return module_not_found;
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
	deps: *[]ast::ident,
) ([]u8 | error) = {
	let f = fs::open(ctx.fs, path)?;
	defer io::close(f);
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let tee = io::tee(f, hash::writer(sha));
	defer io::close(tee);

	let lexer = lex::init(tee, path);
	let imports = parse::imports(&lexer)?;
	for (let i = 0z; i < len(imports); i += 1) {
		let ident = match (imports[i]) {
			m: ast::import_module => m: ast::ident,
			a: ast::import_alias => a.ident,
			o: ast::import_objects => o.ident,
		};
		if (!have_ident(deps, ident)) {
			append(*deps, ident);
		};
	};

	io::copy(io::empty, tee)?; // Finish spooling out the file for the SHA
	return hash::finish(sha);
};

fn have_ident(sl: *[]ast::ident, id: ast::ident) bool = {
	// XXX: We shouldn't have to deref sl here
	for (let i = 0z; i < len(*sl); i += 1) {
		if (ast::ident_eq(sl[i], id)) {
			return true;
		};
	};
	return false;
};

// Parses a set of build tags, returning void if the string is an invalid tag
// set. The caller must free the return value with [tags_free].
export fn parse_tags(in: str) ([]tag | void) = {
	let tags: []tag = [];
	// defer! tags_free(tags);
	let iter = strings::iter(in);
	for (true) {
		let t = tag { ... };
		let m = match (strings::next(&iter)) {
			void => break,
			r: rune => r,
		};
		t.mode = switch (m) {
			*   => return,
			'+' => tag_mode::INCLUSIVE,
			'-' => tag_mode::EXCLUSIVE,
		};
		let buf = strio::dynamic();
		for (true) match (strings::next(&iter)) {
			void => break,
			r: rune => {
				if (ascii::isalnum(r) || r == '_') {
					strio::append_rune(buf, r);
				} else {
					strings::push(&iter, r);
					break;
				};
			},
		};
		t.name = strio::finish(buf);
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
export fn tags_compat(have: []tag, want: []tag) bool = {
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
			tag_mode::INCLUSIVE => if (!present) return false,
			tag_mode::EXCLUSIVE => if (present) return false,
		};
	};
	return true;
};
