// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use bufio;
use bytes;
use encoding::hex;
use encoding::utf8;
use errors;
use fmt;
use fs;
use hare::ast;
use hare::unparse;
use io;
use os;
use path;
use strconv;
use strings;
use time;
use temp;

// The manifest file format is a series of line-oriented records. Lines starting
// with # are ignored.
//
// - "version" indicates the manifest format version, currently 2.
// - "input" is an input file, and its fields are the file hash, path, inode,
//   and mtime as a Unix timestamp.
// - "module" is a version of a module, and includes the module hash and the set
//   of input hashes which produce it.
// - "tags" is a list of tags associated with a module version

def VERSION: int = 2;

fn getinput(in: []input, hash: []u8) nullable *input = {
	for (let i = 0z; i < len(in); i += 1) {
		if (bytes::equal(in[i].hash, hash)) {
			return &in[i];
		};
	};
	return null;
};

// Loads the module manifest from the build cache for the given ident. The
// return value borrows the ident parameter. If the module is not found, an
// empty manifest is returned.
export fn manifest_load(ctx: *context, ident: ast::ident) (manifest | error) = {
	let manifest = manifest {
		ident = ident,
		inputs = [],
		versions = [],
	};
	let ipath = identpath(manifest.ident);
	defer free(ipath);
	let cachedir = path::init(ctx.cache, ipath)!;
	let cachedir = path::string(&cachedir);

	let mpath = path::init(cachedir, "manifest")!;
	let mpath = path::string(&mpath);

	let truefile = match (fs::open(ctx.fs, mpath, fs::flags::RDONLY)) {
	case errors::noentry =>
		return manifest;
	case let err: fs::error =>
		return err;
	case let file: io::handle =>
		yield file;
	};
	defer io::close(truefile)!;

	let inputs: []input = [], versions: []version = [];

	let buf: [4096]u8 = [0...];
	let file = bufio::buffered(truefile, buf, []);
	for (true) {
		let line = match (bufio::scanline(&file)) {
		case io::EOF =>
			break;
		case let err: io::error =>
			return err;
		case let line: []u8 =>
			yield line;
		};
		defer free(line);

		let line = match (strings::fromutf8(line)) {
		case utf8::invalid =>
			// Treat an invalid manifest as empty
			return manifest;
		case let s: str =>
			yield s;
		};

		if (strings::hasprefix(line, "#")) {
			continue;
		};

		let tok = strings::tokenize(line, " ");
		let kind = match (strings::next_token(&tok)) {
		case void =>
			continue;
		case let s: str =>
			yield s;
		};

		switch (kind) {
		case "version" =>
			let ver = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			};
			match (strconv::stoi(ver)) {
			case let v: int =>
				if (v != VERSION) {
					return manifest;
				};
			case =>
				return manifest;
			};
		case "input" =>
			let hash = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			}, path = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			}, inode = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			}, mtime = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			};

			let hash = match (hex::decodestr(hash)) {
			case let b: []u8 =>
				yield b;
			case =>
				return manifest;
			};
			let inode = match (strconv::stoz(inode)) {
			case let z: size =>
				yield z;
			case =>
				return manifest;
			};
			let mtime = match (strconv::stoi64(mtime)) {
			case let i: i64 =>
				yield time::from_unix(i);
			case =>
				return manifest;
			};

			let parsed = parsename(path);
			let ftype = match (type_for_ext(path)) {
			case void =>
				return manifest;
			case let ft: filetype =>
				yield ft;
			};

			append(inputs, input {
				hash = hash,
				path = strings::dup(path),
				ft = ftype,
				stat = fs::filestat {
					mask = fs::stat_mask::MTIME | fs::stat_mask::INODE,
					mtime = mtime,
					inode = inode,
					...
				},
				basename = strings::dup(parsed.0),
				tags = parsed.2,
			});
		case "module" =>
			let modhash = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			};
			let modhash = match (hex::decodestr(modhash)) {
			case let b: []u8 =>
				yield b;
			case =>
				return manifest;
			};

			let minputs: []input = [];
			for (true) {
				let hash = match (strings::next_token(&tok)) {
				case void =>
					break;
				case let s: str =>
					yield s;
				};
				let hash = match (hex::decodestr(hash)) {
				case let b: []u8 =>
					yield b;
				case =>
					return manifest;
				};
				defer free(hash);

				let input = match (getinput(inputs, hash)) {
				case null =>
					return manifest;
				case let i: *input =>
					yield i;
				};
				append(minputs, *input);
			};

			append(versions, version {
				hash = modhash,
				inputs = minputs,
				...
			});
		case "tags" =>
			let modhash = match (strings::next_token(&tok)) {
			case void =>
				return manifest;
			case let s: str =>
				yield s;
			};
			let modhash = match (hex::decodestr(modhash)) {
			case let b: []u8 =>
				yield b;
			case =>
				return manifest;
			};

			const tags = strings::remaining_tokens(&tok);
			const tags = parsetags(tags) as []tag;
			let found = false;
			for (let i = 0z; i < len(versions); i += 1) {
				if (bytes::equal(versions[i].hash, modhash)) {
					versions[i].tags = tags;
					found = true;
					break;
				};
			};
			// Implementation detail: tags always follows module
			// directive for a given module version
			assert(found);

			// Drain tokenizer
			for (strings::next_token(&tok) is str) void;
		case =>
			return manifest;
		};

		// Check for extra tokens
		match (strings::next_token(&tok)) {
		case void => void;
		case str =>
			return manifest;
		};
	};

	manifest.inputs = inputs;
	manifest.versions = versions;
	return manifest;
};

// Returns true if the desired module version is present and current in this
// manifest.
export fn current(man: *manifest, ver: *version) bool = {
	// TODO: This is kind of dumb. What we really need to do is:
	// 1. Update scan to avoid hashing the file if a manifest is present,
	//    and indicate that the hash is cached somewhere in the type. Get an
	//    up-to-date stat.
	// 2. In [current], test if the inode and mtime are equal to the
	//    manifest version. If so, presume the file is up-to-date. If not,
	//    check the hash and update the manifest to the new inode/mtime if
	//    the hash matches. If not, the module is not current; rebuild.
	let cached: nullable *version = null;
	for (let i = 0z; i < len(man.versions); i += 1) {
		if (bytes::equal(man.versions[i].hash, ver.hash)) {
			cached = &man.versions[i];
			break;
		};
	};
	let cached = match (cached) {
	case null =>
		return false;
	case let v: *version =>
		yield v;
	};

	assert(len(cached.inputs) == len(ver.inputs));
	for (let i = 0z; i < len(cached.inputs); i += 1) {
		let a = cached.inputs[i], b = cached.inputs[i];
		assert(a.path == b.path);
		let ast = a.stat, bst = b.stat;
		if (ast.inode != bst.inode
				|| time::compare(ast.mtime, bst.mtime) != 0) {
			return false;
		};
	};
	return true;
};

// Writes a module manifest to the build cache.
export fn manifest_write(ctx: *context, man: *manifest) (void | error) = {
	let ipath = identpath(man.ident);
	defer free(ipath);
	let cachedir = path::init(ctx.cache, ipath)!;
	let cachedir = path::string(&cachedir);

	let mpath = path::init(cachedir, "manifest")!;
	let mpath = path::string(&mpath);

	let (truefile, name) = temp::named(ctx.fs, cachedir, io::mode::WRITE, 0o644)?;
	let wbuf: [os::BUFSIZ]u8 = [0...];
	let file = &bufio::buffered(truefile, [], wbuf);
	defer {
		bufio::flush(file)!;
		fs::remove(ctx.fs, name): void;
		io::close(truefile)!;
	};

	let ident = unparse::identstr(man.ident);
	defer free(ident);
	fmt::fprintfln(file, "# {}", ident)?;
	fmt::fprintln(file, "# This file is an internal Hare implementation detail.")?;
	fmt::fprintln(file, "# The format is not stable.")?;
	fmt::fprintfln(file, "version {}", VERSION)?;
	for (let i = 0z; i < len(man.inputs); i += 1) {
		const input = man.inputs[i];
		let hash = hex::encodestr(input.hash);
		defer free(hash);

		const want = fs::stat_mask::INODE | fs::stat_mask::MTIME;
		assert(input.stat.mask & want == want);
		fmt::fprintfln(file, "input {} {} {} {}",
			hash, input.path, input.stat.inode,
			time::unix(input.stat.mtime))?;
	};

	for (let i = 0z; i < len(man.versions); i += 1) {
		const ver = man.versions[i];
		let hash = hex::encodestr(ver.hash);
		defer free(hash);

		fmt::fprintf(file, "module {}", hash)?;

		for (let j = 0z; j < len(ver.inputs); j += 1) {
			let hash = hex::encodestr(ver.inputs[i].hash);
			defer free(hash);

			fmt::fprintf(file, " {}", hash)?;
		};

		fmt::fprintln(file)?;

		fmt::fprintf(file, "tags {} ", hash)?;
		for (let i = 0z; i < len(ver.tags); i += 1) {
			const tag = &ver.tags[i];
			fmt::fprintf(file, "{}{}",
				switch (tag.mode) {
				case tag_mode::INCLUSIVE =>
					yield "+";
				case tag_mode::EXCLUSIVE =>
					yield "-";
				},
				tag.name)?;
		};
		fmt::fprintln(file)!;
	};

	fs::move(ctx.fs, name, mpath)?;
};

fn input_finish(in: *input) void = {
	free(in.hash);
	free(in.path);
	free(in.basename);
	tags_free(in.tags);
};

// Frees resources associated with this manifest.
export fn manifest_finish(m: *manifest) void = {
	for (let i = 0z; i < len(m.inputs); i += 1) {
		input_finish(&m.inputs[i]);
	};

	for (let i = 0z; i < len(m.versions); i += 1) {
		free(m.versions[i].inputs);
		tags_free(m.versions[i].tags);
	};
};
